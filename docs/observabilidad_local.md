# Observabilidad Local

## Objetivo

Centralizar la inspección mínima operativa del stack local sin depender de herramientas externas.

## Fuentes actuales

- API `gdms-api`: logs por `docker compose logs api`
- PostgreSQL del repo: logs por `docker compose logs postgres`
- `windows-twain`: health/status por HTTP y log local expuesto en `startupLogPath`

## Snapshot operativo

Genera un snapshot consolidado en `artifacts\ops`:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\get_local_operational_snapshot.ps1
```

Incluyendo `windows-twain`:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\get_local_operational_snapshot.ps1 -IncludeScanHost
```

Salida esperada:

- `docker compose ps`
- `docker ps` resumido
- validación de configuración operativa efectiva
- validación de drift entre `.env` y runtime del contenedor `gdms-api`
- validación de riesgos operativos sobre logs de `api` y `postgres`
- validación de headroom/capacidad sobre disco host, storage documental y tamaño de base principal
- reachability de `PostgreSQL`
- payload de `GET /api/health`
- extracto de variables efectivas del contenedor `gdms-api`
- últimos logs de `api`
- últimos logs de `postgres`
- si aplica, reachability de `windows-twain`, `GET /health`, `GET /api/status` y tail del log de `windows-twain`

Artefactos generados por defecto:

- `artifacts\ops\local_operational_snapshot.txt`: dump operativo completo, pensado para diagnóstico humano
- `artifacts\ops\local_operational_snapshot.json`: resumen estructurado con `OverallStatus`, conteos y checks
- `artifacts\ops\local_operational_snapshot.md`: tabla breve para adjuntar en incidentes, handoff o CI

Overrides útiles:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\get_local_operational_snapshot.ps1 `
  -SummaryJsonPath .\artifacts\ops\custom_snapshot.json `
  -SummaryMarkdownPath .\artifacts\ops\custom_snapshot.md
```

## Uso recomendado

Ejecutar este snapshot:

- antes de una validación de preproducción local;
- después de un recovery;
- cuando falle `invoke_preproduction_smoke.ps1`;
- antes de escalar un incidente local.

## Captura automática desde el smoke

El smoke de preproducción puede dejar snapshot automáticamente cuando falla:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -CaptureSnapshotOnFailure
```

Si además querés verificar que el contenedor corriendo refleja el `.env` actual:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateRuntimeConfiguration
```

Si querés validar riesgos operativos visibles en logs:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateOperationalRisks
```

Si querés sumar chequeo preventivo de capacidad y espacio:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\invoke_preproduction_smoke.ps1 -ValidateCapacityHeadroom
```

Para usar thresholds de capacidad del perfil estricto:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\assert_capacity_headroom.ps1 -Profile preproduction-strict
```

Cada corrida de capacidad deja además un snapshot derivado en:

- `artifacts\ops\capacity_metrics\latest.local-light.local-idle.json`
- `artifacts\ops\capacity_metrics\latest.local-light.local-idle.md`
- `artifacts\ops\capacity_metrics\latest.preproduction-strict.preproduction-smoke.json`
- `artifacts\ops\capacity_metrics\latest.preproduction-strict.preproduction-smoke.md`
- `artifacts\ops\capacity_metrics\history.jsonl`
- `artifacts\ops\capacity_metrics\trend_summary.local-light.local-idle.json`
- `artifacts\ops\capacity_metrics\trend_summary.local-light.local-idle.md`
- `artifacts\ops\capacity_metrics\trend_summary.preproduction-strict.preproduction-smoke.json`
- `artifacts\ops\capacity_metrics\trend_summary.preproduction-strict.preproduction-smoke.md`

Ese snapshot resume por perfil: thresholds activos, mediciones reales y estado de cada chequeo. Además, `history.jsonl` deja una línea por corrida con mediciones, `Scenario` y conteo de `OK/WARN/FAIL` para poder construir tendencia después.

Si querés validar explícitamente la tendencia de capacidad:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\assert_capacity_trend.ps1 -Profile preproduction-strict
```

La tendencia de capacidad ahora usa baseline móvil con `p50`, `p95` y promedio. El threshold efectivo se calcula sobre `p95 + margen` para métricas de crecimiento (`PostgresDatabaseSizeMb`, `DocumentStorageSizeMb`) y `p95 - margen` para métricas de espacio libre (`HostDriveFreeGb`, `DocumentStorageDriveFreeGb`).

Cada summary de tendencia deja además `BaselineSource`, `SelectedRunCount`, `ScenarioRunCount` y `ProfileRunCount`, para distinguir si la corrida ya evaluó:

- solo muestras del mismo `Profile + Scenario` (`scenario-tagged-only`);
- una baseline transitoria mezclando muestras etiquetadas del escenario con histórico legacy sin `Scenario` (`scenario-tagged-plus-legacy`);
- o solo histórico legacy del mismo perfil (`profile-legacy-only`).

Con eso se puede ver rápido si el gate está realmente apoyado en suficiente muestra del escenario activo o si todavía está bootstrapeando sobre el historial más general del perfil.

En `preproduction-strict`, la validación de capacidad quedó endurecida respecto de `local-light`:

- headroom absoluto más exigente sobre drive host y tamaños de PostgreSQL/storage;
- márgenes de tendencia más cortos (`1 GB` para espacio libre y `32 MB` para crecimiento), para detectar antes una degradación sostenida en `preproduction-smoke`.

También soporta `Scenario` para no mezclar muestras de laboratorio liviano con corridas más cargadas. Estado actual:

- `local-idle`: baseline liviana por defecto;
- `preproduction-smoke`: baseline pensada para smoke estricto y validación operativa más pesada.

Si querés validar también que los drills de recovery no se degradaron respecto del historial reciente:

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\ops\assert_recovery_drill_thresholds.ps1
```

