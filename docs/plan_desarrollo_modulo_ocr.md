# Plan de desarrollo: modulo avanzado de procesamiento de imagenes y OCR

## 1. Objetivo

Crear un modulo nuevo para procesamiento avanzado de imagenes y OCR dentro de GDMS, con una arquitectura de servicio similar a `windows-twain`: proceso desacoplado, API local/HTTP, contratos claros, almacenamiento temporal de sesiones y capacidad de integrarse con backend, frontend Flutter y captura movil Android.

El modulo debe permitir convertir documentos escaneados, imagenes cargadas y capturas moviles en texto estructurado, PDF searchable y artefactos auditables para busqueda, clasificacion documental y extraccion futura de metadatos.

## 2. Contexto actual del proyecto

GDMS ya cuenta con:

- Backend `.NET` modular en `server/src`.
- Frontend Flutter modular en `client/packages`.
- Host local de escaneo `windows-twain`, con API local, sesiones, endpoints de paginas, previews, rotacion, ajuste basico y exportacion PDF.
- Infraestructura Docker local.
- Documento base `informacion_para_generar_modulo_ocr.md`, con investigacion sobre OpenCV, Tesseract, PaddleOCR, EAST, preprocesamiento adaptativo, metricas CER/WER y alternativas de despliegue.

El nuevo modulo debe apoyarse en el patron de `windows-twain`, pero no quedar acoplado a TWAIN. Debe poder recibir imagenes desde:

- Sesiones escaneadas por `windows-twain`.
- Archivos subidos desde backend/frontend.
- Capturas moviles Android.
- PDFs multipagina.
- Procesos batch futuros.

## 3. Alcance funcional

### MVP

- Crear un nuevo servicio local `ocr-service`.
- Exponer API HTTP local con health, status, operaciones y procesamiento OCR.
- Aceptar entradas `PNG`, `JPG/JPEG`, `TIFF`, `BMP` y `PDF`.
- Normalizar imagenes a una resolucion objetivo, preferentemente 300 DPI para documentos.
- Aplicar preprocesamiento basico y adaptativo:
  - grayscale;
  - CLAHE;
  - denoise;
  - deskew;
  - binarizacion Otsu;
  - binarizacion adaptativa Gaussian;
  - fallback automatico segun metrica de contraste/varianza.
- Ejecutar OCR inicial con Tesseract.
- Devolver resultado `JSON` con texto, paginas, bloques, bounding boxes, confianza y tiempos.
- Generar `TXT` consolidado.
- Generar `PDF searchable` como artefacto opcional.
- Integrar con `windows-twain` mediante procesamiento de paginas o sesiones existentes.
- Integrar con backend GDMS mediante un adaptador de aplicacion.
- Registrar errores, duracion, motor usado, configuracion y artefactos generados.

### Fase avanzada

- Agregar motor PaddleOCR como plugin alternativo para documentos complejos, layouts y tablas.
- Agregar deteccion de regiones de texto con EAST/OpenCV o detector nativo de PaddleOCR.
- Agregar reconocimiento de tablas y layout estructurado.
- Agregar procesamiento batch con cola.
- Agregar seleccion automatica de motor OCR segun tipo/calidad de documento.
- Agregar postprocesamiento heuristico:
  - normalizacion de espacios;
  - correccion de encoding;
  - regex para documentos frecuentes;
  - score de campos esperados;
  - futura correccion asistida por LLM.
- Agregar metricas CER/WER contra dataset propio.

## 4. Alcance no funcional

- Mantener el OCR fuera del proceso principal del backend para aislar dependencias pesadas.
- Permitir ejecucion local en Windows para estaciones de digitalizacion.
- Permitir despliegue Docker Linux para procesamiento centralizado.
- Soportar CPU como baseline y GPU como optimizacion futura.
- Garantizar trazabilidad: cada job debe tener `jobId`, entrada, configuracion, motor, artefactos, timestamps y estado.
- Evitar que imagenes temporales queden indefinidamente en disco.
- Definir limites de tamano, paginas y tiempo por job.
- No bloquear la UI durante procesamiento.
- Mantener resultados reproducibles guardando version de motor, version de pipeline y parametros.

