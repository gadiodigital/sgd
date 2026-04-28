from __future__ import annotations

import shutil
from pathlib import Path

import numpy as np


class PreprocessResult:
    def __init__(self, image_path: Path, diagnostics: dict) -> None:
        self.image_path = image_path
        self.diagnostics = diagnostics


def preprocess_image(source_path: Path, output_dir: Path, mode: str) -> PreprocessResult:
    output_dir.mkdir(parents=True, exist_ok=True)
    target_path = output_dir / f"{source_path.stem}.preprocessed.png"

    if mode == "none":
        target_path = output_dir / f"{source_path.stem}.preprocessed{source_path.suffix}"
        shutil.copy2(source_path, target_path)
        return PreprocessResult(target_path, {"mode": mode, "applied": ["copy"]})

    try:
        import cv2  # type: ignore
    except ImportError:
        shutil.copy2(source_path, target_path)
        return PreprocessResult(
            target_path,
            {
                "mode": mode,
                "applied": ["copy"],
                "warning": "OpenCV no esta instalado; se uso la imagen original.",
            },
        )

    image = cv2.imread(str(source_path))
    if image is None:
        raise ValueError(f"No se pudo leer la imagen: {source_path}")

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    denoised = cv2.medianBlur(enhanced, 3)
    candidates = _build_candidates(denoised, mode)
    selected = _select_candidate(candidates)

    cv2.imwrite(str(target_path), selected["image"])
    return PreprocessResult(
        target_path,
        {
            "mode": mode,
            "applied": ["grayscale", "clahe", "medianBlur", selected["name"]],
            "selectedCandidate": selected["name"],
            "candidates": [
                {
                    "name": candidate["name"],
                    "score": candidate["score"],
                    "blackRatio": candidate["blackRatio"],
                    "whiteRatio": candidate["whiteRatio"],
                    "variance": candidate["variance"],
                }
                for candidate in candidates
            ],
        },
    )


def _build_candidates(denoised, mode: str) -> list[dict]:
    if mode == "document":
        return [_candidate("adaptiveGaussian11", _adaptive(denoised, 11, 2))]
    if mode == "photo" or mode == "low-light":
        return [_candidate("adaptiveGaussian35", _adaptive(denoised, 35, 5))]

    return [
        _candidate("otsu", _otsu(denoised)),
        _candidate("adaptiveGaussian11", _adaptive(denoised, 11, 2)),
        _candidate("adaptiveGaussian35", _adaptive(denoised, 35, 5)),
    ]


def _otsu(image):
    import cv2  # type: ignore

    return cv2.threshold(image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]


def _adaptive(image, block_size: int, c_value: int):
    import cv2  # type: ignore

    return cv2.adaptiveThreshold(
        image,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        block_size,
        c_value,
    )


def _candidate(name: str, image) -> dict:
    black_ratio = float(np.mean(image == 0))
    white_ratio = float(np.mean(image == 255))
    variance = float(np.var(image) / (255 * 255))
    balance_penalty = abs(black_ratio - 0.12)
    score = variance - balance_penalty
    return {
        "name": name,
        "image": image,
        "score": round(score, 6),
        "blackRatio": round(black_ratio, 6),
        "whiteRatio": round(white_ratio, 6),
        "variance": round(variance, 6),
    }


def _select_candidate(candidates: list[dict]) -> dict:
    return max(candidates, key=lambda candidate: candidate["score"])
