# Runbook de Preproducción Local

## Objetivo

Dejar una guía corta y repetible para verificar que el stack local de `GDMS` está listo para una validación operativa de punta a punta.

## Alcance mínimo

Este runbook cubre:

- API `.NET`;
- Swagger;
- PostgreSQL del repo;
- `windows-twain` opcional cuando el flujo de escaneo entra en la validación.

## Prerrequisitos

- Docker Desktop operativo.
- Stack levantado con [16-run-gdms-docker.ps1](C:\IA\codex\scripts\setup\windows\16-run-gdms-docker.ps1) o `docker compose up --build -d`.
- Si se valida escaneo, `windows-twain` levantado localmente.
- Revisar `.env` local; si no existe, crear uno desde [\.env.example](C:\IA\codex\.env.example) y definir al menos `GDMS_JWT_SIGNING_KEY`.

## Arranque rápido

### 1. Levantar backend y PostgreSQL

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\setup\windows\16-run-gdms-docker.ps1
```

Resultado esperado:

- API en `http://127.0.0.1:8080`
- Swagger en `http://127.0.0.1:8080/swagger`
- PostgreSQL en `127.0.0.1:5433`

### 1.1 Perfil local de preproducción estricta

Si querés validar el stack con settings menos permisivos:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\use_preproduction_profile.ps1
```

Después, reemplazar en `.env` al menos:

- `GDMS_POSTGRES_PASSWORD`
- `GDMS_JWT_SIGNING_KEY`
- revisar `GDMS_API_ENABLE_HTTPS_REDIRECTION` según el perfil local que quieras validar

Si cambiás `GDMS_POSTGRES_PASSWORD` y ya existe un volumen PostgreSQL inicializado con otra clave, reprovisionar antes de levantar el stack con ese perfil:

```powershell
cd C:\IA\codex
docker compose down -v
powershell -ExecutionPolicy Bypass -File .\scripts\setup\windows\16-run-gdms-docker.ps1
```

### 2. Ejecutar smoke operativo

Camino recomendado, ya con preset estricto de preproducción:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_preproduction_strict_smoke.ps1
```

Si además querés refrescar la baseline estricta de recovery/capacidad con una corrida serial controlada:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\refresh_preproduction_strict_baseline.ps1
```

Ese helper corre en serie:

- `temp_restore_validation` con `MetricsProfile=preproduction-strict`;
- `stack_reprovision` con `MetricsProfile=preproduction-strict`;
- ambos drills etiquetados tambien con `MetricsScenario=preproduction-smoke`;
- refresh de capacidad para `preproduction-strict / preproduction-smoke`.

Overrrides útiles:

- `-TempRestoreIterations N`
- `-StackReprovisionIterations N`
- `-SkipCapacityChecks`

Ese mismo entrypoint ya puede ejecutarse también desde CI mediante el job `preproduction-strict-smoke` de [ci.yml](C:\IA\codex\.github\workflows\ci.yml). El job queda desactivado por defecto y se habilita con la variable de repo `GDMS_ENABLE_PREPRODUCTION_SMOKE=true`, pensada para runners que realmente tengan Docker disponible.

Desde `2026-04-10`, ese job además ejecuta una selección corta de `Gdms.E2eSmokeTests` contra el PostgreSQL del stack levantado por Docker:

- `ScanEditableSessionSmokeTests`
- `ScanHostRecoverySmokeTests`
- `ScanHostRetryRecoverySmokeTests`
- `ScanHostCorsSmokeTests`

Con eso, CI no valida solo reachability operativa, sino también:

- el flujo `windows-twain -> PDF -> upload backend -> download`
- edición de sesión rehidratada antes del upload
- recuperación del host de escaneo tras reinicio o caída
- contrato CORS `browser -> localhost` del host local

Cuando ese job corre, publica también evidencia operativa en artifacts de GitHub Actions:

- en éxito:
  - `artifacts/ops/ci`
  - `capacity_metrics`
  - `recovery_metrics`
- en fallo:
  - todo lo anterior
  - snapshot operativo completo
  - logs de `docker compose`

Retención actual en CI:

- `coverage-reports`: `14` días;
- `preproduction-strict-smoke-summary`: `7` días;
- `preproduction-strict-smoke-failure`: `7` días.

Los artifacts del job ahora incluyen también:

- `artifacts\test-results\scan-e2e-smoke.trx`
- `artifacts\test-results\scan-e2e-smoke-summary.json`
- `artifacts\test-results\scan-e2e-smoke-summary.md`

Para lectura rápida del resultado de e2e en CI, el artefacto más útil es `scan-e2e-smoke-summary.md`, porque resume outcome total y conteo por suite sin abrir el `trx`.

Sin host de escaneo:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1
```

Con validación de configuración local:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration
```

Incluyendo `windows-twain`:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\run_preproduction_strict_smoke.ps1 -IncludeScanHost
```

## Checks incluidos

