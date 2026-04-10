# gdms_app

Aplicación Flutter principal de `GDMS` para operar:

- autenticación y bootstrap;
- documentos;
- records;
- firma;
- workflow;
- verticales `Legal`, `Real Estate` y `Corporate`.

## Runtime esperado

La app consume:

- API backend por `GDMS_API_BASE_URL`
- host local de escaneo por `WINDOWS_TWAIN_BASE_URL`

Defaults actuales:

- API: `http://localhost:5012`
- `windows-twain`: `http://127.0.0.1:43127`

## Ejecutar la app

Con backend Docker en `8080`:

```powershell
cd C:\IA\codex\client\apps\gdms_app
flutter run -d windows `
  --dart-define=GDMS_API_BASE_URL=http://127.0.0.1:8080 `
  --dart-define=WINDOWS_TWAIN_BASE_URL=http://127.0.0.1:43127
```

Con backend local `.NET` en `5012`:

```powershell
cd C:\IA\codex\client\apps\gdms_app
flutter run -d windows `
  --dart-define=GDMS_API_BASE_URL=http://127.0.0.1:5012 `
  --dart-define=WINDOWS_TWAIN_BASE_URL=http://127.0.0.1:43127
```

## Lanzador recomendado

Desde la raíz del repo:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_gdms_app_ui_validation.ps1
```

Ese script:

- valida `API health`
- valida `windows-twain health`
- abre `gdms_app` con los `dart-define` correctos

## Validación UI documental

La guía corta para validar el flujo real `login/bootstrap -> escaneo -> upload -> documento visible` está en:

- [runbook_validacion_ui_documental_local.md](C:\IA\codex\docs\runbook_validacion_ui_documental_local.md)

## Automatización UI

La automatización de ese flujo vive en:

- [gdms_app_ui_document_scan_flow_test.dart](C:\IA\codex\client\apps\gdms_app\integration_test\gdms_app_ui_document_scan_flow_test.dart)

Runner recomendado:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_gdms_app_ui_automation.ps1
```

Ese runner deja además:

- `artifacts\ui-tests\gdms_app_ui_automation.log`
- `artifacts\ui-tests\gdms_app_ui_automation_summary.json`
- `artifacts\ui-tests\gdms_app_ui_automation_summary.md`

## Verificación de calidad

Desde la raíz del monorepo Flutter:

```powershell
cd C:\IA\codex\client
melos run analyze
melos run test
```
