# Contexto IA - GDMS

Fecha de corte: 2026-04-28.

## 1. Objetivo Del Proyecto

GDMS es un sistema de gestión documental que se está reorientando a una instalación de organización única. El objetivo actual es eliminar la opción visible y documental de operación multi-organización, mantener compatibilidad técnica legacy donde todavía sea necesario, y sumar al plan de desarrollo los requisitos del sistema de digitalización físico analizado en `requisitos_sgd_antiguo.md`.

El nuevo módulo de digitalización debe cubrir recepción física, manifiestos, etiquetas, preparación, escaneo TWAIN en Windows, revisión/indexación, OCR opcional, PDF/A, auditoría, excepciones, remitos y despacho físico.

## 2. Decisiones Técnicas Tomadas

- El producto deja de ofrecer multi-organización como capacidad vigente. La documentación se alineó al modelo de instancia/organización única.
- No se hizo una migración destructiva completa de dominio, base de datos ni rutas internas. `Tenant`, `tenantId` y `/api/tenants/...` siguen existiendo como nombres técnicos legacy hasta una fase posterior.
- El alta adicional de organizaciones quedó bloqueada después del bootstrap: `POST /api/tenants` devuelve `409 Conflict` cuando ya existe administrador de plataforma.
- Se eliminó la acción visible de crear/configurar organización adicional desde la UI admin.
- Se agregó `GET /api/organization/current` como endpoint de transición para consultar la organización de la sesión actual sin listar múltiples organizaciones.
- Se agregaron rutas de usuarios de organización actual: `GET /api/organization/users`, `POST /api/organization/users` y `POST /api/organization/users/{userId}/roles`.
- La UI de gestión de usuarios admin ahora usa `/api/organization/users` en lugar de construir URLs `/api/tenants/{tenantId}/users`.
- Las rutas legacy `/api/tenants/{tenantId}/users` se mantienen activas por compatibilidad.
- Se agregaron rutas de auditoría de organización actual: `GET /api/organization/audit/events/recent` y `GET /api/organization/documents/{documentId}/audit-events`.
- Los clientes Flutter principales de auditoría, admin, dashboard legal y detalle documental usan las rutas `/api/organization/...` para leer eventos de auditoría cuando no requieren vista global de plataforma.
- Las rutas legacy de auditoría `/api/tenants/{tenantId}/audit/events/recent` y `/api/tenants/{tenantId}/documents/{documentId}/audit-events` se mantienen activas por compatibilidad.
- Se agregaron rutas de workflow de organización actual: `GET /api/organization/workflow/tasks`, `POST /api/organization/workflow/tasks` y `POST /api/organization/workflow/tasks/{taskId}/complete`.
- Los clientes Flutter principales de workflow, tareas documentales y dashboards legal/corporate/real estate usan `/api/organization/workflow/tasks` para listar, crear o completar tareas.
- Las rutas legacy de workflow `/api/tenants/{tenantId}/workflow/tasks` y `/api/tenants/{tenantId}/workflow/tasks/{taskId}/complete` se mantienen activas por compatibilidad.
- Se agregó ruta de notificaciones de organización actual: `GET /api/organization/notifications`.
- Los clientes Flutter principales de notificaciones y dashboards corporate/real estate usan `/api/organization/notifications`.
- La ruta legacy de notificaciones `/api/tenants/{tenantId}/notifications` se mantiene activa por compatibilidad.
- Se agregó ruta de reportes de organización actual: `GET /api/organization/reports/operational-summary`.
- El cliente Flutter de reportes usa `/api/organization/reports/operational-summary` para el resumen operativo y conserva `/api/reports/platform-summary` para administradores de plataforma.
- La ruta legacy de reportes `/api/tenants/{tenantId}/reports/operational-summary` se mantiene activa por compatibilidad.
- Los textos visibles de Flutter y comentarios públicos relevantes se movieron de `tenant` a `organización`.
- El plan de desarrollo quedó actualizado con la estrategia por fases y los incrementos ejecutados.

## 3. Archivos Creados/Modificados

Archivos creados relevantes:

- `ia_context.md`
- `requisitos_sgd_antiguo.md`
- `server/src/Gdms.Api/Controllers/CurrentOrganizationController.cs`
- `server/tests/Gdms.ApiContractTests/CurrentOrganizationControllerContractTests.cs`