- `GET /api/health`
- `GET /swagger/index.html`
- reachability de `127.0.0.1:5433`
- `GET /health` de `windows-twain` cuando se usa `-IncludeScanHost`

## Diagnóstico rápido

Si falla API o Swagger:

```powershell
docker compose logs api --tail 200
```

Si falla PostgreSQL:

```powershell
docker compose logs postgres --tail 200
Test-NetConnection 127.0.0.1 -Port 5433
```

Si falla `windows-twain`:

```powershell
Invoke-WebRequest http://127.0.0.1:43127/health
```

Si querés que el smoke deje snapshot automático al fallar:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -CaptureSnapshotOnFailure
```

Ese snapshot deja ahora tres artefactos complementarios en `artifacts\ops`:

- `local_operational_snapshot.txt`
- `local_operational_snapshot.json`
- `local_operational_snapshot.md`

El `.json` sirve para gates y lectura automatizada; el `.md` para revisión rápida o adjuntar evidencia operativa.

Si querés aplicar un gate estricto de configuración para una validación más cercana a preproducción:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration
```

Ese modo estricto falla si detecta:

- `Jwt:SigningKey` ausente;
- `ASPNETCORE_ENVIRONMENT=Development`;
- Firebase en modo `emulator`;
- `AllowAnyOriginInDevelopment=true`;
- credenciales conocidas de desarrollo.

Si querés sumar chequeo de drift runtime y riesgos operativos visibles en logs:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks
```

Desde esta baseline, `invoke_preproduction_smoke.ps1` ya nace con defaults operativos de preproducción:

- `StrictConfiguration = true`
- `CapacityHeadroomProfile = preproduction-strict`
- `CapacityTrendProfile = preproduction-strict`
- `RecoveryThresholdProfile = preproduction-strict`
- `RecoveryThresholdScenario = preproduction-smoke`
- `CapacityScenario = preproduction-smoke`

Si necesitás volver al comportamiento liviano para laboratorio, el override explícito sigue siendo válido:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateCapacityHeadroom -CapacityHeadroomProfile local-light -ValidateCapacityTrend -CapacityTrendProfile local-light -CapacityScenario local-idle -ValidateRecoveryDrillThresholds -RecoveryThresholdProfile local-light
```

Si además querés un gate preventivo de espacio/capacidad:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks -ValidateCapacityHeadroom
```

Si querés exigir la variante más dura de capacidad para preproducción local:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks -ValidateCapacityHeadroom -CapacityHeadroomProfile preproduction-strict
```

Si además querés exigir que la tendencia reciente de capacidad no venga degradándose:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks -ValidateCapacityHeadroom -CapacityHeadroomProfile preproduction-strict -ValidateCapacityTrend -CapacityTrendProfile preproduction-strict
```

Para que capacidad y tendencia usen baseline del escenario más exigente:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks -ValidateCapacityHeadroom -CapacityHeadroomProfile preproduction-strict -CapacityScenario preproduction-smoke -ValidateCapacityTrend -CapacityTrendProfile preproduction-strict
```

Si además querés exigir que la última baseline de recovery siga dentro de umbrales observados:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks -ValidateCapacityHeadroom -ValidateRecoveryDrillThresholds
```

Perfiles disponibles para esos thresholds:

- `local-light`: baseline actual del repo, pensado para entorno local liviano.
- `preproduction-strict`: mismos checks, pero con thresholds y márgenes más exigentes.

Perfiles disponibles para capacidad:

- `local-light`: headroom mínimo para laboratorio local.
- `preproduction-strict`: headroom más exigente para validar espacio libre y crecimiento preventivo.

Estado actual al `2026-04-10`:

- `local-light` validado en verde.
- `preproduction-strict` también validado en verde contra el historial real actual.
- `preproduction-strict` ya tiene baseline etiquetada propia para `temp_restore_validation` y `stack_reprovision`.
- `refresh_preproduction_strict_baseline.ps1` ya permite poblar esa baseline en serie sin correr drills incompatibles en paralelo.
- `stack_reprovision` ya evita rebuild innecesario de imagen durante la medición del drill, para que el `RTO` refleje recovery del stack y no tiempo de `docker build`.
- con la baseline limpia ya refrescada, `preproduction-strict` quedó endurecido otra vez con márgenes móviles de recovery más cortos que en la iteración anterior.
- al `2026-04-10`, ese perfil ya quedó endurecido con thresholds y márgenes más exigentes que `local-light`.

Ejemplo en perfil estricto:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration -ValidateOperationalRisks -ValidateCapacityHeadroom -ValidateRecoveryDrillThresholds -RecoveryThresholdProfile preproduction-strict
```

## Criterio de salida

La validación mínima de preproducción local se considera en verde cuando:

- el smoke operativo termina sin fallos;
- `validate_workspace.ps1` sigue en verde;
- no hay desvíos de puertos o endpoints respecto del runbook.
