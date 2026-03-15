# windows-twain

## Base de la API

- Base URL por defecto: `http://127.0.0.1:43127`
- Health: `GET /health`
- La ruta `GET /` redirige a `/health`
- Formato principal: `application/json`
- Descargas:
  - previews: `image/jpeg`
  - PDF final: `application/pdf`

La aplicación lee la configuración desde `appsettings.json` y también desde variables de entorno con prefijo `WINDOWS_TWAIN_`.

## Estado general

### `GET /health`

Sirve para saber si el host local está levantado.

Respuesta ejemplo:

```json
{
  "application": "windows-twain",
  "version": "1.0.0.0",
  "status": "ok",
  "startedAtUtc": "2026-03-15T16:20:00.0000000+00:00",
  "baseUrl": "http://127.0.0.1:43127"
}
```

### `GET /api/status`

Devuelve estado del proceso, modo de ejecución, log de arranque, operaciones disponibles y estado del scanner.

Uso:

```bash
curl http://127.0.0.1:43127/api/status
```

Campos relevantes:

- `application`: nombre de la app.
- `version`: versión del assembly.
- `baseUrl`: URL del host local.
- `startedAtUtc`: momento de inicio.
- `runMode`: `tray` o `headless`.
- `startupLogPath`: ruta del log.
- `scanner`: estado de integración TWAIN.
- `operations`: operaciones publicadas por la API.

### `GET /api/operations`

Lista las operaciones declaradas por el servicio.

Uso:

```bash
curl http://127.0.0.1:43127/api/operations
```

Hoy expone estas operaciones:

- `list-scanners`
- `scan-flatbed-single`
- `scan-adf-simplex`
- `scan-adf-duplex`
- `get-session`
- `get-page-preview`
- `delete-page`
- `rotate-page`
- `export-pdf`

## Descubrimiento de escáneres

### `GET /api/scanners`

Lista los escáneres TWAIN detectados.

### `POST /api/scanners/discover`

Hace lo mismo que el endpoint anterior, pero vía `POST`.

Uso:

```bash
curl http://127.0.0.1:43127/api/scanners
```

```bash
curl -X POST http://127.0.0.1:43127/api/scanners/discover
```

Respuesta ejemplo:

```json
{
  "result": "ok",
  "timestampUtc": "2026-03-15T16:20:00.0000000+00:00",
  "transport": "twain",
  "processArchitecture": "x64",
  "scanners": [
    {
      "id": 0,
      "name": "EPSON DS-570W",
      "manufacturer": "EPSON",
      "productFamily": "Scanner",
      "twainVersion": "2.4",
      "isOpen": false
    }
  ],
  "message": "Se detectaron 1 escaner(es) TWAIN."
}
```

Notas:

- Si `result = "error"`, el servicio responde igual con JSON, pero con `scanners: []` y el detalle en `message`.
- `processArchitecture` importa para compatibilidad de drivers TWAIN (`x86` vs `x64`).

## Escaneo

## Parámetros comunes de escaneo

Estos parámetros aplican a `POST /api/scans/adf/simplex` y `POST /api/scans/adf/duplex`.

Body JSON:

```json
{
  "scannerId": 0,
  "scannerName": "EPSON DS-570W",
  "timeoutSeconds": 90,
  "dpi": 300,
  "pixelType": "color",
  "discardBlankPages": "auto"
}
```

Campos:

- `scannerId`: opcional. Si se envía, tiene prioridad para elegir el scanner.
- `scannerName`: opcional. Se usa si no vino `scannerId`.
- `timeoutSeconds`: opcional. Default `90`. Internamente se fuerza al rango `15..300`.
- `dpi`: opcional. Debe estar entre `50` y `1200`.
- `pixelType`: opcional. Valores válidos:
  - `bw`
  - `gray`
  - `color`
- `discardBlankPages`: opcional. Valores válidos:
  - `off`
  - `auto`

Comportamiento si no se indica scanner:

- La API toma el primer source devuelto por TWAIN.

Comportamiento si el body es `null` o vacío:

- Usa defaults: `timeoutSeconds = 90`, `dpi = null`, `pixelType = null`, `discardBlankPages = off`.

### `POST /api/scans/adf/simplex`

Escanea todo el ADF a una cara.

Uso:

```bash
curl -X POST http://127.0.0.1:43127/api/scans/adf/simplex \
  -H "Content-Type: application/json" \
  -d "{\"scannerId\":0,\"dpi\":300,\"pixelType\":\"gray\",\"discardBlankPages\":\"auto\"}"
```

### `POST /api/scans/adf/duplex`

Escanea todo el ADF en doble faz.

Uso:

```bash
curl -X POST http://127.0.0.1:43127/api/scans/adf/duplex \
  -H "Content-Type: application/json" \
  -d "{\"scannerName\":\"EPSON DS-570W\",\"dpi\":300,\"pixelType\":\"color\"}"
```

Respuesta de éxito ejemplo:

```json
{
  "result": "ok",
  "sessionId": "378140186ee342e29239b86d6b86be8f",
  "status": "completed",
  "createdAtUtc": "2026-03-15T16:20:00.0000000+00:00",
  "scannerName": "EPSON DS-570W",
  "mode": "adf-simplex",
  "settings": {
    "dpi": 300.0,
    "pixelType": "gray",
    "discardBlankPages": "auto",
    "transferFormat": "bmp"
  },
  "pageCount": 2,
  "pages": [
    {
      "pageNumber": 1,
      "fileName": "page-001.bmp",
      "filePath": "C:\\...\\sessions\\378140186ee342e29239b86d6b86be8f\\page-001.bmp",
      "transferType": "File",
      "fileFormat": "Bmp",
      "length": 1234567
    }
  ],
  "sessionPath": "C:\\...\\sessions\\378140186ee342e29239b86d6b86be8f",
  "message": "Escaneo finalizado con 2 pagina(s)."
}
```