Archivos eliminados relevantes:

- `client/apps/gdms_app/lib/src/admin/application/create_tenant_view_model.dart`
- `client/apps/gdms_app/lib/src/admin/presentation/create_tenant_dialog.dart`

Archivos modificados principales:

- `docs/plan_desarrollo_sesiones_grandes.md`
- `README.md`, `wiki.md`, `rf.md`, `rnf.md`, `MANUAL_USUARIO.md`, `contexto_handoff.md`, `normas_relacionadas.md`
- `client/README.md`, `database/scripts/README.md`, `docs/*.md`
- `server/src/Gdms.Api/Controllers/TenantsController.cs`
- `server/src/Gdms.Api/Controllers/AuditController.cs`
- `server/src/Gdms.Api/Controllers/UsersController.cs`
- `server/src/Gdms.Api/Controllers/WorkflowController.cs`
- `server/src/Gdms.Api/Controllers/NotificationsController.cs`
- `server/src/Gdms.Api/Controllers/ReportsController.cs`
- `server/src/Gdms.Application/Tenants/TenantService.cs`
- `server/tests/Gdms.ApiContractTests/AuditControllerContractTests.cs`
- `server/tests/Gdms.ApiContractTests/WorkflowControllerContractTests.cs`
- `server/tests/Gdms.ApiContractTests/NotificationsControllerContractTests.cs`
- `server/tests/Gdms.ApiContractTests/ReportsControllerContractTests.cs`
- `server/tests/Gdms.ApiContractTests/TenantsControllerContractTests.cs`
- `server/tests/Gdms.ApiContractTests/UsersControllerContractTests.cs`
- `client/packages/feature_admin/lib/src/presentation/admin_dashboard_page.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_admin_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_audit_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_workflow_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_corporate_dashboard_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_legal_dashboard_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_notifications_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_reports_repository.dart`
- `client/apps/gdms_app/lib/src/infrastructure/repositories/api_real_estate_dashboard_repository.dart`
- `client/apps/gdms_app/lib/src/documents/application/document_details_view_model.dart`
- `client/apps/gdms_app/lib/src/documents/application/document_workflow_tasks_view_model.dart`
- `client/apps/gdms_app/lib/src/workflow/application/create_workflow_task_view_model.dart`
- `client/apps/gdms_app/lib/src/admin/application/identity_management_view_model.dart`
- `client/apps/gdms_app/lib/src/app/gdms_authenticated_shell_admin.dart`
- `client/apps/gdms_app/integration_test/gdms_app_ui_document_scan_flow_test.dart`

Hay muchas modificaciones adicionales de texto visible/comentarios y formato en paquetes Flutter y backend. Revisar `git status --short` antes de continuar porque el árbol de trabajo está sucio y también contiene cambios no relacionados/preexistentes.

## 4. Qué Falta Hacer

- Migrar progresivamente rutas restantes `/api/tenants/{tenantId}/...` hacia rutas de organización actual o rutas sin identificador de organización.
- Definir ADR de instancia única antes de tocar migraciones destructivas de base de datos.
- Decidir si `tenant_id` queda como columna técnica legacy con un único valor o si se elimina en fases futuras.
- Renombrar internamente dominio/contratos de `Tenant` hacia `Organization` o `InstallationProfile` cuando exista diseño aprobado.
- Actualizar contratos y tests para dejar de usar nombres `Tenant*` donde ya no correspondan.
- Migrar módulos pendientes: documentos, records, firmas, integraciones, estructura documental y verticales legal/corporate/real estate.
- Revisar consumidores residuales de reportes si aparecen flujos nuevos sobre `/api/tenants/{tenantId}/reports/...`; los tests todavía ejercitan ruta legacy para compatibilidad.
- Revisar consumidores residuales de notificaciones si aparecen flujos nuevos sobre `/api/tenants/{tenantId}/notifications`; los tests todavía ejercitan ruta legacy para compatibilidad.
- Revisar consumidores residuales de workflow si aparecen flujos nuevos sobre `/api/tenants/{tenantId}/workflow/...`; los tests todavía ejercitan rutas legacy para compatibilidad.
- Completar la migración de consumidores residuales de auditoría si siguen apareciendo flujos específicos sobre `/api/tenants/{tenantId}/audit/...`; `api_admin_tenant_details_repository.dart` todavía usa ruta legacy para la vista de detalle por organización.
- Implementar el módulo `digitization` descrito en el plan: backend, frontend, modelos, estados, auditoría, TWAIN, OCR/PDF-A, excepciones y despacho.
- Ejecutar contract tests reales con PostgreSQL habilitado.
- Revisar archivos de configuración sucios (`.env.example`, `.gitignore`, `docker-compose.yml`) antes de commit para separar cambios relacionados de cambios previos.

