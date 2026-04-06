# Plan de desarrollo para sesiones grandes

Fecha de actualización: `2026-04-06`

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
- suite `server/tests/Gdms.UnitTests` agregada a la solución con cobertura inicial en `Auth`, `TenantService` y `Document`.
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

Estado actual de integración backend:

- `Gdms.IntegrationTests` corre contra PostgreSQL real cuando existe `GDMS_TEST_POSTGRES_CONNECTION`;
- cada corrida crea una base efímera, aplica `database/scripts` y destruye la base al finalizar;
- el gate principal no lo exige todavía en todos los entornos, pero `validate_workspace.ps1` ya lo ejecuta automáticamente cuando la variable está disponible.
- la suite ya cubre persistencia real de `Tenant`, `User`, `Documents`, `DocumentMetadata` y `Auth`;
- la suite ya cubre también `Records` con políticas de retención, legal holds y candidatos de disposición;
- la suite ya cubre también `Workflow` y `Signature` con persistencia real, auditoría y transiciones principales de estado;
- la suite ya cubre también `Reports` con agregación operacional tenant-scoped y resumen de plataforma;
- la suite `Gdms.ApiContractTests` ya cubre `ReportsController` con contratos HTTP `401`, `403` y `200`;
- la suite `Gdms.ApiContractTests` ya cubre también `RecordsController` sobre `disposition-candidates`, aplicación de retención y ciclo de `legal hold` con contratos HTTP `401`, `403`, `200`, `201` y `204`;
- la suite `Gdms.ApiContractTests` ya cubre también `DocumentsController` sobre lectura, ACL y creación con contratos HTTP `401`, `403`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `SignaturesController` sobre listado, creación, completado y cancelación con contratos HTTP `401`, `403`, `200` y `201`;
- la suite `Gdms.ApiContractTests` ya cubre también `WorkflowController` sobre listado, creación y completado con contratos HTTP `401`, `403`, `200` y `201`;
- la suite `Gdms.E2eSmokeTests` ya cubre un flujo cross-system real con `bootstrap/login` JWT, upload multipart, metadata, workflow, signature y reporte operacional;
- la suite `Gdms.E2eSmokeTests` ya cubre también un flujo cross-system de binarios con upload inicial, nueva versión y descarga;
- la suite `Gdms.E2eSmokeTests` ya cubre también ACL multiusuario con bootstrap real, alta de usuario, transición de acceso implícito a ACL explícita y descarga controlada;
- la suite `Gdms.E2eSmokeTests` ya cubre también `scan -> export pdf local -> upload backend` usando `windows-twain` headless con sesión rehidratada y JWT real;
- la suite `Gdms.E2eSmokeTests` ya cubre también edición de sesión local rehidratada sobre `windows-twain` con `preview`, `merge`, `move`, `delete` y upload final al backend;
- la suite `Gdms.E2eSmokeTests` ya cubre también recovery del host local `windows-twain` con reinicio, rehidratación de sesión mutada y upload posterior al backend;
- la suite `Gdms.E2eSmokeTests` ya cubre también mantenimiento explícito del host local con `clear rehydrated sessions` y validación de vaciado operativo del estado persistido;
- la suite `Gdms.E2eSmokeTests` ya cubre también cleanup de artefactos huérfanos envejecidos sin afectar sesiones activas del host local;
- `client/apps/gdms_app` ya cubre recuperación del cliente ante host local caído y restablecido, recomponiendo estado de scanners, sesiones y mensaje operativo;
- en entornos de desarrollo con PostgreSQL local instalado, el contenedor del repo quedó expuesto en `localhost:5433` para evitar conflicto con `5432`.

## 4. Definición operativa de cobertura completa

Para este proyecto, "cobertura completa" no debe significar perseguir `100%` lineal del monorepo sin criterio. La definición operativa será:

- `100%` del código nuevo o modificado en una sesión debe salir cubierto por pruebas automáticas.
- `100%` de los flujos críticos debe tener al menos una combinación de `unit`, `integration`, `contract` o `e2e-smoke`.
- `Gdms.Domain` y `Gdms.Application` deben converger al objetivo `>= 80%` indicado en `rnf.md`.
- APIs críticas deben tener pruebas positivas, negativas y tenant-scoped.
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

La siguiente prioridad correcta es endurecer el smoke de escaneo hacia un flujo con browser o hacia escenarios de cliente contra host caído durante operación activa, manteniendo el threshold backend de CI en `54%` como piso y evitando cualquier regresión por debajo de la baseline consolidada actual.