## 5. Arquitectura propuesta

```text
[Entrada]
  |-- archivo local
  |-- sesion windows-twain
  |-- upload backend
  |-- captura Android
        |
        v
[ocr-service API]
        |
        v
[Job Store + Artifact Store]
        |
        v
[Carga + normalizacion]
        |
        v
[Preprocesamiento adaptativo]
        |
        v
[OCR Engine Plugin]
  |-- Tesseract
  |-- PaddleOCR
        |
        v
[Postprocesamiento]
        |
        v
[Exportadores]
  |-- JSON estructurado
  |-- TXT
  |-- PDF searchable
  |-- XLSX/tablas futuro
        |
        v
[Backend GDMS / busqueda / documentos / auditoria]
```

## 6. Forma del modulo

Crear carpeta nueva en la raiz:

```text
ocr-service/
  app/
  tests/
  models/
  artifacts/
  Dockerfile
  docker-compose.override.yml
  pyproject.toml
  README.md
```

Servicio sugerido: `Python + FastAPI + OpenCV + Tesseract + PaddleOCR`.

Razon tecnica:

- OpenCV, PaddleOCR, pdf2image y tooling OCR tienen soporte mas directo en Python.
- Evita cargar dependencias de vision en el backend `.NET`.
- Facilita Docker, GPU futura y multiprocessing.
- Se integra bien con `windows-twain` y backend por HTTP.

## 7. API local propuesta

Mantener una forma similar a `windows-twain`.

### Estado y operaciones

```http
GET /health
GET /api/ocr/status
GET /api/ocr/operations
GET /api/ocr/jobs
GET /api/ocr/jobs/{jobId}
DELETE /api/ocr/jobs/{jobId}
```

### Procesamiento

```http
POST /api/ocr/jobs
POST /api/ocr/jobs/from-scan-session
POST /api/ocr/jobs/{jobId}/cancel
GET /api/ocr/jobs/{jobId}/result
GET /api/ocr/jobs/{jobId}/artifacts/{artifactId}
```

### Preprocesamiento y diagnostico

```http
POST /api/ocr/preprocess
GET /api/ocr/jobs/{jobId}/pages/{pageNumber}/preview
GET /api/ocr/jobs/{jobId}/pages/{pageNumber}/diagnostics
```

## 8. Contratos iniciales

### `CreateOcrJobRequest`

```json
{
  "sourceType": "file | scan-session | upload | mobile-capture",
  "sourcePath": "C:\\path\\page-001.bmp",
  "scanSessionId": "optional",
  "pageNumbers": [1, 2],
  "languageHints": ["spa", "eng"],
  "engine": "auto | tesseract | paddleocr",
  "preprocessMode": "auto | document | photo | low-light | none",
  "outputs": ["json", "txt", "searchable-pdf"],
  "options": {
    "targetDpi": 300,
    "detectLayout": false,
    "detectTables": false,
    "keepIntermediateArtifacts": true
  }
}
```

### `OcrJobResponse`

```json
{
  "result": "ok",
  "jobId": "ocr_...",
  "status": "queued | running | completed | failed | cancelled",
  "createdAtUtc": "2026-04-24T00:00:00Z",
  "startedAtUtc": null,
  "completedAtUtc": null,
  "engine": "tesseract",
  "preprocessMode": "auto",
  "pageCount": 0,
  "message": "Job OCR creado."
}
```

### `OcrResult`

```json
{
  "jobId": "ocr_...",
  "status": "completed",
  "language": "spa",
  "text": "texto consolidado",
  "confidenceAverage": 0.91,
  "pages": [
    {
      "pageNumber": 1,
      "width": 2480,
      "height": 3508,
      "dpi": 300,
      "rotationApplied": -1.2,
      "confidenceAverage": 0.93,
      "text": "texto pagina",
      "blocks": [
        {
          "type": "line | word | table | paragraph",
          "text": "fragmento",
          "confidence": 0.94,
          "bbox": { "x": 10, "y": 20, "w": 300, "h": 40 }
        }
      ]
    }
  ],
  "artifacts": [
    {
      "artifactId": "txt",
      "type": "text/plain",
      "path": "..."
    }
  ],
  "timingsMs": {
    "load": 120,
    "preprocess": 450,
    "ocr": 1800,
    "export": 300
  }
}
```

