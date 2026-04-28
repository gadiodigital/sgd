from __future__ import annotations

import shutil
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from pathlib import Path


@dataclass(frozen=True)
class StorageStatus:
    artifacts_root: str
    total_bytes: int
    job_count: int
    upload_count: int
    preprocess_count: int


@dataclass(frozen=True)
class CleanupResult:
    deleted_count: int
    deleted_bytes: int
    retention_hours: int
    cutoff_utc: str


def get_storage_status(root: Path) -> StorageStatus:
    return StorageStatus(
        artifacts_root=str(root),
        total_bytes=_directory_size(root),
        job_count=_count_children(root / "jobs"),
        upload_count=_count_children(root / "uploads"),
        preprocess_count=_count_children(root / "preprocess"),
    )


def cleanup_artifacts(root: Path, retention_hours: int) -> CleanupResult:
    cutoff = datetime.now(UTC) - timedelta(hours=retention_hours)
    deleted_count = 0
    deleted_bytes = 0

    for directory in _cleanup_targets(root):
        if not directory.exists():
            continue
        for child in directory.iterdir():
            if not child.exists() or _modified_at(child) >= cutoff:
                continue

            deleted_bytes += _directory_size(child) if child.is_dir() else child.stat().st_size
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
            deleted_count += 1

    return CleanupResult(
        deleted_count=deleted_count,
        deleted_bytes=deleted_bytes,
        retention_hours=retention_hours,
        cutoff_utc=cutoff.isoformat().replace("+00:00", "Z"),
    )


def _cleanup_targets(root: Path) -> list[Path]:
    return [
        root / "jobs",
        root / "uploads",
        root / "preprocess",
    ]


def _directory_size(path: Path) -> int:
    if not path.exists():
        return 0
    if path.is_file():
        return path.stat().st_size
    return sum(child.stat().st_size for child in path.rglob("*") if child.is_file())


def _count_children(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(1 for _ in path.iterdir())


def _modified_at(path: Path) -> datetime:
    return datetime.fromtimestamp(path.stat().st_mtime, UTC)