## 5. Riesgos O Bugs Abiertos

- Persisten nombres internos legacy `Tenant`, `tenantId`, `TenantResponse`, `CreateTenantRequest` y rutas `/api/tenants/...`. Esto es deuda técnica controlada, no eliminación completa.
- Los contract tests compilan, pero se omiten si no está configurada la variable de conexión PostgreSQL requerida por `PostgresContractFact`.
- El árbol Git incluye muchos cambios y archivos no rastreados. Hay riesgo de mezclar tareas si se hace commit sin revisar por grupos.
- `dotnet test` puede fallar si se ejecuta en paralelo con build por bloqueo temporal de `Gdms.Api.dll` por `VBCSCompiler`; reintentar con `--no-build` después de build suele resolverlo.
- Las pruebas Flutter pueden modificar caches rastreados en `client/packages/*/build/test_cache`; si aparecen en `git status`, restaurarlos antes de commit.
- El flujo TWAIN de integración depende del puerto default `http://127.0.0.1:43127`; ya se alineó la prueba, pero cambiar el default requiere actualizar test y runtime juntos.

Validaciones ya ejecutadas:

- `dotnet build .\server\Gdms.sln`: correcto.
- `flutter test` en `client/packages/feature_admin`: correcto.
- `flutter test` en `feature_audit`, `feature_auth`, `feature_reports`: correcto en iteración previa.
- `flutter test test/widget_test.dart test/upload_document_dialog_state_test.dart` en `client/apps/gdms_app`: correcto.
- `flutter test -d windows integration_test/gdms_app_ui_document_scan_flow_test.dart`: correcto.
- `dotnet test .\server\tests\Gdms.ApiContractTests\Gdms.ApiContractTests.csproj --no-build --filter "UsersControllerContractTests|CurrentOrganizationControllerContractTests|TenantsControllerContractTests"`: tests omitidos por falta de PostgreSQL de integración, sin errores de compilación.
- `dotnet test .\server\tests\Gdms.ApiContractTests\Gdms.ApiContractTests.csproj --no-build --filter "AuditControllerContractTests|CurrentOrganizationControllerContractTests|UsersControllerContractTests"`: 15 tests omitidos por falta de PostgreSQL de integración, sin errores de compilación.
- `dotnet test .\server\tests\Gdms.ApiContractTests\Gdms.ApiContractTests.csproj --no-build --filter "WorkflowControllerContractTests|CurrentOrganizationControllerContractTests"`: 9 tests omitidos por falta de PostgreSQL de integración, sin errores de compilación.
- `dotnet test .\server\tests\Gdms.ApiContractTests\Gdms.ApiContractTests.csproj --no-build --filter "NotificationsControllerContractTests|CurrentOrganizationControllerContractTests"`: 7 tests omitidos por falta de PostgreSQL de integración, sin errores de compilación.
- `dotnet test .\server\tests\Gdms.ApiContractTests\Gdms.ApiContractTests.csproj --no-build --filter "ReportsControllerContractTests|CurrentOrganizationControllerContractTests"`: 7 tests omitidos por falta de PostgreSQL de integración, sin errores de compilación.

## 6. Próximo Prompt Recomendado

Continuá la migración incremental a organización única. Próxima prioridad sugerida: integraciones, documentos o firmas, agregando rutas `/api/organization/...` equivalentes y migrando consumidores Flutter sin retirar rutas legacy. Antes de editar, revisá `git status --short`, evitá tocar cambios no relacionados, y después ejecutá `dotnet build .\server\Gdms.sln` más las pruebas Flutter/contract tests afectados.