## 9. Pipeline de procesamiento

### Carga

- Detectar tipo de entrada por extension y MIME.
- Para PDF, convertir paginas a imagen usando `pdf2image` o alternativa equivalente.
- Para TIFF multipagina, expandir paginas.
- Leer DPI cuando exista metadata.
- Si DPI es menor a 200, reescalar hacia 300 DPI.
- Preservar original como artefacto de entrada si la politica lo permite.

### Preprocesamiento adaptativo

Pipeline base:

```text
imagen original
  -> grayscale
  -> CLAHE
  -> denoise
  -> deskew
  -> binarizacion candidata
  -> seleccion por metrica
  -> morphologia ligera
  -> imagen lista para OCR
```

Candidatos de binarizacion:

- Otsu.
- Adaptive Gaussian `blockSize=11`, `C=2`.
- Adaptive Gaussian `blockSize=35`, `C=5`.
- Sauvola como fase avanzada para historicos o baja calidad.

Criterios de seleccion inicial:

- Varianza texto/fondo.
- Porcentaje de pixeles negros/blancos dentro de rango esperado.
- Densidad de componentes conectados.
- Confianza OCR en muestra corta si el costo es aceptable.

### OCR

Motores:

- `Tesseract`: baseline offline, estable, buen soporte para `spa` y documentos simples.
- `PaddleOCR`: recomendado para fase avanzada por mejor soporte de deteccion, reconocimiento, orientacion, layout y despliegue CPU/GPU.

Seleccion recomendada:

- MVP: Tesseract.
- Fase 2: PaddleOCR como motor preferente para documentos complejos.
- Fase 3: `auto`, con reglas por calidad, layout y tiempo.

### Postprocesamiento

- Unificar saltos de linea.
- Normalizar caracteres frecuentes mal reconocidos.
- Preservar bounding boxes originales.
- Calcular confianza promedio por pagina y documento.
- Detectar paginas vacias o de baja confianza.
- Generar advertencias cuando `confidenceAverage` quede bajo un umbral configurable.

## 10. Integracion con `windows-twain`

El modulo OCR no debe reemplazar a `windows-twain`; debe consumir sus artefactos.

Integracion inicial:

- `windows-twain` mantiene captura, sesiones, previews, rotacion y PDF basico.
- `ocr-service` recibe `sessionId`, `pageNumbers` y rutas de imagen.
- El backend o UI coordina la llamada:
  - escanear documento;
  - revisar paginas;
  - ejecutar OCR;
  - adjuntar resultado al documento GDMS.

Opcional futuro:

- Agregar endpoint en `windows-twain` que delegue OCR a `ocr-service`.
- Mantenerlo como adaptador, no como dependencia fuerte.

## 11. Integracion con backend GDMS

Crear capa de aplicacion:

```text
server/src/Gdms.Application/Ocr
server/src/Gdms.Contracts/Ocr
server/src/Gdms.Infrastructure/Ocr
server/src/Gdms.Api/Endpoints/Ocr
```

Responsabilidades:

- Registrar solicitud OCR sobre documento o archivo.
- Llamar a `ocr-service`.
- Persistir resultado en el modelo documental.
- Exponer texto a busqueda.
- Guardar artefactos en storage.
- Registrar auditoria.
- Manejar reintentos, errores y estados.

Endpoints backend sugeridos:

```http
POST /api/documents/{documentId}/ocr
GET /api/documents/{documentId}/ocr
GET /api/documents/{documentId}/ocr/artifacts/{artifactId}
POST /api/documents/{documentId}/ocr/retry
```

## 12. Integracion Flutter desktop/web

Crear paquete:

