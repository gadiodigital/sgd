from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from uuid import uuid4


def utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")


@dataclass
class OcrJob:
    job_id: str
    status: str
    created_at_utc: str
    started_at_utc: str | None
    completed_at_utc: str | None
    engine: str
    preprocess_mode: str
    page_count: int
    message: str
    request: dict
    error: str | None = None
    artifacts: list[dict] = field(default_factory=list)
    source: dict | None = None
    progress: dict = field(default_factory=dict)
    parent_job_id: str | None = None
    retry_of_job_id: str | None = None


class JobStore:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.jobs_root = root / "jobs"
        self.jobs_root.mkdir(parents=True, exist_ok=True)

    def create(self, request: dict, engine: str, preprocess_mode: str) -> OcrJob:
        job_id = f"ocr_{datetime.now(UTC):%Y%m%d_%H%M%S}_{uuid4().hex[:8]}"
        job = OcrJob(
            job_id=job_id,
            status="queued",
            created_at_utc=utc_now(),
            started_at_utc=None,
            completed_at_utc=None,
            engine=engine,
            preprocess_mode=preprocess_mode,
            page_count=0,
            message="Job OCR creado.",
            request=request,
            progress={
                "stage": "queued",
                "processedPages": 0,
                "totalPages": None,
                "percent": 0,
            },
            parent_job_id=request.get("parentJobId"),
            retry_of_job_id=request.get("retryOfJobId"),
        )
        self.job_dir(job_id).mkdir(parents=True, exist_ok=False)
        self.write_job(job)
        return job

    def list(
        self,
        status: str | None = None,
        source_type: str | None = None,
        created_from: str | None = None,
        created_to: str | None = None,
        order: str = "desc",
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[OcrJob], int]:
        jobs = []
        reverse = order != "asc"
        for path in sorted(self.jobs_root.glob("*/job.json"), reverse=reverse):
            job = self.read_job(path.parent.name)
            if status is not None and job.status != status:
                continue
            if source_type is not None and _job_source_type(job) != source_type:
                continue
            if created_from is not None and job.created_at_utc < created_from:
                continue
            if created_to is not None and job.created_at_utc > created_to:
                continue
            jobs.append(job)

        total = len(jobs)
        return jobs[offset : offset + limit], total

    def list_retry_chain(self, job_id: str) -> list[OcrJob]:
        root_job = self.read_job(job_id)
        root_id = root_job.parent_job_id or root_job.job_id
        jobs = []
        for path in sorted(self.jobs_root.glob("*/job.json")):
            job = self.read_job(path.parent.name)
            if job.job_id == root_id or job.parent_job_id == root_id:
                jobs.append(job)
        return sorted(jobs, key=lambda job: job.created_at_utc)

    def read_job(self, job_id: str) -> OcrJob:
        data = self._read_json(self.job_dir(job_id) / "job.json")
        data.setdefault("source", None)
        data.setdefault("progress", {})
        data.setdefault("parent_job_id", data.pop("parentJobId", None))
        data.setdefault("retry_of_job_id", data.pop("retryOfJobId", None))
        return OcrJob(**data)

    def write_job(self, job: OcrJob) -> None:
        self._write_json(self.job_dir(job.job_id) / "job.json", asdict(job))

    def update(self, job: OcrJob, **changes: object) -> OcrJob:
        for key, value in changes.items():
            setattr(job, key, value)
        self.write_job(job)
        return job

    def delete(self, job_id: str) -> None:
        job_dir = self.job_dir(job_id)
        if not job_dir.exists():
            raise KeyError(job_id)
        for child in sorted(job_dir.rglob("*"), reverse=True):
            if child.is_file():
                child.unlink()
            else:
                child.rmdir()
        job_dir.rmdir()

    def job_dir(self, job_id: str) -> Path:
        if not job_id.startswith("ocr_") or any(part in job_id for part in ("..", "/", "\\")):
            raise ValueError("jobId invalido.")
        return self.jobs_root / job_id

    @staticmethod
    def _read_json(path: Path) -> dict:
        if not path.exists():
            raise KeyError(path.parent.name)
        return json.loads(path.read_text(encoding="utf-8"))

    @staticmethod
    def _write_json(path: Path, data: dict) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _job_source_type(job: OcrJob) -> str | None:
    if job.source and job.source.get("sourceType"):
        return job.source["sourceType"]
    return job.request.get("sourceType")
