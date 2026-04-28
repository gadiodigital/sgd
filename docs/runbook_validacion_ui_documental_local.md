# Runbook de Validación UI Documental Local

## Objetivo

Dejar un recorrido corto y repetible para validar la UI real de `gdms_app` contra:

- API local en Docker o `.NET`;
- PostgreSQL del repo;
- `windows-twain` local.

## Prerrequisitos

- API accesible en `http://127.0.0.1:8080` o `http://127.0.0.1:5012`
- `windows-twain` accesible en `http://127.0.0.1:43127`
- Flutter operativo en la PC

## Arranque rápido

Con stack Docker ya levantado y `windows-twain` corriendo:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_gdms_app_ui_validation.ps1
```

Si querés apuntar a la API local `.NET`:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_gdms_app_ui_validation.ps1 `
  -ApiBaseUrl http://127.0.0.1:5012
```

Si querés abrir la app en Chrome en vez de Windows:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_gdms_app_ui_validation.ps1 `
  -Device chrome
```

## Recorrido manual recomendado

### 1. Ingreso inicial

En la pantalla `Ingreso al GDMS`:

- `URL API backend`: usar la misma URL con la que lanzaste la app
- `Modo de acceso`: elegir `Organización admin`
- `Codigo de organización`: por ejemplo `SCAN-DEMO`
- `Email`: por ejemplo `scan.demo.admin@organización.ar`
- `Nombre completo`: por ejemplo `Scan Demo Admin`
- `Password`: una clave de al menos `8` caracteres
- botón: `Crear administrador de organización`

Resultado esperado:

- ingreso exitoso a la shell autenticada;
- banner superior mostrando organización activo y base URL de API.

### 2. Abrir el flujo documental

Dentro de la app:

- ir al módulo `Documents`
- abrir la acción de carga documental
- elegir `Escanear documento`

Resultado esperado:

- aparece el diálogo `Escanear documento`;
- se ve el estado del host `windows-twain`;
- se muestran scanners detectados o mensajes de readiness.

### 3. Validar host y scanner

En el diálogo de escaneo:

- usar `Redescubrir escaneres` si no aparece ninguno;
- elegir el scanner disponible;
- verificar que el resumen operativo no muestre error de conexión;
- dejar `ADF` o `flatbed` según el equipo real disponible.

Resultado esperado:

- no aparece el mensaje `El servicio windows-twain no responde...`;
- el scanner queda seleccionado;
- la acción de escaneo queda habilitada.

### 4. Ejecutar escaneo

- disparar el escaneo desde el diálogo;
- esperar la preview;
- si hace falta, revisar páginas o sesión activa.

Resultado esperado:

- preview visible o mensaje operativo de PDF disponible;
- resumen del scan con nombre de archivo, cantidad de páginas y scanner.

### 5. Subir documento escaneado

Desde el flujo de carga:

- completar metadatos mínimos;
- elegir tipo documental válido, por ejemplo `CONTRACT`;
- completar título;
- confirmar `Subir documento`.

Resultado esperado:

- upload exitoso al backend;
- el documento aparece en el listado dla organización;
- al abrir detalle, la descarga del binario responde.

## Verificaciones mínimas

La validación UI se considera aceptable si se cumple todo esto:

- login/bootstrap exitoso desde la app;
- `Escanear documento` abre y detecta `windows-twain`;
- el escaneo devuelve preview o PDF válido;
- el upload documental termina en verde;
- el documento queda visible y descargable desde `Documents`.

## Relación con otros runbooks

- smoke operativo: [runbook_preproduccion_local.md](C:\IA\codex\docs\runbook_preproduccion_local.md)
- recovery local: [runbook_recovery_local.md](C:\IA\codex\docs\runbook_recovery_local.md)
- observabilidad local: [observabilidad_local.md](C:\IA\codex\docs\observabilidad_local.md)

## Automatización disponible

La automatización actual del recorrido UI principal está en:

- [gdms_app_ui_document_scan_flow_test.dart](C:\IA\codex\client\apps\gdms_app\integration_test\gdms_app_ui_document_scan_flow_test.dart)

Runner:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_gdms_app_ui_automation.ps1
```

Esa prueba monta un backend fake y un host `windows-twain` fake en puertos dedicados y valida:

- bootstrap `Organización admin`
- navegación a `Documentos`
- apertura del flujo real de escaneo
- escaneo y confirmación `Usar escaneo`
- upload documental y refresco del listado

## CI opt-in

El workflow de CI ya tiene un job dedicado:

- `gdms-app-ui-automation`

Se habilita con la variable de repo:

- `GDMS_ENABLE_UI_AUTOMATION=true`

Artifacts esperados:

- `artifacts\ui-tests\gdms_app_ui_automation.log`
- `artifacts\ui-tests\gdms_app_ui_automation_summary.json`
- `artifacts\ui-tests\gdms_app_ui_automation_summary.md`
- binarios/debug output de `client\apps\gdms_app\build\windows\x64\runner\Debug`

Para lectura rápida en CI, el archivo más útil es:

- `artifacts\ui-tests\gdms_app_ui_automation_summary.md`