```text
client/packages/feature_ocr/
```

Responsabilidades:

- Pantalla de OCR para documento.
- Accion "Ejecutar OCR" desde detalle documental.
- Indicador de estado `queued/running/completed/failed`.
- Vista de texto extraido.
- Vista de confianza por pagina.
- Descarga de TXT/PDF searchable.
- Advertencias de baja confianza.
- Enlace con flujo de escaneo existente.

## 13. Estrategia mobile Android

### OCR on-device con fallback al servicio

Usar ML Kit Text Recognition v2 para reconocer texto directamente en Android cuando el dispositivo y la instalación lo permitan. Es util para captura rapida, previsualizacion y escenarios offline. Si el dispositivo no permite OCR on-device, si falta soporte local o si el resultado queda por debajo del umbral de confianza configurado, la app debe enviar la imagen directamente al `ocr-service`.

Ventajas:

- Baja latencia percibida.
- Puede funcionar sin enviar imagen al servidor cuando ML Kit este disponible.
- Buena integracion con camara.
- Adecuado para captura simple de texto.

Limitaciones:

- Resultado menos controlado que el pipeline central.
- Menor capacidad para PDF searchable, tablas avanzadas y normalizacion GDMS.
- Puede haber diferencias de resultado entre dispositivos.

Uso recomendado:

- Captura movil asistida.
- Preview OCR inmediato.
- Extraccion rapida para busqueda preliminar.
- Luego sincronizar imagen y resultado al backend para reprocesamiento oficial si corresponde.
- Si el dispositivo no permite OCR on-device, llamar directamente al `ocr-service`.

## 14. Plan de implementacion por fases

### Fase 0: decisiones tecnicas y estructura

- Crear `ocr-service/`.
- Definir runtime Python, formato de configuracion y convenciones de artefactos.
- Definir contratos JSON versionados.
- Definir variables de entorno:
  - `OCR_SERVICE_BASE_URL`;
  - `OCR_ARTIFACTS_ROOT`;
  - `OCR_DEFAULT_ENGINE`;
  - `OCR_TESSERACT_PATH`;
  - `OCR_MAX_PAGES`;
  - `OCR_MAX_FILE_MB`.
- Definir politica de limpieza de jobs.

Entregable: servicio arranca con `/health`, `/api/ocr/status` y `/api/ocr/operations`.

### Fase 1: MVP Tesseract

- Implementar carga de imagenes y PDF.
- Implementar normalizacion DPI.
- Implementar preprocesamiento base.
- Implementar Tesseract.
- Implementar resultados JSON/TXT.
- Implementar job store en filesystem.
- Implementar tests unitarios de pipeline.
- Crear dataset minimo de validacion manual.

Entregable: OCR funcional sobre imagenes de `windows-twain` y archivos sueltos.

### Fase 2: integracion GDMS

- Crear cliente HTTP en backend.
- Crear contratos `Gdms.Contracts/Ocr`.
- Agregar endpoints backend de OCR por documento.
- Persistir texto extraido y metadata.
- Integrar busqueda documental.
- Agregar auditoria.
- Agregar UI Flutter `feature_ocr`.

Entregable: usuario ejecuta OCR desde GDMS y ve texto/estado/artefactos.

### Fase 3: PDF searchable y artefactos

- Generar PDF searchable con capa de texto.
- Exponer descarga desde backend.
- Guardar diagnosticos por pagina.
- Agregar preview de imagen preprocesada.
- Agregar comparacion original/preprocesada.

Entregable: documento escaneado puede convertirse en PDF searchable trazable.

### Fase 4: PaddleOCR y layout

- Agregar plugin PaddleOCR.
- Agregar seleccion `engine=auto`.
- Agregar deteccion de orientacion.
- Agregar layout detection.
- Evaluar PP-Structure para tablas.
- Comparar Tesseract vs PaddleOCR con dataset propio.

Entregable: mejor precision en documentos complejos y layouts no triviales.

### Fase 5: Android

