# Plan de desarrollo para sesiones grandes

Fecha de actualización: `2026-04-28`

## 1. Objetivo

Definir cómo ejecutar sesiones de desarrollo grandes sin degradar el estándar de calidad actual del repositorio y llevando la cobertura de pruebas a un estado verificable y sostenible.

Este plan complementa:

- `C:\IA\codex\wiki.md`
- `C:\IA\codex\rf.md`
- `C:\IA\codex\rnf.md`
- `C:\IA\codex\contexto_handoff.md`

## 2. Línea base verificada

Al `2026-04-06` se validó correctamente:

- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado confirmado:

- control de archivos `.cs` y `.dart` por debajo de `300` líneas;
- `dotnet build` en `server\Gdms.sln`;
- `dotnet test` en backend;
- `flutter analyze` y `flutter test` en app y `18` targets Flutter;
- workspace completo en verde.

## 3. Estado actual del estándar de calidad

### Fortalezas ya presentes

- `Clean Architecture` en backend y frontend.
- gate unificado de workspace.
- límite estructural de `300` líneas por clase/archivo relevante.
- cobertura funcional fuerte en `client\apps\gdms_app`.
- smoke tests en packages Flutter.
- documentación viva de roadmap y handoff.

### Gaps que bloquean sesiones grandes sostenibles

- backend ya tiene suites `architecture`, `unit`, `integration`, `contract` y `e2e-smoke`.
- varios packages Flutter dependen demasiado de smoke tests.
- `database` todavía no tiene pruebas de integración equivalentes a migrations verificadas contra motor real.
- el umbral de coverage backend sigue siendo una línea base baja y debe escalar por fases.

### Avance ya implementado en Fase 0

Al `2026-04-06` quedó incorporado:

- recolección automática de coverage en CI;
- artefacto de coverage publicado por pipeline;
- resumen de coverage en `artifacts\coverage\summary.md`;
- umbral inicial de backend en CI para evitar regresión por debajo de la línea base actual;
- `windows-twain` agregado al gate de workspace mediante build;
- validación automatizada mínima para `database/scripts`;
- límite de `300` líneas extendido a `windows-twain`.
- suite `server/tests/Gdms.UnitTests` agregada a la solución con cobertura inicial en `Auth`, `OrganizationService` y `Document`.
- suite `server/tests/Gdms.IntegrationTests` agregada a la solución con base real para PostgreSQL sobre base efímera.
- suite `server/tests/Gdms.ApiContractTests` agregada a la solución con host HTTP real, auth de prueba y PostgreSQL efímero.
- suite `server/tests/Gdms.E2eSmokeTests` agregada a la solución con host HTTP real, JWT real y PostgreSQL efímero.

Baseline medida en esta etapa:

- backend total inicial: `5.49%`;
- Flutter total: `38.88%`;
- `client/apps/gdms_app`: `43.56%`.

Medición backend posterior a la incorporación de `Gdms.UnitTests`:

- backend total actualizado: `8.92%`;
- threshold mínimo de CI ajustado a `8.5%`.

Medición backend consolidada luego de corregir la agregación de coverage y ampliar `integration tests`:

- backend total consolidado: `40.44%`;
- threshold mínimo de CI ajustado a `39.0%`.

Medición backend consolidada luego de ampliar `Gdms.ApiContractTests` sobre mutaciones críticas de `DocumentsController`, `SignaturesController` y `RecordsController`:

- backend total consolidado: `43.29%`;
- threshold mínimo de CI ajustado a `42.0%`.

Medición backend consolidada luego de incorporar `e2e-smoke` cross-system de escaneo con `windows-twain` headless:

- backend total consolidado: `55.95%`;
- threshold mínimo de CI ajustado a `54.0%`.

Medición backend consolidada luego de cerrar la primera pasada de `Gdms.ApiContractTests` sobre todos los controladores API:

- backend total consolidado: `87.82%`;
- threshold mínimo de CI ajustado a `80.0%`.

Medición Flutter consolidada luego de endurecer `feature_documents`, `feature_records`, `feature_signature`, `feature_workflow`, `feature_notifications` y `feature_admin`:

