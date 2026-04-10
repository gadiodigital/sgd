# Runbook de Recovery Local

## Objetivo

Tener una guía corta para recuperar el stack local cuando falla alguno de los componentes operativos principales:

- API `gdms-api`
- PostgreSQL del repo
- `windows-twain`

## 1. Diagnóstico rápido

### Docker y API

```powershell
cd C:\IA\codex
docker compose ps
docker compose logs api --tail 200
docker compose logs postgres --tail 200
```

### Reachability

```powershell
Invoke-WebRequest http://127.0.0.1:8080/swagger/index.html
Invoke-RestMethod http://127.0.0.1:8080/api/health
Test-NetConnection 127.0.0.1 -Port 5433
Invoke-RestMethod http://127.0.0.1:43127/health
```

## 2. Recovery de API + PostgreSQL

### Reinicio normal

```powershell
cd C:\IA\codex
docker compose down
docker compose up -d --build
```

### Validación posterior

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1
```

## 3. Recovery de `windows-twain`

### Levantar en modo headless

```powershell
cd C:\IA\codex\windows-twain
dotnet run --project .\windows-twain.csproj -- --headless
```

### Healthcheck posterior

```powershell
Invoke-RestMethod http://127.0.0.1:43127/health
Invoke-RestMethod http://127.0.0.1:43127/api/status
```

### Limpieza operativa si reaparecen sesiones viejas

```powershell
Invoke-RestMethod -Method Delete http://127.0.0.1:43127/api/sessions/rehydrated
Invoke-RestMethod -Method Post http://127.0.0.1:43127/api/sessions/cleanup
```

## 4. Smoke completo con host de escaneo

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -IncludeScanHost
```

## 5. Criterio de salida

La recuperación local se considera completa cuando:

- `docker compose ps` muestra `gdms-api` y `postgres` arriba;
- `invoke_preproduction_smoke.ps1` termina en verde;
- si aplica escaneo, `invoke_preproduction_smoke.ps1 -IncludeScanHost` también queda en verde.

## 6. Backup y restore

Para respaldo y reposición local mínima:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\backup_local_stack.ps1
```

Restore de validación segura:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\restore_local_stack.ps1 -BackupBundlePath .\artifacts\ops\backups\backup_<timestamp>
```

El procedimiento completo quedó detallado en [runbook_backup_restore_local.md](C:\IA\codex\docs\runbook_backup_restore_local.md).

## 7. Drill de reprovisión completa

Si querés validar una recuperación más cercana a incidente real:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\reprovision_stack_from_backup.ps1 -CreateFreshBackup -RunSmokeAfterRestore -RunBusinessIntegrityChecks -EnsureBusinessFixture
```

Ese flujo:

- genera un backup fresco;
- ejecuta `docker compose down -v`;
- levanta otra vez el stack;
- restaura la base principal y el storage principal desde el backup;
- vuelve a correr el smoke estricto.
- valida integridad de negocio minima sobre el estado restaurado.
- si se usa `-EnsureBusinessFixture`, valida tambien un documento fixture con dos versiones, ACL explicita y binarios restaurados.

Resultado actual esperado:

- el drill debe quedar en verde;
- puede persistir una advertencia `WARN` por Data Protection sin cifrado en reposo del host, tratada como riesgo residual local aceptado.
