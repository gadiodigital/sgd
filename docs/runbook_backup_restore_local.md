# Runbook de Backup y Restore Local

## Objetivo

Tener un procedimiento corto y verificable para respaldar y restaurar localmente:

- PostgreSQL del repo;
- storage documental local de la API.

## Scripts operativos

- backup: [backup_local_stack.ps1](C:\IA\codex\scripts\ops\backup_local_stack.ps1)
- restore: [restore_local_stack.ps1](C:\IA\codex\scripts\ops\restore_local_stack.ps1)
- verificación integrada: [verify_local_backup_restore.ps1](C:\IA\codex\scripts\ops\verify_local_backup_restore.ps1)
- reprovisión completa: [reprovision_stack_from_backup.ps1](C:\IA\codex\scripts\ops\reprovision_stack_from_backup.ps1)
- métricas persistidas del drill: [write_recovery_drill_metrics.ps1](C:\IA\codex\scripts\ops\write_recovery_drill_metrics.ps1)

## Flujo integrado recomendado

No correr `verify_local_backup_restore.ps1` y `reprovision_stack_from_backup.ps1` en paralelo: ambos comparten el mismo stack Docker, PostgreSQL y fixture de recovery.

Si querés verificar en una sola pasada `backup -> restore seguro -> smoke posterior`:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\verify_local_backup_restore.ps1 -RunSmokeAfterRestore -RunBusinessIntegrityChecks -EnsureBusinessFixture
```

Resultado esperado:

- se genera un bundle bajo `artifacts\ops\backups\backup_<timestamp>`;
- se restaura sobre una base temporal `gdms_restore_validation_<timestamp>`;
- se restaura storage en `artifacts\ops\restore_validation\storage_<timestamp>`;
- el smoke operativo estricto posterior queda en verde.
- la integridad de negocio post-restore queda validada sobre seeds, tablas core y consistencia documental minima.
- si se usa `-EnsureBusinessFixture`, tambien se valida un documento fixture con dos versiones, ACL explicita, hash, tamano y metadata restaurados.
- ademas se persiste un artefacto comparable de RTO en `artifacts\ops\recovery_metrics\history.jsonl`, `latest.json` y `latest.md`.
- el artefacto ahora incluye tambien `RpoObservedMs`, calculado desde `manifest.json` del bundle hasta la finalizacion del drill.
- al `2026-04-09`, los thresholds de `RTO`, `ValidationExecutionMs` y `RPO` para `temp_restore_validation` y `stack_reprovision` ya estan operando en modo `rolling`.
- desde `2026-04-10`, los drills tambien pueden etiquetar `MetricsProfile` (`local-light` o `preproduction-strict`) para separar baseline por perfil sin romper compatibilidad con historial legacy.
- desde esta misma sesion, tambien pueden etiquetar `MetricsScenario` (`local-idle` o `preproduction-smoke`) para separar baseline por escenario dentro de un mismo perfil.

## 1. Prerrequisitos

- Docker Desktop operativo.
- Contenedor `gdms-postgres` arriba.
- Stack local en el repo `C:\IA\codex`.

## 2. Generar un backup

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\backup_local_stack.ps1
```

Resultado esperado:

- se crea un bundle bajo `artifacts\ops\backups\backup_<timestamp>`;
- el bundle contiene `postgres_gdms.dump`, `document_storage.zip` y `manifest.json`.

## 3. Restore de validación segura

Esto no toca la base principal ni el storage activo. Restaura sobre una base temporal y una carpeta de validación.

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\restore_local_stack.ps1 -BackupBundlePath .\artifacts\ops\backups\backup_<timestamp>
```

Resultado esperado:

- base restaurada en `gdms_restore_validation`;
- storage restaurado bajo `artifacts\ops\restore_validation\...`;
- resumen con cantidad de tablas y archivos restaurados.

## 4. Restore sobre entorno local principal

Solo si realmente querés reponer el entorno activo.

```powershell
cd C:\IA\codex
docker compose stop api
powershell -ExecutionPolicy Bypass -File .\scripts\ops\restore_local_stack.ps1 `
  -BackupBundlePath .\artifacts\ops\backups\backup_<timestamp> `
  -TargetDatabaseName gdms `
  -AllowPrimaryDatabaseRestore `
  -TargetStorageRoot .\server\src\Gdms.Api\data\storage\documents `
  -AllowPrimaryStorageRestore
docker compose start api
```

## 5. Verificación posterior

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1
```

Si además querés evidencia operativa:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\get_local_operational_snapshot.ps1
```

## 6. Criterio de salida

La operación se considera válida cuando:

- el bundle se genera sin errores;
- el restore de validación reconstruye PostgreSQL y storage en destinos temporales;
- el smoke operativo posterior queda en verde cuando se usa la verificación integrada o cuando se reponen destinos principales.
- el drill deja artefacto de métricas con `RecoveryExecutionMs`, `ValidationExecutionMs` y `RtoObservedMs` para comparación entre corridas.