- Agregar flujo Flutter/Android de captura movil.
- Integrar CameraX en Android nativo si Flutter puro no alcanza.
- Integrar ML Kit Text Recognition para OCR preliminar.
- Implementar fallback directo al `ocr-service` cuando ML Kit no este disponible o no alcance confianza minima.
- Agregar cola local para capturas pendientes.
- Sincronizar captura al backend.
- Marcar diferencia entre resultado preliminar mobile y OCR oficial.

Entregable: captura movil con OCR preliminar y reprocesamiento central.

### Fase 6: escalabilidad y operacion

- Dockerizar `ocr-service`.
- Agregar procesamiento asincronico real con cola.
- Agregar limites por organización.
- Agregar metricas Prometheus/OpenTelemetry si el stack lo incorpora.
- Agregar GPU opcional para PaddleOCR.
- Agregar runbook operativo.

Entregable: servicio listo para preproduccion.

## 15. Validacion y metricas

Metricas tecnicas:

- CER objetivo inicial: menor a 8% en dataset controlado.
- WER objetivo inicial: menor a 15% en dataset controlado.
- Tiempo objetivo CPU: menor a 2 segundos por pagina simple, sujeto a hardware.
- Tiempo objetivo GPU futuro: menor a 0.5 segundos por pagina simple, sujeto a hardware.
- Confianza promedio por pagina.
- Tasa de paginas fallidas.
- Tamano promedio de artefactos.

Dataset minimo:

- Documentos 150, 200, 300 y 600 DPI.
- Escaneos TWAIN reales.
- Fotos Android con sombra.
- Documentos rotados.
- Documentos con bajo contraste.
- PDFs multipagina.
- Documentos con tablas.

Pruebas:

- Unitarias para preprocesamiento.
- Integracion API OCR.
- Integracion backend.
- E2E desde escaneo a OCR.
- E2E desde captura movil a OCR central.
- Pruebas de regresion con ground truth.

## 16. Riesgos y mitigaciones

- Dependencias pesadas de OCR: aislar en `ocr-service` y Docker.
- Diferencias Windows/Linux: validar Tesseract y fuentes en ambos entornos.
- Calidad variable de imagenes moviles: usar guia de captura, blur detection y reprocesamiento central.
- Tiempos altos en PDF multipagina: usar jobs asincronicos y limites.
- PaddleOCR/GPU aumenta complejidad operativa: dejarlo para fase avanzada.
- PDF searchable puede desalinear texto si no se preservan coordenadas: validar por pagina con bounding boxes.
- Datos sensibles: definir retencion, limpieza y almacenamiento cifrado antes de produccion.

## 17. Estructura de artefactos sugerida

```text
artifacts/ocr/
  jobs/
    ocr_20260424_000001/
      job.json
      input/
      pages/
        page-001.original.png
        page-001.normalized.png
        page-001.preprocessed.png
        page-001.diagnostics.json
      output/
        result.json
        result.txt
        searchable.pdf
      logs/
        pipeline.log
```

## 18. Criterios de aceptacion MVP

- `ocr-service` arranca localmente y responde health/status.
- Se puede enviar una imagen escaneada por `windows-twain`.
- El servicio devuelve texto y bounding boxes.
- El servicio genera `result.json` y `result.txt`.
- El job queda consultable por ID.
- Errores de archivo invalido, pagina inexistente y timeout devuelven respuestas controladas.
- Existe documentacion de ejecucion local.
- Existe al menos un test de integracion con imagen real o fixture.

## 19. Fuentes tecnicas consultadas

- Documento interno: `informacion_para_generar_modulo_ocr.md`.
- Tesseract OCR: https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html
- Tesseract proyecto: https://tesseractocr.org/
- PaddleOCR OCR pipeline: https://www.paddleocr.ai/main/en/version3.x/pipeline_usage/OCR.html
- PaddleOCR deployment: https://www.paddleocr.ai/v2.10.0/en/infer_deploy/index.html
- Google ML Kit Text Recognition Android: https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- Android CameraX ML Kit Analyzer: https://developer.android.com/media/camera/camerax/mlkitanalyzer




