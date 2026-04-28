# GDMS

Sistema de gestión documental y `ECM` modular, instancia única, auditable y orientado a operación real.

El repositorio incluye:

- backend `.NET`;
- frontend `Flutter`;
- base de datos `PostgreSQL`;
- host local de escaneo `windows-twain`;
- infraestructura local con Docker;
- documentación funcional, técnica y operativa.

## Documentos principales

Leer primero estos archivos:

- guía general del proyecto: [wiki.md](C:\IA\codex\wiki.md)
- setup del entorno Windows: [scripts\setup\windows\README.md](C:\IA\codex\scripts\setup\windows\README.md)
- manual de usuario: [MANUAL_USUARIO.md](C:\IA\codex\MANUAL_USUARIO.md)
- contexto técnico y estado del proyecto: [contexto_handoff.md](C:\IA\codex\contexto_handoff.md)
- requisitos funcionales: [rf.md](C:\IA\codex\rf.md)
- requisitos no funcionales: [rnf.md](C:\IA\codex\rnf.md)
- estructura documental configurable: [docs\estructura_documental_configurable.md](C:\IA\codex\docs\estructura_documental_configurable.md)

## Estructura principal

- backend: [server](C:\IA\codex\server)
- frontend: [client](C:\IA\codex\client)
- escaneo local: [windows-twain](C:\IA\codex\windows-twain)
- base de datos: [database](C:\IA\codex\database)
- scripts: [scripts](C:\IA\codex\scripts)
- documentación adicional: [docs](C:\IA\codex\docs)

## Estado resumido

Avance estimado actual del proyecto: `86%`.

Bloques con mayor avance:

- backend base;
- frontend operativo;
- módulo documental;
- escaneo con `windows-twain`;
- administración, auditoría, búsqueda, workflow, firma, records, reportes y notificaciones;
- verticales `Legal`, `Real Estate` y `Corporate`.

Bloques con mayor trabajo pendiente:

- integraciones productivas reales;
- storage y búsqueda productivos;
- observabilidad;
- seguridad operativa;
- despliegue y validación end-to-end.

## Cómo empezar rápido

### 1. Configurar el entorno

Seguir:

- [scripts\setup\windows\README.md](C:\IA\codex\scripts\setup\windows\README.md)

### 2. Abrir el repo en Visual Studio Code

```powershell
code C:\IA\codex
```

### 3. Levantar los subproyectos principales

#### Backend con Docker

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\setup\windows\16-run-gdms-docker.ps1
```

#### API local `.NET`

```powershell
cd C:\IA\codex\server
dotnet run --project .\src\Gdms.Api\Gdms.Api.csproj
```

#### Host local de escaneo

```powershell
cd C:\IA\codex\windows-twain
dotnet run --project .\windows-twain.csproj
```

#### App Flutter

```powershell
cd C:\IA\codex\client\apps\gdms_app
flutter run --dart-define=GDMS_API_BASE_URL=http://localhost:5012
```

### 4. Validar el workspace

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\quality\validate_workspace.ps1
```

## Roadmap y plan

El detalle del plan de desarrollo y del roadmap está en:

- [wiki.md](C:\IA\codex\wiki.md)
- [docs\plan_desarrollo_sesiones_grandes.md](C:\IA\codex\docs\plan_desarrollo_sesiones_grandes.md)
- [docs\runbook_preproduccion_local.md](C:\IA\codex\docs\runbook_preproduccion_local.md)
- [docs\runbook_validacion_ui_documental_local.md](C:\IA\codex\docs\runbook_validacion_ui_documental_local.md)
- [docs\runbook_recovery_local.md](C:\IA\codex\docs\runbook_recovery_local.md)
- [docs\observabilidad_local.md](C:\IA\codex\docs\observabilidad_local.md)

## Manual de uso

El manual funcional del sistema está en:

- [MANUAL_USUARIO.md](C:\IA\codex\MANUAL_USUARIO.md)