Estados posibles:

- `running`
- `completed`
- `empty`
- `canceled`
- `error`

Errores frecuentes en `message`:

- no hay escáneres TWAIN disponibles
- no existe scanner con ese `id` o `name`
- el ADF no reporta hojas cargadas
- el driver no permite configurar `dpi`, `pixelType` o descarte de blancas
- el scanner no soporta duplex
- timeout agotado

### `POST /api/scans/flatbed/single`

Existe pero no está implementado.

Uso:

```bash
curl -X POST http://127.0.0.1:43127/api/scans/flatbed/single
```

Respuesta:

```json
{
  "operationId": "scan-flatbed-single",
  "result": "not-ready",
  "message": "La operacion existe pero todavia no esta implementada en esta fase.",
  "timestampUtc": "2026-03-15T16:20:00.0000000+00:00"
}
```

Status HTTP: `501 Not Implemented`

## Sesiones

### `GET /api/scans/{sessionId}`

Recupera el estado actual de una sesión ya creada.

Uso:

```bash
curl http://127.0.0.1:43127/api/scans/378140186ee342e29239b86d6b86be8f
```

Respuesta:

- `200` con el mismo esquema de `ScanSessionResponse` visto en los endpoints de escaneo.
- `404` si la sesión no existe.

Error `404` ejemplo:

```json
{
  "result": "not-found",
  "sessionId": "inexistente",
  "message": "No existe una sesion con ese identificador."
}
```

## Previews

### `GET /api/scans/{sessionId}/pages/{pageNumber}/preview`

Genera o reutiliza una preview JPEG de una página.

Query params opcionales:

- `width`: ancho máximo. Si no se envía y tampoco viene `height`, usa `320`.
- `height`: alto máximo.
- `quality`: calidad JPEG. Default `75`.

Normalización interna:

- `width` y `height`:
  - si son `<= 0`, se ignoran
  - rango efectivo: `64..2048`
- `quality`:
  - rango efectivo: `30..95`

Uso:

```bash
curl "http://127.0.0.1:43127/api/scans/378140186ee342e29239b86d6b86be8f/pages/1/preview?width=900&quality=82" --output preview.jpg
```

Respuesta:

- `200` con imagen `image/jpeg`
- `404` si la sesión no existe
- `400` si la página no existe o hay un problema al generar la preview

## Edición de páginas

### `POST /api/scans/{sessionId}/pages/{pageNumber}/rotate`

Rota una página y devuelve la sesión actualizada.

Body JSON:

```json
{
  "degrees": 90
}
```

Valores válidos para `degrees`:

- `90`
- `180`
- `270`
- `-90`
- `-180`
- `-270`

Uso:

```bash
curl -X POST http://127.0.0.1:43127/api/scans/378140186ee342e29239b86d6b86be8f/pages/1/rotate \
  -H "Content-Type: application/json" \
  -d "{\"degrees\":90}"
```

Notas:

- Si no se manda body, el valor por defecto es `90`.
- Al rotar se invalidan el PDF exportado y las previews ya generadas para esa sesión.

Errores:

- `404` si la sesión no existe
- `400` si la página no existe
- `400` si `degrees` no es uno de los valores permitidos
- `400` si falta el archivo físico de la página

### `DELETE /api/scans/{sessionId}/pages/{pageNumber}`

Elimina una página, renumera el resto y devuelve la sesión actualizada.

Uso:

```bash
curl -X DELETE http://127.0.0.1:43127/api/scans/378140186ee342e29239b86d6b86be8f/pages/2
```

Notas:

- Si la sesión queda vacía, el `status` pasa a `empty`.
- También invalida el PDF exportado y todas las previews de la sesión.

Errores:

- `404` si la sesión no existe
- `400` si la página no existe
- `400` si falta el archivo físico de la página

## Exportación a PDF

### `GET /api/scans/{sessionId}/pdf`

Genera el PDF final si no existe y lo devuelve como archivo.

Uso:

```bash
curl http://127.0.0.1:43127/api/scans/378140186ee342e29239b86d6b86be8f/pdf --output documento.pdf
```

Respuesta:

- `200` con `application/pdf`
- `404` si la sesión no existe
- `400` si la sesión no tiene páginas o falta alguna imagen en disco

Notas:

- El nombre descargable es `{sessionId}.pdf`.
- El PDF se arma usando el tamaño real de cada imagen escaneada.

## Códigos HTTP y formato de error

La API no usa un único envelope de error global. Según el endpoint, los errores salen así:

- `404`:

```json
{
  "result": "not-found",
  "sessionId": "abc",
  "message": "..."
}
```

- `400`:

```json
{
  "result": "error",
  "sessionId": "abc",
  "pageNumber": 1,
  "message": "...",
  "filePath": "C:\\ruta\\archivo.bmp"
}
```

- `501`:

```json
{
  "operationId": "scan-flatbed-single",
  "result": "not-ready",
  "message": "...",
  "timestampUtc": "..."
}
```

## Flujo recomendado

1. `GET /api/scanners` para identificar el scanner.
2. `POST /api/scans/adf/simplex` o `POST /api/scans/adf/duplex`.
3. `GET /api/scans/{sessionId}` para consultar páginas y metadatos.
4. `GET /api/scans/{sessionId}/pages/{pageNumber}/preview` para mostrar previews.
5. `POST /api/scans/{sessionId}/pages/{pageNumber}/rotate` o `DELETE /api/scans/{sessionId}/pages/{pageNumber}` si hace falta editar.
6. `GET /api/scans/{sessionId}/pdf` para descargar el resultado final.