El modo actual usa baseline móvil por tipo de drill: toma las últimas corridas exitosas del historial y compara la más reciente contra `p95 previo + margen`. El detalle operativo muestra además `p50` como referencia de latencia típica y el promedio como referencia secundaria. Si todavía no hay suficiente muestra, cae al threshold fijo inicial.

Al `2026-04-09`, los seis chequeos de recovery ya operan efectivamente en `rolling`:

- `temp_restore_validation`: `RTO`, `ValidationExecutionMs` y `RPO`.
- `stack_reprovision`: `RTO`, `ValidationExecutionMs` y `RPO`.

Además, el historial de recovery ya persiste `RpoObservedMs` usando el `createdAtUtc` del bundle restaurado, manteniendo compatibilidad hacia atrás con corridas viejas que todavía no tenían ese campo.

Cada corrida del assert deja además un snapshot derivado en:

- `artifacts\ops\recovery_metrics\threshold_summary.json`
- `artifacts\ops\recovery_metrics\threshold_summary.md`
- `artifacts\ops\recovery_metrics\threshold_summary.local-light.json`
- `artifacts\ops\recovery_metrics\threshold_summary.local-light.md`
- `artifacts\ops\recovery_metrics\threshold_summary.preproduction-strict.json`
- `artifacts\ops\recovery_metrics\threshold_summary.preproduction-strict.md`
- `artifacts\ops\recovery_metrics\threshold_summary.<profile>.<scenario>.json`
- `artifacts\ops\recovery_metrics\threshold_summary.<profile>.<scenario>.md`

Ese snapshot resume por drill y métrica: perfil activo, valor observado, `p50`, `p95`, promedio, margen, threshold efectivo y modo (`fixed` o `rolling`).

Desde `2026-04-10`, el summary de recovery ya deja también trazabilidad de baseline por drill:

- `BaselineSource`
- `SelectedRunCount`
- `ScenarioRunCount`
- `ProfileRunCount`
- `LegacyRunCount`

Desde esta misma baseline, recovery ya puede separarse también por escenario operativo. En particular:

- `preproduction-strict + preproduction-smoke` ya deja artefactos propios;
- si todavía no hay suficiente muestra del escenario pedido, el assert cae con compatibilidad hacia atrás a baseline por perfil o legacy.
- el artefacto actual para ese caso ya queda en `artifacts\ops\recovery_metrics\threshold_summary.preproduction-strict.preproduction-smoke.json` y `.md`.

El assert ahora prefiere corridas del mismo `MetricsProfile` cuando existen. Mientras el historial viejo se migra de forma natural:

- si no hay muestras etiquetadas para el perfil pedido, cae al historial legacy sin `MetricsProfile`;
- si ya hay muestras etiquetadas pero todavía no alcanzan para una baseline propia útil, arma una baseline transitoria mezclando `tagged + legacy`;
- cuando ya hay muestra suficiente del perfil, usa solo corridas etiquetadas de ese perfil.

Para recovery, "muestra suficiente" no significa solo tener dos corridas etiquetadas. Como el threshold se calcula sobre la ventana previa y excluye la corrida más reciente, el modo puro `scenario-tagged-only` o `profile-tagged-only` recién se activa con `3` corridas etiquetadas, para no terminar calculando la baseline móvil sobre una única muestra histórica.

Estado actual al `2026-04-10`: `preproduction-strict + preproduction-smoke` ya alcanzó esas `3` corridas etiquetadas y el artefacto `threshold_summary.preproduction-strict.preproduction-smoke.*` ya queda en `BaselineSource=scenario-tagged-only`.

Estado actual al `2026-04-10`:

- `local-light` opera sobre la baseline histórica principal del repo;
- `preproduction-strict` ya opera con baseline etiquetada propia para ambos drills principales, sin depender del bootstrap mixto;
- ese perfil ya usa thresholds y márgenes más exigentes que `local-light`.
- la validación de capacidad también quedó separada por perfil: `local-light` para laboratorio y `preproduction-strict` para headroom preventivo más duro.

## Relación con otros runbooks

- smoke operativo: [runbook_preproduccion_local.md](C:\IA\codex\docs\runbook_preproduccion_local.md)
- recovery local: [runbook_recovery_local.md](C:\IA\codex\docs\runbook_recovery_local.md)

## Riesgo residual conocido

En el perfil local actual puede seguir apareciendo una advertencia `WARN` sobre Data Protection sin cifrado en reposo del host. No rompe el smoke ni el runtime, pero debe tratarse como riesgo residual aceptado de laboratorio local, no como baseline objetivo para un entorno realmente productivo.
