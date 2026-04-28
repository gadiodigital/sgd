# GDMS OCR Service

Servicio local HTTP para procesamiento OCR avanzado de GDMS.

## Alcance inicial

- API `FastAPI` compatible con el patron de `windows-twain`.
- Jobs OCR con almacenamiento filesystem.
- Entrada por imagen, TIFF multipagina y PDF.
- Preprocesamiento con OpenCV cuando esta disponible.
- OCR con Tesseract CLI.
- Salida `result.json`, `result.txt`, `result.md`, `searchable.pdf` opcional y diagnostico por pagina.

## Requisitos locales

- Python 3.12 a 3.14.
- Tesseract instalado localmente o `OCR_TESSERACT_PATH` definido.
- Poppler instalado localmente para procesar PDF sin Docker.
- Dependencias Python instaladas desde `requirements.txt`.

## Instalacion local

```powershell
cd C:\IA\codex\ocr-service
py -m venv .venv
.\.venv\Scripts\python -m pip install --upgrade pip
.\.venv\Scripts\python -m pip install -r requirements.txt
```

## Ejecucion

```powershell
cd C:\IA\codex\ocr-service
.\.venv\Scripts\python -m uvicorn app.main:app --host 127.0.0.1 --port 8091
```

Health:

```http
GET http://127.0.0.1:8091/health
GET http://127.0.0.1:8091/ready
```

`/health` confirma que el proceso responde. `/ready` valida dependencias OCR y escritura de artefactos; devuelve `503` si el servicio no esta listo para procesar.

`OCR_ALLOWED_SOURCE_ROOTS` permite restringir rutas aceptadas en `sourcePath`. Si esta vacio, no aplica restriccion; en Docker queda limitado por defecto a `/app/artifacts`.

Crear job:

```http
POST http://127.0.0.1:8091/api/ocr/jobs
Content-Type: application/json

{
  "sourceType": "file",
  "sourcePath": "C:\\IA\\codex\\windows-twain\\sessions\\demo\\page-001.bmp",
  "languageHints": ["spa", "eng"],
  "engine": "tesseract",
  "preprocessMode": "auto",
  "outputs": ["json", "txt", "markdown", "searchable-pdf"],
  "options": {
    "targetDpi": 300,
    "detectLayout": false,
    "detectTables": false,
    "keepIntermediateArtifacts": true
  }
}
```

Para ejecutar sincronico y recibir el estado final:

```http
POST http://127.0.0.1:8091/api/ocr/jobs?wait=true
```

Crear job por upload directo:

```powershell
$form = @{
  file = Get-Item "C:\IA\codex\sample.png"
  languageHints = "spa,eng"
  outputs = "json,txt,markdown,searchable-pdf"
  engine = "tesseract"
  preprocessMode = "auto"
}

Invoke-RestMethod `
  -Uri "http://127.0.0.1:8091/api/ocr/jobs/upload" `
  -Method Post `
  -Form $form
```

Para upload sincronico agregar `wait = "true"` al formulario.

Crear job desde captura Android:

```powershell
$form = @{
  file = Get-Item "C:\IA\codex\mobile-capture.jpg"
  languageHints = ""
  outputs = "json,txt"
  engine = "tesseract"
  preprocessMode = "auto"
  wait = "true"
  mobileDeviceId = "android-device-id"
  mobileCaptureId = "capture-id"
  clientCapturedAtUtc = "2026-04-24T20:00:00Z"
}

Invoke-RestMethod `
  -Uri "http://127.0.0.1:8091/api/ocr/jobs/mobile-capture" `
  -Method Post `
  -Form $form
```

Si `languageHints` esta vacio, el servicio usa `OCR_DEFAULT_LANGUAGES`.

Procesar una sesion escaneada desde un directorio:

```http
POST http://127.0.0.1:8091/api/ocr/jobs/from-scan-session
Content-Type: application/json

{
  "sourceType": "scan-session",
  "sourcePath": "C:\\IA\\codex\\windows-twain\\sessions\\session-id",
  "pageNumbers": [1, 3],
  "languageHints": ["spa", "eng"],
  "engine": "tesseract",
  "preprocessMode": "auto",
  "outputs": ["json", "txt"],
  "options": {
    "targetDpi": 300,
    "detectLayout": false,
    "detectTables": false,
    "keepIntermediateArtifacts": true
  }
}
```