- Flutter total consolidado: `46.8%`;
- `client/packages/feature_documents`: `87.18%`;
- `client/packages/feature_records`: `95.3%`;
- `client/packages/feature_signature`: `98.79%`;
- `client/packages/feature_workflow`: `99.35%`;
- `client/packages/feature_notifications`: `98.69%`;
- `client/packages/feature_admin`: `98.45%`;
- `client/packages/feature_reports`: `37.21%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_search`: `28.43%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_auth`: `11.86%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_config`: `12.99%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_integrations`: `22.22%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_sector_corporate`: `11.98%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_sector_legal`: `11.98%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- `client/packages/feature_sector_real_estate`: `11.98%` antes de la segunda pasada y pendiente de re-medición consolidada tras endurecer tests reales;
- threshold mínimo de CI ajustado a `45.0%` para Flutter total.

Medición Flutter consolidada luego de cerrar la segunda pasada sobre packages transversales y verticales sectoriales:

- Flutter total consolidado: `53.48%`;
- `client/apps/gdms_app`: `43.8%`;
- `client/packages/core`: `92.86%`;
- `client/packages/design_system`: `67.44%`;
- `client/packages/feature_auth`: `94.92%`;
- `client/packages/feature_config`: `100%`;
- `client/packages/feature_documents`: `87.18%`;
- `client/packages/feature_integrations`: `100%`;
- `client/packages/feature_notifications`: `98.69%`;
- `client/packages/feature_records`: `95.3%`;
- `client/packages/feature_reports`: `98.45%`;
- `client/packages/feature_search`: `94.12%`;
- `client/packages/feature_signature`: `98.79%`;
- `client/packages/feature_sector_corporate`: `100%`;
- `client/packages/feature_sector_legal`: `100%`;
- `client/packages/feature_sector_real_estate`: `100%`;
- `client/packages/feature_admin`: `98.45%`;
- `client/packages/feature_audit`: `24.26%`;
- `client/packages/feature_workflow`: `99.35%`;
- threshold mínimo de CI ajustado a `52.0%` para Flutter total.

Medición Flutter consolidada luego de cerrar también `feature_audit`:

- Flutter total consolidado: `54.58%`;
- `client/packages/feature_audit`: pendiente de nueva lectura detallada por target, pero ya impactando positivamente en el consolidado total;
- threshold mínimo de CI ajustado a `54.0%` para Flutter total.

Estado actual de integración backend:

- `Gdms.IntegrationTests` corre contra PostgreSQL real cuando existe `GDMS_TEST_POSTGRES_CONNECTION`;
- cada corrida crea una base efímera, aplica `database/scripts` y destruye la base al finalizar;
- el gate principal no lo exige todavía en todos los entornos, pero `validate_workspace.ps1` ya lo ejecuta automáticamente cuando la variable está disponible.
- la suite ya cubre persistencia real de `Organización`, `User`, `Documents`, `DocumentMetadata` y `Auth`;
- la suite ya cubre también `Records` con políticas de retención, legal holds y candidatos de disposición;
- la suite ya cubre también `Workflow` y `Signature` con persistencia real, auditoría y transiciones principales de estado;
- la suite ya cubre también `Reports` con agregación operacional scoped a organización y resumen de plataforma;
- la suite `Gdms.ApiContractTests` ya cubre `ReportsController` con contratos HTTP `401`, `403` y `200`;
- la suite `Gdms.ApiContractTests` ya cubre también `RecordsController` sobre `disposition-candidates`, aplicación de retención y ciclo de `legal hold` con contratos HTTP `401`, `403`, `200`, `201` y `204`;
- la suite `Gdms.ApiContractTests` ya cubre también `DocumentsController` sobre lectura, ACL y creación con contratos HTTP `401`, `403`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `DocumentContentController` sobre upload multipart, nueva versión, download y `Range`, incluyendo `401`, `403`, `200`, `201` y `206`;
- la suite `Gdms.ApiContractTests` ya cubre también `DocumentAccessController` sobre listado y grant de ACL documental, incluyendo `401`, `403`, `400`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `DocumentMetadataController` sobre lectura y reemplazo de metadatos, incluyendo `401`, `403`, `400`, `200` y validación contra ACL de `EditMetadata`;
- la suite `Gdms.ApiContractTests` ya cubre también `DocumentTypesController` sobre catálogo scoped a organización de tipos documentales, incluyendo `401`, `403` y payload autorizado con validación de seeds y schema JSON;
- la suite `Gdms.ApiContractTests` ya cubre también `NotificationsController` sobre inbox scoped a organización, incluyendo `401`, `403` y agregación real de `workflow`, `signature`, `records` y `security`;
- la suite `Gdms.ApiContractTests` ya cubre también `IntegrationsController` sobre discovery scoped a organización de integraciones configuradas, incluyendo `401`, `403` y validación del catálogo efectivo expuesto por infraestructura;
- la suite `Gdms.ApiContractTests` ya cubre también `HealthController` sobre payload público de healthcheck, validando `200`, `Status`, ventana temporal UTC y ruta de documentación;
- la suite `Gdms.ApiContractTests` ya cubre también `CaseFilesController` sobre listado, documentos vinculados, creación y attach documental, incluyendo `401`, `403`, `200`, `201` y `204`;
- la suite `Gdms.ApiContractTests` ya cubre también `PropertyFilesController` sobre listado, documentos vinculados, creación y attach documental, incluyendo `401`, `403`, `200`, `201` y `204`;
- la suite `Gdms.ApiContractTests` ya cubre también `CorporateRecordFilesController` sobre listado, documentos vinculados, creación y attach documental, incluyendo `401`, `403`, `200`, `201` y `204`;
- la suite `Gdms.ApiContractTests` ya cubre también `EvidencePackagesController` sobre export de evidencia documental en JSON descargable, incluyendo `401`, `403`, validación de documento inexistente y verificación de auditoría persistida tras exportar;
- la suite `Gdms.ApiContractTests` ya cubre también `AuditController` sobre vistas recientes de plataforma, organización y documento, incluyendo `401`, `403`, normalización de `limit` y validación de documento inexistente;
- la suite `Gdms.ApiContractTests` ya cubre también `UsersController` sobre listado, detalle, creación y asignación de roles, incluyendo `401`, `403`, `400`, `404`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `OrganizacionesController` sobre listado y creación, incluyendo bootstrap inicial sin `PLATFORM_ADMIN`, protección posterior por rol y contratos `401`, `403`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `RolesController` sobre discovery de roles asignables, incluyendo `401` y listado autenticado exitoso;
- la suite `Gdms.ApiContractTests` ya cubre también `AuthController` sobre bootstrap de `PLATFORM_ADMIN`, bootstrap de `ORGANIZATION_ADMIN`, login local y `me`, incluyendo `201`, `200`, `400`, `401` y mapeo explícito de claims requeridos;
- la suite `Gdms.ApiContractTests` ya cubre también `SignaturesController` sobre listado, creación, completado y cancelación con contratos HTTP `401`, `403`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `WorkflowController` sobre listado, creación y completado con contratos HTTP `401`, `403`, `200` y `201`;
- la suite `Gdms.E2eSmokeTests` ya cubre un flujo cross-system real con `bootstrap/login` JWT, upload multipart, metadata, workflow, signature y reporte operacional;
- la suite `Gdms.E2eSmokeTests` ya cubre también un flujo cross-system de binarios con upload inicial, nueva versión y descarga;
- la suite `Gdms.E2eSmokeTests` ya cubre también ACL multiusuario con bootstrap real, alta de usuario, transición de acceso implícito a ACL explícita y descarga controlada;
- la suite `Gdms.E2eSmokeTests` ya cubre también `scan -> export pdf local -> upload backend` usando `windows-twain` headless con sesión rehidratada y JWT real;
- la suite `Gdms.E2eSmokeTests` ya cubre también edición de sesión local rehidratada sobre `windows-twain` con `preview`, `merge`, `move`, `delete` y upload final al backend;
- la suite `Gdms.E2eSmokeTests` ya cubre también recovery del host local `windows-twain` con reinicio, rehidratación de sesión mutada y upload posterior al backend;
- la suite `Gdms.E2eSmokeTests` ya cubre también caída real del host local durante una sesión visible, fallo de acceso mientras está abajo y retry exitoso tras reinicio con exportación/upload posterior;
- la suite `Gdms.E2eSmokeTests` ya cubre también el contrato `browser -> localhost` de `windows-twain`, validando CORS loopback permitido y origen externo rechazado;
- la suite `Gdms.E2eSmokeTests` ya cubre también preflight `OPTIONS` de navegador sobre endpoints de escaneo, verificando headers CORS esperados para origen loopback;
- la suite `Gdms.E2eSmokeTests` ya cubre también configuración explícita de CORS en `windows-twain`, validando origen externo permitido y loopback rechazado cuando `AllowLoopbackOrigins=false`;
- la suite `Gdms.E2eSmokeTests` ya cubre también preflight `OPTIONS` para origen explícito configurado en `windows-twain`, completando el contrato browser/localhost sin depender de loopback abierto;
- la suite `Gdms.E2eSmokeTests` ya cubre también descarga PDF con `Range`, validando el contrato esperado por visores inline de navegador sobre `windows-twain`;
- la suite `Gdms.E2eSmokeTests` ya cubre también abort temprano del request de escaneo, propagando `RequestAborted` hasta `windows-twain` sin dejar el host local degradado;
- la suite `Gdms.E2eSmokeTests` ya cubre también abort con operación ya iniciada simulada, preservando una sesión `canceled` sin degradar el host local;
- la suite `Gdms.E2eSmokeTests` ya cubre también mantenimiento explícito del host local con `clear rehydrated sessions` y validación de vaciado operativo del estado persistido;
- la suite `Gdms.E2eSmokeTests` ya cubre también cleanup de artefactos huérfanos envejecidos sin afectar sesiones activas del host local;
- `client/apps/gdms_app` ya cubre recuperación del cliente ante host local caído y restablecido, recomponiendo estado de scanners, sesiones y mensaje operativo;
- `client/apps/gdms_app` ya cubre también sesión activa con host local caído durante `refreshSession`, preservando estado visible y reportando error de conexión;
- `client/apps/gdms_app` ya cubre también recuperación automática del estado operativo al reintentar `refreshSession` cuando el host local vuelve a responder;
- `client/apps/gdms_app` ya ofrece retry guiado desde la preview cuando la sesión sigue visible pero el host local cayó;
- `client/apps/gdms_app` ya cubre también el retry guiado desde `ScanDocumentDialog`, verificando recomposición de la sesión activa y del estado operativo al volver el host local;
- `client/packages/feature_documents` ya salió del smoke test único y ahora cubre comportamiento real de `DocumentsViewModel` y `DocumentsDashboardPage`, incluyendo búsqueda, limpieza, mensajes y callbacks operativos;
- `client/packages/feature_records` ya salió del smoke test único y ahora cubre comportamiento real de `RecordsViewModel` y `RecordsDashboardPage`, incluyendo filtros, limpieza, selección, gestión y ejecución confirmada de disposición;
- `client/packages/feature_signature` ya salió del smoke test único y ahora cubre comportamiento real de `SignatureViewModel` y `SignatureDashboardPage`, incluyendo filtros, selección, completado, cancelación con motivo y corrección del ciclo de vida del diálogo de cancelación;
- `client/packages/feature_workflow` ya salió del smoke test único y ahora cubre comportamiento real de `WorkflowViewModel` y `WorkflowDashboardPage`, incluyendo filtros, toggle de `solo mis tareas`, selección, creación y completado de tareas;
- `client/packages/feature_notifications` ya salió del smoke test único y ahora cubre comportamiento real de `NotificationsViewModel` y `NotificationsDashboardPage`, incluyendo filtros por severidad y categoría, búsqueda, limpieza y acción contextual por alerta;
- `client/packages/feature_admin` ya salió del smoke test único y ahora cubre comportamiento real de `AdminOverviewViewModel` y `AdminDashboardPage`, incluyendo carga, mensajes, acciones de header y navegación/callbacks sobre métricas, backlog, organizaciones y eventos;
- `client/packages/feature_reports` ya salió del smoke test único y ahora cubre comportamiento real de `ReportsViewModel` y `ReportsDashboardPage`, incluyendo carga, filtros por lente operativa, métricas visibles y callbacks sobre KPIs operativos y de plataforma;
- `client/packages/feature_search` ya salió del smoke test único y ahora cubre comportamiento real de `SearchViewModel` y `SearchDashboardPage`, incluyendo presets, saved searches, filtros, limpieza, ejecución de búsqueda y selección de resultados;
- `client/packages/feature_auth` ya salió del smoke test único y ahora cubre comportamiento real de `AuthOverviewViewModel` y `AuthDashboardPage`, incluyendo carga de sesión, manejo de error, badges operativos y datos del contexto autenticado;
- `client/packages/feature_config` ya salió del smoke test único y ahora cubre comportamiento real de `ConfigViewModel` y `ConfigDashboardPage`, incluyendo carga de snapshot, edición de preferencias, guardado y recomposición del estado visible;
- `client/packages/feature_integrations` ya salió del smoke test único y ahora cubre comportamiento real de `IntegrationsViewModel` y `IntegrationsDashboardPage`, incluyendo carga, filtros por texto/categoría/estado, métricas visibles, limpieza y selección de integraciones;
- `client/packages/feature_audit` ya salió del smoke test único y ahora cubre comportamiento real de `AuditOverviewViewModel` y `AuditDashboardPage`, incluyendo carga, filtros por severidad/organización/query, métricas derivadas y manejo explícito de error;
- `client/packages/feature_sector_corporate` ya salió del smoke test único y ahora cubre comportamiento real de `CorporateDashboardViewModel` y `CorporateDashboardPage`, incluyendo carga, métricas del vertical, CTA de creación y selección de legajos/alertas;
- `client/packages/feature_sector_legal` ya salió del smoke test único y ahora cubre comportamiento real de `LegalDashboardViewModel` y `LegalDashboardPage`, incluyendo carga, métricas del vertical, CTA de creación, selección de expedientes y render de asuntos jurídicos;
- `client/packages/feature_sector_real_estate` ya salió del smoke test único y ahora cubre comportamiento real de `RealEstateDashboardViewModel` y `RealEstateDashboardPage`, incluyendo carga, métricas del vertical, CTA de creación y selección de legajos/alertas inmobiliarias;
- en entornos de desarrollo con PostgreSQL local instalado, el contenedor del repo quedó expuesto en `localhost:5433` para evitar conflicto con `5432`.

## 4. Definición operativa de cobertura completa

Para este proyecto, "cobertura completa" no debe significar perseguir `100%` lineal del monorepo sin criterio. La definición operativa será:

- `100%` del código nuevo o modificado en una sesión debe salir cubierto por pruebas automáticas.
- `100%` de los flujos críticos debe tener al menos una combinación de `unit`, `integration`, `contract` o `e2e-smoke`.
- `Gdms.Domain` y `Gdms.Application` deben converger al objetivo `>= 80%` indicado en `rnf.md`.
- APIs críticas deben tener pruebas positivas, negativas y scoped a organización.
- integraciones locales y externas deben tener pruebas de contrato o dobles de prueba explícitos.

## 5. Principios para sesiones grandes

- cada sesión grande debe tocar un solo frente principal;
- no mezclar en una misma sesión cambios profundos de backend, frontend, datos e infraestructura salvo que formen un único vertical slice;
- todo cambio debe salir con pruebas en la misma sesión;
- el gate del workspace debe correr completo antes de cerrar la sesión;
- no se acepta deuda de tests "para después" en módulos críticos;
- la documentación de continuidad debe actualizarse cuando cambie un flujo relevante.

## 6. Plan por fases

## Fase 0. Endurecimiento del sistema de calidad

Objetivo:
llevar el estándar actual desde "tests en verde" a "calidad medible y exigible".

Entregables:

- coverage real en CI para `.NET` y Flutter;
- reporte unificado de coverage por módulo;
- umbrales mínimos por capa;
- extensión del gate para incluir `windows-twain`;
- validaciones automáticas iniciales para `database`.

Duración sugerida:

- `2` a `3` sesiones grandes.

## Fase 1. Cobertura profunda del core backend

Objetivo:
cerrar el riesgo principal del backend antes de seguir ampliando funcionalidad.

Prioridades:

- `Documents`
- `DocumentMetadata`
- `Records`
- `Workflow`
- `Signature`
- `Auth` e `Identity`
- `Reports`

Entregables:

- suites unitarias por servicio de aplicación;
- tests de dominio para invariantes críticas;
- contract tests para controladores clave;
- integration tests para persistencia PostgreSQL.

Duración sugerida:

- `4` a `6` sesiones grandes.

## Fase 2. Cobertura crítica del frontend modular

Objetivo:
evitar que `gdms_app` concentre toda la confianza y distribuir cobertura real en los packages.

Prioridades:

- `feature_documents`
- `feature_records`
- `feature_signature`
- `feature_workflow`
- `feature_search`
- `feature_notifications`
- `feature_admin`
- `feature_audit`

Entregables:

- tests de `view model`;
- widget tests de pantallas críticas;
- tests de repositorios y mappers;
- reducción de dependencia de smoke tests simples.

Duración sugerida:

- `3` a `5` sesiones grandes.

## Fase 3. Cobertura cross-system y escaneo

Objetivo:
cerrar el flujo completo de operación documental con escaneo real.

Entregables:

- build y test para `windows-twain`;
- pruebas del flujo `scan -> upload -> metadata -> search -> evidence/signature`;
- escenarios de recovery, host caído, timeout y mantenimiento;
- smoke tests cross-system reutilizables.

Duración sugerida:

- `2` a `4` sesiones grandes.

## Fase 4. Preproducción y cierre productivo

Objetivo:
alinear el roadmap técnico con la Fase 5 de `wiki.md`.

Entregables:

- observabilidad mínima;
- endurecimiento de secretos y configuración;
- storage y búsqueda productivos;
- smoke tests de preproducción;
- runbooks operativos.

Duración sugerida:

- continua, luego de estabilizar Fases 0 a 3.

## 7. Plantilla de ejecución por sesión

Cada sesión grande debe seguir esta secuencia:

1. delimitar el vertical slice o módulo objetivo;
2. definir matriz de pruebas antes de editar;
3. implementar primero núcleo y adaptadores directos;
4. escribir o ampliar tests del cambio;
5. ejecutar gates locales del módulo;
6. ejecutar `validate_workspace.ps1`;
7. actualizar handoff o documentación si cambió el comportamiento.

## 8. Definition of Done por sesión

Una sesión grande solo se considera cerrada si:

- el alcance comprometido quedó implementado;
- no se rompió el límite estructural del repositorio;
- el código nuevo o modificado quedó cubierto;
- el workspace quedó en verde;
- no quedó un cambio crítico sin prueba;
- la continuidad documental quedó actualizada.

## 9. Métricas que deben empezar a seguirse

- coverage por proyecto backend;
- coverage por app/package Flutter;
- cantidad de suites por tipo: `unit`, `integration`, `contract`, `e2e-smoke`;
- tiempo promedio de `validate_workspace`;
- cantidad de módulos fuera de gate;
- cantidad de flujos críticos sin smoke test.

## 10. Backlog inmediato recomendado

### Sesión 1

- instrumentar coverage en CI;
- definir umbrales iniciales por capa;
- publicar reporte de coverage por artefacto.

### Sesión 2

- ampliar `Gdms.IntegrationTests` sobre `Documents`, `Auth` y repositorios críticos;
- ampliar cobertura de `Documents`, `DocumentMetadata` y `Auth` sobre la base de `Gdms.UnitTests`.

Estado al cierre de esta sesión:

- `Documents`, `DocumentMetadata` y `Auth` ya tienen cobertura de integración real sobre PostgreSQL;
- `Records` ya tiene cobertura de integración real sobre PostgreSQL;
- `Workflow` y `Signature` ya tienen cobertura de integración real sobre PostgreSQL;
- `Reports` ya tiene cobertura de integración real sobre PostgreSQL;
- `ReportsController` ya tiene pruebas de contrato de API;
- `RecordsController` ya tiene pruebas de contrato de API;
- `DocumentsController` ya tiene pruebas de contrato de API;
- `SignaturesController` ya tiene pruebas de contrato de API;
- la siguiente ampliación backend debería ir sobre mutaciones críticas adicionales o cierre de coverage backend;
- la agregación de coverage backend ya mide de forma consolidada todas las suites `.NET`, habilitando thresholds más exigentes en CI.

### Sesión 3

- ampliar cobertura real en `feature_documents`, `feature_records` y `feature_workflow`;
- dejar `gdms_app` enfocado en integración.

### Sesión 4

- incluir `windows-twain` en el gate principal;
- definir validación automatizada mínima para `database`.

### Sesión 5

- cerrar el primer smoke cross-system completo de escaneo a documento operativo.

## 11. Criterio de prioridad actual

La siguiente prioridad correcta es seguir profundizando `Fase 4` sobre drills operativos e incident response, manteniendo pisos de CI en `80%` backend y `54%` Flutter total.

Avance inicial de `Fase 4` ya abierto:

- smoke operativo local en `scripts\ops\invoke_preproduction_smoke.ps1`;
- runbook base en `docs\runbook_preproduccion_local.md`;
- runbook de recovery local en `docs\runbook_recovery_local.md`;
- validación opcional de `windows-twain` integrada al smoke mediante `-IncludeScanHost`;
- snapshot operativo local en `scripts\ops\get_local_operational_snapshot.ps1`;
- guía de observabilidad mínima en `docs\observabilidad_local.md`;
- corrección del puerto operativo documentado de PostgreSQL del stack local a `5433`;
- backup local reproducible de PostgreSQL y storage documental en `scripts\ops\backup_local_stack.ps1`;
- restore mínimo verificable en base temporal y storage temporal en `scripts\ops\restore_local_stack.ps1`;
- runbook específico de backup/restore en `docs\runbook_backup_restore_local.md`;
- validación operativa de configuración y secretos mínimos en `scripts\ops\assert_operational_configuration.ps1`, con modo estricto para detectar defaults inseguros antes de preproducción;
- perfil local de preproducción estricta en `.env.preproduction.example` y `scripts\ops\use_preproduction_profile.ps1` para conmutar el stack a settings menos permisivos sin editar archivos versionados;
- snapshot operativo ampliado con drift check entre `.env` y runtime del contenedor API, más reachability y extractos de configuración efectiva;
- stack local reprovisionado y verificado en perfil estricto, con `invoke_preproduction_smoke.ps1 -ValidateConfiguration -StrictConfiguration -ValidateRuntimeConfiguration` en verde;
- validación de riesgos operativos sobre logs en `scripts\ops\assert_operational_risks.ps1`, integrada al snapshot y al smoke de preproducción.
- verificación integrada de `backup -> restore temporal -> smoke posterior` en `scripts\ops\verify_local_backup_restore.ps1` para dejar evidencia repetible de recuperabilidad local.
- runtime, riesgos operativos y smoke estricto de preproducción ya quedaron en verde sobre el stack local alineado con el `.env` activo.
- validación preventiva de capacidad/headroom en `scripts\ops\assert_capacity_headroom.ps1`, integrada al snapshot y opcionalmente al smoke operativo.
- drill automatizado de reprovisión completa desde backup en `scripts\ops\reprovision_stack_from_backup.ps1`.
- reprovisión completa desde backup ya validada en verde sobre el stack local, con un riesgo residual visible: Data Protection persiste sin cifrado en reposo del host.
- chequeo de integridad de negocio post-restore en `scripts\ops\assert_restore_business_integrity.ps1`, integrable tanto en restore temporal como en reprovisión completa.
- fixture documental determinístico para drills de recovery en `scripts\ops\seed_restore_business_fixture.ps1`, usable para validar hash, tamaño y metadata tras restore.
- el fixture de recovery ya cubre dos versiones documentales y ACL explícita restauradas junto con el binario.
- el fixture de recovery ya cubre además una tarea de `workflow` completada y un `signature envelope` firmado, ambos restaurados y verificados post-restore.
- el fixture de recovery ya cubre además un `legal hold` activo y un evento de `audit` documental, ambos restaurados y verificados post-restore.
- el fixture de recovery ya deja un usuario autenticable de la organización para validar `evidence package` por HTTP real contra la API local restaurada.
- `verify_local_backup_restore.ps1 -RunSmokeAfterRestore -RunBusinessIntegrityChecks -EnsureBusinessFixture` ya quedó estable y validado en verde con ese fixture enriquecido.
- `reprovision_stack_from_backup.ps1 -CreateFreshBackup -RunSmokeAfterRestore -RunBusinessIntegrityChecks -EnsureBusinessFixture` ya quedó validado en verde sobre el stack principal con restore completo del fixture.
- `scripts\ops\assert_evidence_package_export.ps1` ya valida por HTTP el `evidence package` del fixture y `reprovision_stack_from_backup.ps1 -RunEvidencePackageChecks` ya quedó en verde.
- `scripts\ops\invoke_temp_restore_evidence_validation.ps1` ya levanta una API efímera contra la base/storage temporales restaurados y `verify_local_backup_restore.ps1 -RunEvidencePackageChecks` ya quedó en verde sin depender del stack principal.
- el harness temporal de evidencia quedó estabilizado resolviendo la password PostgreSQL desde el runtime activo y evitando colisiones por puerto fijo con asignación dinámica de `ApiBaseUrl`.
- primera métrica real del drill temporal completo: `TotalDrillDurationMs=20964`, con `EvidencePackageDurationMs=6160`, `BusinessIntegrityDurationMs=2262` y `SmokeDurationMs=9322`.
- los drills `verify_local_backup_restore.ps1` y `reprovision_stack_from_backup.ps1` ya persisten métricas comparables en `artifacts\ops\recovery_metrics\history.jsonl`, `latest.json` y `latest.md`.
- baseline observada al `2026-04-09`:
  - `temp_restore_validation`: `RecoveryExecutionMs=1340`, `ValidationExecutionMs=17726`, `RtoObservedMs=19066`, `TotalDrillDurationMs=20937`;
  - `stack_reprovision`: `RecoveryExecutionMs=7806`, `ValidationExecutionMs=12937`, `RtoObservedMs=20743`, `TotalDrillDurationMs=24321`.
- thresholds operativos iniciales ya formalizados en `scripts\ops\assert_recovery_drill_thresholds.ps1`:
  - `temp_restore_validation`: `RtoObservedMs <= 22000` y `ValidationExecutionMs <= 19000`;
  - `stack_reprovision`: `RtoObservedMs <= 24000` y `ValidationExecutionMs <= 14000`.
- `invoke_preproduction_smoke.ps1` ya puede exigir esos thresholds con `-ValidateRecoveryDrillThresholds`.
- el assert de recovery ya soporta baseline móvil por historial: usa las últimas corridas exitosas del mismo drill y compara la más reciente contra `p95 previo + margen`, dejando además visibles `p50` como referencia de latencia típica y el promedio como referencia secundaria, con fallback al threshold fijo cuando todavía no hay suficiente muestra.
- al `2026-04-09` ya hay al menos 2 corridas exitosas por tipo de drill, por lo que `assert_recovery_drill_thresholds.ps1` ya está operando efectivamente en modo `rolling`.
- baseline móvil actual luego de sumar segunda muestra completa con `RPO` por tipo:
  - `temp_restore_validation`: último `RtoObservedMs=20512`, `ValidationExecutionMs=19161`, `RpoObservedMs=20623`; `RTO`, `ValidationExecutionMs` y `RPO` ya operan en `rolling`.
  - `stack_reprovision`: último `RtoObservedMs=20749`, `ValidationExecutionMs=13183`, `RpoObservedMs=21476`; `RTO`, `ValidationExecutionMs` y `RPO` ya operan en `rolling`.
- restricción operativa: `temp_restore_validation` y `stack_reprovision` no deben correrse en paralelo porque comparten stack Docker, PostgreSQL y fixture de recovery.
- `write_recovery_drill_metrics.ps1` ya persiste también `RpoObservedMs` a partir de `manifest.createdAtUtc` del bundle restaurado.
- `assert_recovery_drill_thresholds.ps1` ya persiste además un snapshot derivado en `artifacts\ops\recovery_metrics\threshold_summary.json` y `threshold_summary.md`, más variantes dedicadas por perfil (`threshold_summary.local-light.*` y `threshold_summary.preproduction-strict.*`), con `observed`, `p50`, `p95`, promedio, margen, threshold efectivo y modo por drill/métrica.
- ese summary de recovery ya expone además `BaselineSource`, `SelectedRunCount`, `ProfileRunCount` y `LegacyRunCount`, dejando la baseline de recovery tan trazable como la de capacidad.
- desde esta sesión, recovery ya soporta también separación por `Scenario`, con artefactos derivados `threshold_summary.<profile>.<scenario>.*` y fallback compatible cuando todavía no hay suficiente muestra etiquetada del escenario.
- la baseline etiquetada de recovery para `preproduction-strict + preproduction-smoke` ya quedó poblada y validada con varias corridas reales; desde esta sesión el assert ya opera en modo puro `scenario-tagged-only`, apoyado por `3` corridas etiquetadas del escenario.
- durante esta sesión se corrigió precisamente esa transición en `assert_recovery_drill_thresholds.ps1`: el modo `scenario-tagged-only` y `profile-tagged-only` ya no se activan con `2` corridas, sino con `3`, evitando falsos rojos por endurecimiento prematuro del baseline.
- el gate de recovery ya soporta perfiles explícitos:
  - `local-light` como baseline actual del repo;
  - `preproduction-strict` con thresholds y márgenes más exigentes para una validación operativa más dura.
- al `2026-04-10`, ambos perfiles (`local-light` y `preproduction-strict`) ya fueron validados en verde contra el historial real disponible.
- desde `2026-04-10`, `write_recovery_drill_metrics.ps1` ya persiste `MetricsProfile` y `assert_recovery_drill_thresholds.ps1` ya prefiere muestras del perfil pedido cuando existen, con bootstrap transitorio `tagged + legacy` y fallback compatible al historial legacy no etiquetado mientras el perfil nuevo junta baseline propia.
- después de poblar dos muestras reales por drill en `preproduction-strict`, ese perfil ya puede operar con baseline etiquetada propia sobre `temp_restore_validation` y `stack_reprovision`.
- al cierre de esta sesión, `preproduction-strict` ya quedó endurecido con thresholds y márgenes más exigentes que `local-light`, aprovechando esa baseline etiquetada propia.
- al cierre de esta sesión, `assert_capacity_headroom.ps1` también quedó separado por perfil (`local-light` y `preproduction-strict`), para no compartir el mismo gate preventivo de espacio/capacidad entre laboratorio y validación más exigente.
- al cierre de esta sesión, `assert_capacity_headroom.ps1` ya persiste también evidencia derivada por perfil en `artifacts\ops\capacity_metrics`, con thresholds, mediciones y estado de checks.
- al cierre de esta sesión, `assert_capacity_headroom.ps1` ya persiste también historial incremental en `artifacts\ops\capacity_metrics\history.jsonl`, dejando base para tendencia preventiva por perfil.
- al cierre de esta sesión, `assert_capacity_trend.ps1` ya valida degradación sostenida de headroom por perfil usando `capacity_metrics\history.jsonl`, con fallback implícito cuando todavía no hay suficiente muestra.
- al cierre de esta sesión, `assert_capacity_trend.ps1` ya expone también `p50`, `p95` y promedio por métrica, alineando el gate de capacidad con el criterio móvil usado en recovery.
- al cierre de esta sesión, los scripts de capacidad ya soportan además `Scenario`, para no mezclar en el historial corridas `local-idle` con corridas `preproduction-smoke`.
- al cierre de esta sesión, los artefactos derivados de capacidad (`latest.*` y `trend_summary.*`) ya quedaron separados por `Profile + Scenario`, evitando colisiones entre escenarios del mismo perfil.
- al cierre de esta sesión, `assert_capacity_trend.ps1` ya persiste también `BaselineSource` en sus artefactos derivados, para dejar explícito si el baseline usado fue `scenario-tagged-only`, mixto con legacy o puramente legacy.
- al cierre de esta sesión, `assert_capacity_trend.ps1` ya persiste también `SelectedRunCount`, `ScenarioRunCount` y `ProfileRunCount`, para mostrar cuánta muestra real sostiene cada baseline por escenario.
- al cierre de esta sesión, `preproduction-strict` quedó endurecido también en capacidad: thresholds absolutos más bajos y márgenes de tendencia más cortos, aprovechando que `preproduction-smoke` ya opera con baseline `scenario-tagged-only`.
- al cierre de esta sesión, `invoke_preproduction_smoke.ps1` ya quedó orientado por default a `preproduction-strict` / `preproduction-smoke`, evitando depender de overrides explícitos para la corrida operativa dura.
- al cierre de esta sesión, `scripts\ops\run_preproduction_strict_smoke.ps1` ya quedó como entrypoint corto para el smoke estricto de preproducción local.
- al cierre de esta sesión, `scripts\ops\refresh_preproduction_strict_baseline.ps1` ya quedó como helper serial para refrescar baseline estricta de recovery y capacidad sin correr drills incompatibles en paralelo.
- al cierre de esta sesión, `stack_reprovision` ya quedó desacoplado del rebuild forzado de imagen Docker durante el drill, evitando contaminar `RTO`/`RPO` con tiempo de build del API.
- al cierre de esta sesión, luego de refrescar dos muestras limpias adicionales, `preproduction-strict` volvió a endurecerse con márgenes móviles de recovery más cortos sobre `RTO`, `ValidationExecutionMs` y `RPO`.
- al cierre de esta sesión, el workflow de CI ya soporta un job opt-in `preproduction-strict-smoke`, activable con `GDMS_ENABLE_PREPRODUCTION_SMOKE=true` en runners con Docker disponible.
- al cierre de esta sesión, ese job ya publica también snapshot operativo y artefactos de `capacity_metrics` / `recovery_metrics`, dejando evidencia útil de la corrida en CI.
- al cierre de esta sesión, la retención de artifacts en CI ya quedó acotada: `14` días para coverage y `7` días para evidencia operativa del smoke estricto.
- al cierre de esta sesión, el job estricto ya separa artifacts de éxito y de fallo, publicando evidencia mínima en verde y el paquete completo solo cuando la corrida falla.
- baseline actual con `RPO observed` ya absorbida por baseline móvil:
  - `temp_restore_validation`: promedio previo `RpoObservedMs=19249`, último `20623`, threshold efectivo `25000`;
  - `stack_reprovision`: promedio previo `RpoObservedMs=21206`, último `21476`, threshold efectivo `26000`.
- compatibilidad hacia atrás: el assert de recovery ignora corridas históricas que todavía no tenían `RpoObservedMs`, evitando romper el baseline existente.
- baseline estricta refrescada y validada nuevamente al `2026-04-10` con muestra limpia:
  - `temp_restore_validation`: `RTO=19275 ms`, `ValidationExecutionMs=17937 ms`, `RPO=19386 ms`, threshold efectivo `20188/18870/22000`;
  - `stack_reprovision`: `RTO=19219 ms`, `ValidationExecutionMs=13012 ms`, `RPO=19903 ms`, threshold efectivo `21408/13839/22107`.
- baseline estricta ampliada al `2026-04-10` con una muestra limpia adicional por drill:
  - `temp_restore_validation`: último `RTO=19096 ms`, `ValidationExecutionMs=17785 ms`, `RPO=19214 ms`;
  - `stack_reprovision`: último `RTO=19250 ms`, `ValidationExecutionMs=12885 ms`, `RPO=19930 ms`.
- el siguiente paso operativo sobre esta base ya no es más tooling nuevo, sino refrescar periódicamente `preproduction-strict` con corridas seriales reales para que la baseline etiquetada siga representando el estado actual del stack.

Siguiente corte recomendado:

- seguir endureciendo el perfil `preproduction-strict` con thresholds preventivos más cercanos a una preproducción cargada real;
- o poblar baseline propia del escenario `preproduction-smoke` con varias corridas reales, hasta que el `BaselineSource` quede estable en `scenario-tagged-only`.

## 12. Plan de simplificación instancia única y módulo de digitalización

Objetivo:
quitar la opción múltiples organizaciones del GDMS, alinear toda la documentación al nuevo modelo de instancia única y planificar la incorporación del flujo de digitalización física descrito en `requisitos_sgd_antiguo.md`.

Decisiones base:

- GDMS deja de ofrecer modalidad múltiples organizaciones y se orienta a una única organización por instalación.
- El aislamiento por `organization` deja de ser una capacidad de producto y debe reemplazarse en documentación por organización, instancia, proyecto, área o perfil, según corresponda.
- El nuevo flujo de digitalización se implementará como módulo independiente `digitization`, integrado con `documents`, `workflow`, `audit`, `records`, `search`, `signature`, `notifications`, `config`, `integrations` y `windows-twain`.
- En esta versión no habrá integración automática con depósitos externos como Iron Mountain.
- El visualizador externo será el mismo cliente GDMS con permisos externos, no una aplicación separada.
- Los manifiestos oficiales de organismos quedan como formato pendiente, por lo que el diseño inicial debe admitir importadores configurables y carga manual controlada.
- Las etiquetas usarán inicialmente numeración autoincremental para contenedores y documentos.
- Las imágenes escaneadas se preservarán como páginas individuales durante la operación y se convertirán a PDF/A al finalizar; si el proyecto tiene OCR, el PDF/A final debe incluir OCR.
- La eliminación de blancos se apoyará primero en configuración del escáner cuando exista y además podrá validarse en el módulo de escaneo por contenido mínimo configurable.
- El proveedor de firma digital/electrónica queda pendiente; el módulo debe conservar el puerto de integración y operar con adaptador simulado o pendiente de configuración.
- Los remitos firmados deben escanearse y adjuntarse al sistema como evidencia.

### Fase 12.1. Inventario y limpieza documental de instancia única

Objetivo:
eliminar de la documentación existente toda referencia a múltiples organizaciones como opción de producto y dejar explícito el nuevo modelo de instancia única.

Entregables:

- Inventario completo de menciones en `README.md`, `wiki.md`, `rf.md`, `rnf.md`, `MANUAL_USUARIO.md`, `contexto_handoff.md`, `normas_relacionadas.md`, `client/README.md`, `database/scripts/README.md`, `docs/*.md` y `requisitos_sgd_antiguo.md`.
- Reescritura de `rf.md` para quitar `RF-006 Configuración de organización única` como requisito de producto y reemplazarlo por configuración de organización/instancia.
- Reescritura de `rnf.md` para quitar separación por organización, claves por organización y disponibilidad instalación dedicada.
- Actualización de manuales y runbooks que hoy piden código de organización, administrador de organización, alta de organización o rutas legacy `/api/tenants`.
- Actualización del lenguaje de documentación técnica: `scoped a organización`, `orientado a organización`, `instancia única`, `instalación dedicada` y `instalación dedicada/on-premise` deben desaparecer o quedar marcados como deuda técnica histórica, no como capacidad vigente.
- Matriz de reemplazo terminológico: `organization` por `organización` o `instancia`; `administrador de organización` por `administrador de organización`; `platform admin` por `administrador del sistema`; `scoped a organización` por `scoped a organización` solo si todavía describe código existente.

Criterio de salida:

- `rg -n "multi[- ]?organization|organizacion|organizaciones|scoped a organización|orientado a organización|instalación dedicada" --glob "*.md"` no devuelve menciones de producto vigente.
- Las menciones históricas remanentes, si existen, están explícitamente marcadas como estado legado a migrar.

### Fase 12.2. Plan técnico de simplificación a instancia única

Objetivo:
definir el cambio técnico necesario para que el código acompañe la documentación y el producto deje de depender conceptualmente de organizaciones.

Entregables:

- Diseño de migración de dominio para reemplazar la entidad técnica legacy `Tenant` por `Organization`, `InstallationProfile` o entidad equivalente de instancia única.
- Decisión sobre persistencia: mantener temporalmente `organization_id` como columna técnica legacy con valor único o migrar a claves sin organización en fases posteriores.
- Diseño de compatibilidad para rutas API: mantener `/api/tenants/...` como superficie legacy, incorporar rutas de organización actual como `/api/organization/current` y migrar después a rutas sin identificador de organización.
- Backlog de refactor para `Auth`, `Admin`, `Documents`, `Records`, `Workflow`, `Signature`, `Search`, `Reports`, `Audit`, verticales y estructura documental.
- Plan de tests para reemplazar casos `scoped a organización` por casos de permisos, organización única, áreas, roles y proyectos.
- Plan de migración de datos para instalaciones existentes, fijando una única organización activa y eliminando operaciones de alta/listado de organizaciones adicionales.
- Primer incremento ejecutado: se bloqueó el alta adicional después del bootstrap, se eliminó la acción visible de creación en la UI admin y se agregó `GET /api/organization/current` como endpoint de transición.
- Segundo incremento ejecutado: se agregaron rutas de usuarios de organización actual `GET/POST /api/organization/users` y `POST /api/organization/users/{userId}/roles`, manteniendo las rutas legacy con identificador para compatibilidad.

Criterio de salida:

- Existe ADR o documento de diseño aprobado antes de tocar migraciones destructivas.
- El plan identifica rutas, tablas, servicios, DTOs, tests y pantallas impactadas.

### Fase 12.3. Requisitos base del módulo `digitization`

Objetivo:
convertir `requisitos_sgd_antiguo.md` en backlog implementable del nuevo módulo independiente.

Entregables:

- Crear módulo backend `digitization` con Clean Architecture y límites propios.
- Crear paquete frontend `feature_digitization` o sección equivalente en `gdms_app`.
- Definir agregados iniciales: proyecto de digitalización, manifiesto esperado, lote físico, remito, contenedor físico, documento físico, etiqueta, sesión de escaneo, revisión, excepción y despacho.
- Definir estados canónicos de contenedor y documento según `requisitos_sgd_antiguo.md`.
- Integrar auditoría obligatoria para toma de trabajo, cambios de estado, excepciones, etiquetas, escaneo, edición de páginas, revisión, OCR, firma y despacho.
- Integrar permisos por rol operativo: supervisor, recepción detallada, preparación, digitalización, revisión/indexación, consultor externo y auditor.

Criterio de salida:

- El módulo compila con contratos públicos definidos.
- Existen tests unitarios de estados y transiciones críticas.
- No se mezcla lógica específica de digitalización dentro del core documental salvo interfaces explícitas.

### Fase 12.4. Recepción, manifiestos, excepciones y etiquetas

Objetivo:
cubrir el flujo físico previo al escaneo.

Entregables:

- Carga manual y estructura de importación flexible de manifiestos, dejando pendiente el formato oficial definitivo.
- Registro de solicitudes de contenedores y remitos de ingreso sin integración automática con depósitos externos.
- Recepción detallada por contenedor y documento.
- Verificación de completitud contra manifiesto.
- Gestión de faltantes, sobrantes y documentos sin contenedor presente.
- Zona controlada para documentos sin contenedor.
- Generación e impresión de etiquetas con numeración autoincremental para contenedores y documentos.
- Reimpresión controlada con motivo auditado.

Criterio de salida:

- Un lote puede recibirse, verificarse y quedar listo para preparación.
- Las discrepancias bloquean avance normal hasta resolución o autorización.
- Todo movimiento relevante queda auditado.

### Fase 12.5. Preparación y escaneo operativo

Objetivo:
implementar la operación de preparación física y digitalización.

Entregables:

- Bandeja de preparación por rol.
- Marcado de documentos preparados y observaciones por deterioro o no escaneabilidad.
- Toma de contenedor por digitalizador mediante código de barras.
- Integración con `windows-twain` para captura desde escáner.
- Agregado desde archivo con validaciones de seguridad.
- Manejo de páginas individuales con miniaturas, navegación, rotación, reordenamiento, inserción, eliminación y salto a página.
- Eliminación de blancos apoyada en configuración de escáner y validación opcional de contenido mínimo desde el módulo.
- Validación backend de que todo documento obligatorio tenga al menos una imagen antes de enviar a revisión.

Criterio de salida:

- El flujo `preparación -> escaneo -> envío a revisión` funciona de extremo a extremo.
- Fallos de escáner o red no corrompen sesiones ni pierden páginas confirmadas.
- Las imágenes quedan preservadas individualmente hasta el cierre documental.

### Fase 12.6. Revisión, indexación, PDF/A y OCR

Objetivo:
cerrar calidad documental y producir el artefacto digital final.

Entregables:

- Bandeja de revisión e indexación.
- Comparación contra físico con resultado correcto, observado o corregir escaneo.
- Carga de metadatos configurables por proyecto y tipo documental.
- Devolución a corrección de escaneo con motivo, documento y páginas observadas.
- Generación final de PDF/A desde imágenes individuales.
- OCR opcional según configuración del proyecto, embebido o asociado al PDF/A final.
- Indexación de metadatos y texto OCR para búsqueda.

Criterio de salida:

- Un documento revisado correctamente puede finalizar en PDF/A.
- Si el proyecto tiene OCR activo, el PDF/A final queda buscable por texto.
- Los documentos observados no se publican hasta resolución.

### Fase 12.7. Visualizador, permisos externos y firma

Objetivo:
exponer los documentos finalizados desde el mismo cliente GDMS con control de permisos.

Entregables:

- Permisos externos dentro del mismo cliente, sin construir visualizador separado.
- Búsqueda por atributos de proyecto, contenedor, documento, lote, remito, metadatos y OCR.
- Previsualización segura con navegación de páginas y descarga según política.
- Firma digital/electrónica mediante puerto `SignatureProviderPort`, con proveedor concreto pendiente.
- Adaptador simulado o estado `pendiente_configuracion` para proyectos que requieran firma antes de definir proveedor.

Criterio de salida:

- Un consultor externo autorizado accede solo a documentos publicados.
- La búsqueda no filtra resultados fuera de permisos.
- El flujo de firma queda preparado aunque el proveedor final se defina después.

### Fase 12.8. Despacho físico, remitos firmados y evidencia

Objetivo:
cerrar el ciclo físico y probatorio del contenedor.

Entregables:

- Bandeja de contenedores pendientes de despacho.
- Generación de remito de salida/devolución.
- Escaneo y adjunto del remito firmado como evidencia documental.
- Registro de transporte, fecha, usuario que entrega y evidencia asociada.
- Cierre de contenedor solo si no hay excepciones abiertas, OCR/firma obligatoria pendiente ni jobs críticos fallidos.
- Exportación de paquete de evidencia por documento, contenedor o lote.

Criterio de salida:

- Un contenedor puede pasar de finalizado digitalmente a despachado y cerrado.
- El remito firmado queda asociado al despacho y disponible para auditoría.
- La cadena de custodia puede reconstruirse extremo a extremo.

### Fase 12.9. Reportes, dashboards y operación

Objetivo:
dar visibilidad operativa al nuevo flujo de digitalización.

Entregables:

- Dashboard de estados por lote, proyecto, contenedor, documento y sector.
- Alertas por faltantes, sobrantes, correcciones de escaneo, jobs OCR fallidos, firma pendiente y despachos demorados.
- Reporte de discrepancias de manifiesto.
- Reporte de productividad por usuario, sector y período.
- Seguimiento de ubicación física por zonas: recepción, preparación, digitalización, revisión, documentos sin contenedor y despacho.
- Métricas de jobs de OCR, PDF/A, indexación y firma.

Criterio de salida:

- El supervisor puede detectar cuellos de botella y excepciones abiertas.
- Los reportes operativos pueden exportarse.
- Las métricas se incorporan al smoke/preproducción cuando el módulo esté activo.

### Fase 12.10. Calidad, migración documental y gates

Objetivo:
asegurar que los cambios de arquitectura documental, simplificación a instancia única y digitalización no degraden el estándar del repo.

Entregables:

- Tests unitarios del módulo `digitization`.
- Tests de integración con PostgreSQL para manifiestos, contenedores, documentos, estados, excepciones y despachos.
- Contract tests de API para rutas nuevas sin organización.
- E2E smoke `recepción -> etiquetas -> preparación -> escaneo -> revisión -> PDF/A/OCR -> visualización -> despacho`.
- Actualización de `validate_workspace.ps1` para incluir el nuevo módulo.
- Actualización de runbooks y manuales una vez implementado el flujo.
- Verificación documental final para confirmar que no quedaron referencias instancia única como capacidad vigente.

Criterio de salida:

- Workspace en verde.
- Documentación alineada al modelo de instancia única.
- Flujo principal de digitalización cubierto por pruebas automatizadas.





