from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


SourceType = Literal["file", "scan-session", "upload", "mobile-capture"]
Engine = Literal["auto", "tesseract", "paddleocr"]
PreprocessMode = Literal["auto", "document", "photo", "low-light", "none"]
OutputType = Literal["json", "txt", "markdown", "searchable-pdf"]
JobStatus = Literal["queued", "running", "completed", "failed", "cancelled"]


class OcrJobOptions(BaseModel):
    target_dpi: int = Field(default=300, alias="targetDpi", ge=72, le=600)
    detect_layout: bool = Field(default=False, alias="detectLayout")
    detect_tables: bool = Field(default=False, alias="detectTables")
    keep_intermediate_artifacts: bool = Field(
        default=True,
        alias="keepIntermediateArtifacts",
    )


class CreateOcrJobRequest(BaseModel):
    source_type: SourceType = Field(alias="sourceType")
    source_path: str | None = Field(default=None, alias="sourcePath")
    scan_session_id: str | None = Field(default=None, alias="scanSessionId")
    mobile_device_id: str | None = Field(default=None, alias="mobileDeviceId")
    mobile_capture_id: str | None = Field(default=None, alias="mobileCaptureId")
    client_captured_at_utc: str | None = Field(default=None, alias="clientCapturedAtUtc")
    page_numbers: list[int] | None = Field(default=None, alias="pageNumbers")
    language_hints: list[str] | None = Field(default=None, alias="languageHints")
    engine: Engine = "auto"
    preprocess_mode: PreprocessMode = Field(default="auto", alias="preprocessMode")
    outputs: list[OutputType] = Field(default_factory=lambda: ["json", "txt"])
    options: OcrJobOptions = Field(default_factory=OcrJobOptions)


class OcrJobResponse(BaseModel):
    result: str
    job_id: str = Field(alias="jobId")
    status: JobStatus
    created_at_utc: str = Field(alias="createdAtUtc")
    started_at_utc: str | None = Field(default=None, alias="startedAtUtc")
    completed_at_utc: str | None = Field(default=None, alias="completedAtUtc")
    engine: str
    preprocess_mode: str = Field(alias="preprocessMode")
    page_count: int = Field(alias="pageCount")
    message: str


class OcrArtifactResponse(BaseModel):
    artifact_id: str = Field(alias="artifactId")
    type: str
    path: str


class OcrResultResponse(BaseModel):
    job_id: str = Field(alias="jobId")
    status: JobStatus
    language: str
    text: str
    confidence_average: float = Field(alias="confidenceAverage")
    pages: list[dict[str, Any]]
    artifacts: list[OcrArtifactResponse]
    timings_ms: dict[str, int] = Field(alias="timingsMs")