Consultar resultado:

```http
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/retries
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/summary?text_limit=500
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/quality
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/text
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/markdown
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/result
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/metrics
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/error
```

La respuesta de `GET /api/ocr/jobs/{jobId}` incluye `progress` con `stage`, `processedPages`, `totalPages`, `currentPage` y `percent` cuando el job esta en ejecucion.
`GET /api/ocr/jobs/{jobId}/retries` devuelve el job raiz y sus reintentos asociados.
`GET /api/ocr/jobs/{jobId}/summary` devuelve un resumen liviano sin `blocks` completos, util para listados o vistas previas.
`GET /api/ocr/jobs/{jobId}/quality` devuelve solo `confidenceAverage`, `quality` y `warnings`, util para reglas automaticas de revision.
`GET /api/ocr/jobs/{jobId}/text` descarga el texto OCR completo como `text/plain`.
`GET /api/ocr/jobs/{jobId}/markdown` descarga el Markdown OCR como `text/markdown` cuando fue solicitado en `outputs`.

Cancelar un job:

```http
POST http://127.0.0.1:8091/api/ocr/jobs/{jobId}/cancel
```

La cancelacion es cooperativa: si el job ya esta ejecutando OCR, el servicio detiene el pipeline al terminar la etapa o pagina actual.

Reintentar un job fallido o cancelado:

```http
POST http://127.0.0.1:8091/api/ocr/jobs/{jobId}/retry?wait=true
```

El reintento crea un nuevo `jobId` reutilizando la request original. La respuesta incluye `parentJobId` y `retryOfJobId` para auditoria.

Listar jobs:

```http
GET http://127.0.0.1:8091/api/ocr/jobs?status=completed&source_type=upload&created_from=2026-04-25T00:00:00Z&created_to=2026-04-25T23:59:59Z&order=desc&limit=50&offset=0
```

La respuesta incluye `items`, `total`, `limit`, `offset` y `filters`.

El resultado incluye:

- `source` con tipo, ruta, tamaño y paginas solicitadas.
- `engine.requested` y `engine.resolved` para auditar el motor usado.
- `confidenceAverage` a nivel documento.
- `quality.level` con `good`, `review` o `poor`.
- `warnings` cuando hay baja confianza o paginas sin texto.
- `pages[].confidenceAverage`.
- `pages[].blocks[]` con bloques `line` y `word`, ambos con bounding boxes.
- `blocks[].metadata` con `blockNumber`, `paragraphNumber` y `lineNumber` cuando proviene de Tesseract.

Consultar diagnostico de pagina:

```http
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/pages/{pageNumber}
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/pages/{pageNumber}/diagnostics
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/pages/{pageNumber}/text
```

Consultar preview preprocesada:

```http
GET http://127.0.0.1:8091/api/ocr/jobs/{jobId}/pages/{pageNumber}/preview
```

Preprocesar una imagen sin ejecutar OCR:

```powershell
$form = @{
  file = Get-Item "C:\IA\codex\sample.png"
  preprocessMode = "auto"
}

Invoke-RestMethod `
  -Uri "http://127.0.0.1:8091/api/ocr/preprocess" `
  -Method Post `
  -Form $form
```

Consultar imagen preprocesada:

```http
GET http://127.0.0.1:8091/api/ocr/preprocess/{preprocessId}/image
```

Consultar storage de artefactos:

```http
GET http://127.0.0.1:8091/api/ocr/storage
```

Limpiar artefactos antiguos:

```http
POST http://127.0.0.1:8091/api/ocr/maintenance/cleanup?retention_hours=72
```

## Tests

```powershell
cd C:\IA\codex\ocr-service
.\.venv\Scripts\python -m unittest discover -s tests
```

## Docker

```powershell
cd C:\IA\codex\ocr-service
docker build -t gdms/ocr-service:0.1.0 .
docker run --rm -p 8091:8091 -v C:\IA\codex\artifacts\ocr:/app/artifacts gdms/ocr-service:0.1.0
```

La imagen Docker incluye Tesseract, idiomas `spa/eng` y Poppler. Es la ruta recomendada si no se desea instalar dependencias OCR en Windows.
