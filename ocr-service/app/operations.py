from __future__ import annotations


def get_operations() -> list[dict[str, str]]:
    return [
        {
            "id": "create-job",
            "description": "Crear un job OCR asincronico o sincronico con wait=true.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "upload-job",
            "description": "Subir un archivo y crear un job OCR en una unica llamada.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "mobile-capture-job",
            "description": "Subir una captura tomada desde Android y crear un job OCR con metadata movil.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "preprocess",
            "description": "Preprocesar una imagen y devolver diagnosticos sin ejecutar OCR.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "storage-status",
            "description": "Consultar uso de artefactos OCR en disco.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "cleanup-artifacts",
            "description": "Eliminar jobs, uploads y preprocesamientos vencidos.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-job",
            "description": "Consultar estado y metadata de un job OCR.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "retry-job",
            "description": "Reintentar un job OCR fallido o cancelado reutilizando la request original.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-job-retries",
            "description": "Consultar la cadena de reintentos asociada a un job OCR.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-result",
            "description": "Consultar el resultado estructurado de un job OCR completado.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-result-summary",
            "description": "Consultar resumen liviano del resultado OCR sin bloques completos.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-job-quality",
            "description": "Consultar solo la calidad OCR y advertencias de un job completado.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-job-text",
            "description": "Descargar texto OCR completo del job sin conocer el artifactId.",
            "availability": "ready",
            "output": "text/plain",
        },
        {
            "id": "get-job-markdown",
            "description": "Descargar Markdown OCR del job sin conocer el artifactId.",
            "availability": "ready",
            "output": "text/markdown",
        },
        {
            "id": "get-artifact",
            "description": "Descargar artefactos generados por el job.",
            "availability": "ready",
            "output": "file",
        },
        {
            "id": "get-page-preview",
            "description": "Consultar imagen preprocesada de una pagina OCR.",
            "availability": "ready",
            "output": "image",
        },
        {
            "id": "get-page-diagnostics",
            "description": "Consultar diagnosticos de preprocesamiento por pagina.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-page-result",
            "description": "Consultar resultado OCR estructurado de una pagina.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-page-text",
            "description": "Consultar texto OCR plano de una pagina.",
            "availability": "ready",
            "output": "text/plain",
        },
        {
            "id": "get-job-metrics",
            "description": "Consultar metricas de ejecucion de un job OCR.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "get-job-error",
            "description": "Consultar error estructurado de un job OCR fallido.",
            "availability": "ready",
            "output": "json",
        },
        {
            "id": "paddleocr",
            "description": "Motor avanzado para layout y documentos complejos; no disponible en este corte.",
            "availability": "planned",
            "output": "json",
        },
        {
            "id": "searchable-pdf",
            "description": "Exportar PDF con capa de texto OCR.",
            "availability": "ready",
            "output": "application/pdf",
        },
        {
            "id": "markdown",
            "description": "Exportar resultado OCR en Markdown por pagina.",
            "availability": "ready",
            "output": "text/markdown",
        },
    ]
