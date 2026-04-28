# Contexto de Handoff

## Objetivo del proyecto

Desarrollar un sistema de gestion documental/ECM modular, hibrido, instancia única, seguro y auditable para empresas, inmobiliarias, estudios juridicos y organizaciónes similares en la Republica Argentina.

El sistema debe cumplir y trazar:
- normativa argentina aplicable;
- buenas practicas ISO/IRAM;
- requisitos de seguridad, privacidad, evidencia y accesibilidad;
- arquitectura limpia y modular para backend y frontend.

## Documentos contractuales vigentes

Estos archivos son la fuente de verdad funcional y normativa actual:
- `C:\IA\codex\rf.md`
- `C:\IA\codex\rnf.md`
- `C:\IA\codex\normas_relacionadas.md`

## Stack y decisiones tecnicas vigentes

- Backend: `.NET 10 LTS` con `C#`
- Arquitectura backend: `modular monolith` + `Clean Architecture`
- Frontend: `Flutter` estable
- UI frontend: `MVVM`
- Resto del frontend: `Clean Architecture`
- Base de datos relacional: `PostgreSQL 18.x`
- Configuracion dinamica no sensible: `Firebase Remote Config`
- Datos no relacionales/proyecciones: `Cloud Firestore`
- Busqueda: `OpenSearch`
- Binarios: almacenamiento `S3-compatible`
- Integracion futura: `Outbox`
- Documentacion de API: `Swagger/OpenAPI`
- Documentacion tecnica .NET: comentarios XML + `DocFX`
- Accesibilidad: `WCAG 2.2 AA`

## Estado actual implementado

### Documentacion

Se generaron y actualizaron:
- `C:\IA\codex\rf.md`
- `C:\IA\codex\rnf.md`
- `C:\IA\codex\normas_relacionadas.md`

### Backend

Se creo una solucion base en:
- `C:\IA\codex\server\Gdms.sln`

Capas actuales:
- `C:\IA\codex\server\src\Gdms.Api`
- `C:\IA\codex\server\src\Gdms.Application`
- `C:\IA\codex\server\src\Gdms.Domain`
- `C:\IA\codex\server\src\Gdms.Infrastructure`
- `C:\IA\codex\server\src\Gdms.Contracts`

Tests iniciales:
- `C:\IA\codex\server\tests\Gdms.ArchitectureTests`

### API actual

La API ya expone Swagger y tiene endpoints base documentados:
- `C:\IA\codex\server\src\Gdms.Api\Controllers\HealthController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\OrganizaciónesController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\DocumentsController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\RolesController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\UsersController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\AuthController.cs`

Configuracion central:
- `C:\IA\codex\server\src\Gdms.Api\Program.cs`
- `C:\IA\codex\server\src\Gdms.Api\Infrastructure\DomainExceptionHandler.cs`

### Dominio y aplicacion

Modelos y reglas iniciales:
- `C:\IA\codex\server\src\Gdms.Domain\Tenancy\Organización.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Documents\Document.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Documents\DocumentVersion.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Documents\DocumentStatus.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Common\DomainRuleException.cs`

Servicios de aplicacion:
- `C:\IA\codex\server\src\Gdms.Application\Organizaciónes\OrganizationService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Documents\DocumentService.cs`

Puertos actuales:
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Persistence\IOrganizaciónRepository.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Persistence\IDocumentRepository.cs`

### Persistencia real

Se reemplazaron los repositorios en memoria por repositorios PostgreSQL:
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresOrganizaciónRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresDocumentRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresAuditEventRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresRoleRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresUserRepository.cs`

Configuracion de infraestructura:
- `C:\IA\codex\server\src\Gdms.Infrastructure\DependencyInjection.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Configuration\PostgresOptions.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Configuration\FirebaseOptions.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Configuration\JwtOptions.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Security\JwtSigningKeyProvider.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Security\JwtAccessTokenIssuer.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Security\LocalPasswordHashingService.cs`

### Base de datos

Scripts actuales:
- `C:\IA\codex\database\scripts\001_extensions_and_schemas.sql`
- `C:\IA\codex\database\scripts\002_core_tables.sql`
- `C:\IA\codex\database\scripts\003_seed_reference_data.sql`
- `C:\IA\codex\database\scripts\004_identity_auth_enhancements.sql`
- `C:\IA\codex\database\scripts\005_records_management_enhancements.sql`
- `C:\IA\codex\database\scripts\006_document_disposition_status.sql`
- `C:\IA\codex\database\scripts\007_document_type_metadata_seed_defaults.sql`
- `C:\IA\codex\database\scripts\008_document_metadata_storage.sql`
- `C:\IA\codex\database\scripts\009_workflow_tasks.sql`
- `C:\IA\codex\database\scripts\010_signature_envelopes.sql`
- `C:\IA\codex\database\scripts\011_case_files.sql`
- `C:\IA\codex\database\scripts\012_case_file_document_links.sql`
- `C:\IA\codex\database\scripts\013_document_access_entries.sql`
- `C:\IA\codex\database\scripts\014_property_files.sql`
- `C:\IA\codex\database\scripts\015_property_file_document_links.sql`
- `C:\IA\codex\database\scripts\016_corporate_record_files.sql`
- `C:\IA\codex\database\scripts\017_corporate_record_file_document_links.sql`
- `C:\IA\codex\database\scripts\018_workflow_task_assignments.sql`
- `C:\IA\codex\database\scripts\019_signature_cancellation.sql`
- `C:\IA\codex\database\scripts\README.md`

### Docker y despliegue

Archivos preparados:
- `C:\IA\codex\docker-compose.yml`
- `C:\IA\codex\server\Dockerfile`
- `C:\IA\codex\server\.dockerignore`

Nota: en la maquina anterior Docker no pudo instalarse, por eso se preparo tambien una ruta de trabajo sin contenedores.

### Documentacion operativa

Archivos actuales:
- `C:\IA\codex\docs\implementacion_backend_docker.md`
- `C:\IA\codex\docs\documentation_tooling.md`

## Estado del frontend

El frontend Flutter ya tiene una primera implementacion modular operativa en:
- `C:\IA\codex\client\apps\gdms_app`
- `C:\IA\codex\client\packages\core`
- `C:\IA\codex\client\packages\design_system`
- `C:\IA\codex\client\packages\feature_auth`
- `C:\IA\codex\client\packages\feature_config`
- `C:\IA\codex\client\packages\feature_documents`
- `C:\IA\codex\client\packages\feature_integrations`
- `C:\IA\codex\client\packages\feature_notifications`
- `C:\IA\codex\client\packages\feature_records`
- `C:\IA\codex\client\packages\feature_reports`
- `C:\IA\codex\client\packages\feature_admin`
- `C:\IA\codex\client\packages\feature_audit`
- `C:\IA\codex\client\packages\feature_search`
- `C:\IA\codex\client\packages\feature_signature`
- `C:\IA\codex\client\packages\feature_sector_corporate`
- `C:\IA\codex\client\packages\feature_sector_legal`
- `C:\IA\codex\client\packages\feature_sector_real_estate`
- `C:\IA\codex\client\packages\feature_workflow`

Estado actual del frontend:
- shell responsive con `NavigationBar` y `NavigationRail`;
- tema visual propio en `design_system`;
- `MVVM` base con `ViewModel` y `ViewState` en `core`;
- gate de autenticacion con login y bootstrap inicial;
- features iniciales de acceso, documentos, records y administracion;
- modulo dedicado de configuracion dinamica y preferencias;
- modulo dedicado de auditoria con trazabilidad reciente;
- modulo dedicado de busqueda documental;
- modulo dedicado de firma documental con solicitudes y cierre de firmas;
- modulo dedicado de integraciones con estado de conectividad y configuración;
- inbox operativo de notificaciones scoped a organización;
- modulo dedicado de reportes operativos con vista organización y plataforma;
- primer vertical sectorial juridico;
- vertical sectorial inmobiliario inicial;
- vertical sectorial corporativo inicial;
- repositorios HTTP reales para auth, documents, records y admin parcial;
- carga documental real con catalogo de tipos y metadatos dinamicos validados;
- consulta de detalle documental y lectura de metadatos desde la API;
- exportacion probatoria por documento desde el detalle documental;
- tests y analisis estatico en verde;
- convención Android en `C:\IA\codex\client\apps\gdms_app\android\build-logic`.

## Avance nuevo incorporado en esta iteracion

Se implemento el modulo inicial de identidad y acceso del backend:
- dominio para `User`, `Role` y `UserStatus`;
- servicios de aplicacion `UserService` y `RoleService`;
- contratos API para alta de usuarios y asignacion de roles;
- controladores Swagger para:
  - `GET /api/roles`
  - `GET /api/organization/users`
  - `GET /api/organization/users/{userId}`
  - `POST /api/organization/users`
  - `POST /api/organization/users/{userId}/roles`
- persistencia PostgreSQL real para usuarios y roles.

Validacion realizada:
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln --no-build`

Resultado:
- build exitoso;
- tests exitosos.

## Avance nuevo incorporado en la iteracion documental orientado a organización

Se endurecio el modulo documental:
- los endpoints documentales pasaron a ser scoped a organización;
- el `organizationId` se toma del route y ya no del body;
- el `uploadedByUserId` se deriva desde el JWT y ya no del cliente;
- se protege acceso por organización en documentos;
- se agrego listado documental por organización;
- se agrego auditoria inmutable de lectura y alta documental.

Endpoints documentales actuales:
- `GET /api/organization/documents`
- `GET /api/organization/documents/{documentId}`
- `POST /api/organization/documents`

Persistencia nueva:
- `PostgresAuditEventRepository` inserta eventos en `audit.audit_events`;
- `PostgresDocumentRepository` ya soporta lectura por organización y rehidratacion de versiones.

Validacion realizada:
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`

Resultado:
- build exitoso;
- tests exitosos.

## Avance nuevo incorporado en la iteracion siguiente

Se implemento la base de autenticacion y autorizacion HTTP del backend:
- JWT bearer para autenticacion local;
- hashing de contraseñas con primitives de ASP.NET Core Identity;
- bootstrap seguro del primer `PLATFORM_ADMIN` de la plataforma;
- bootstrap seguro del primer `ORGANIZATION_ADMIN` por organización;
- login local por `organizationCode + email + password`;
- endpoint autenticado `GET /api/auth/me`;
- bloqueo temporal por intentos fallidos;
- tracking de ultimo acceso exitoso;
- proteccion de endpoints de usuarios y roles con JWT;
- control de acceso por organización en la administracion de usuarios.

Endpoints nuevos:
- `POST /api/auth/bootstrap-platform-admin`
- `POST /api/auth/bootstrap-organization-admin`
- `POST /api/auth/token`
- `GET /api/auth/me`

Cambios de esquema incorporados:
- columnas de credenciales y lockout en `identity.users`;
- script incremental `004_identity_auth_enhancements.sql`.

Validacion realizada:
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`

Resultado:
- build exitoso;
- tests exitosos.

## Avance nuevo incorporado en la iteracion de cierre de administracion de organizaciónes

Se redujo la exposicion anonima de administracion de organizaciónes:
- `GET /api/organization` ahora exige `PLATFORM_ADMIN`;
- `POST /api/organization` queda libre solo mientras no exista ningun `PLATFORM_ADMIN`;
- una vez bootstrappeado el primer `PLATFORM_ADMIN`, la alta de organizaciónes requiere ese rol;
- `POST /api/auth/bootstrap-platform-admin` permite inicializar la gobernanza global usando una organización existente.

Validacion realizada:
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`

Resultado:
- build exitoso;
- tests exitosos.

## Avance nuevo incorporado en la iteracion de records management

Se implemento la primera capa operativa de records management:
- listado de politicas de retencion disponibles por organización;
- aplicacion de politica de retencion a documentos;
- alta de `legal hold` por documento;
- liberacion de `legal hold` con motivo y trazabilidad;
- auditoria inmutable para aplicacion de retencion, alta y liberacion de `legal hold`.

Endpoints nuevos:
- `GET /api/organization/records/retention-policies`
- `POST /api/organization/records/documents/{documentId}/retention-policy`
- `GET /api/organization/records/documents/{documentId}/legal-holds`
- `POST /api/organization/records/documents/{documentId}/legal-holds`
- `POST /api/organization/records/legal-holds/{legalHoldId}/release`

Persistencia nueva:
- `PostgresRetentionPolicyRepository`;
- `PostgresLegalHoldRepository`;
- soporte de asignacion de politica de retencion en `PostgresDocumentRepository`;
- script incremental `005_records_management_enhancements.sql`.

Validacion realizada:
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`

Resultado:
- build exitoso;
- tests exitosos.

## Avance nuevo incorporado en la iteracion de auditoria y disposicion

Se completo la siguiente capa de cumplimiento en backend:
- auditoria para bootstrap de administradores, login exitoso, login fallido, bloqueo y cambios administrativos;
- calculo de candidatos a disposicion por vencimiento de retencion;
- ejecucion controlada de disposicion documental;
- bloqueo de disposicion destructiva cuando existe `legal hold` activo;
- nuevo estado documental `DISPOSED`.

Endpoints nuevos:
- `GET /api/organization/records/disposition-candidates`
- `POST /api/organization/records/documents/{documentId}/disposition/execute`

Persistencia nueva:
- `PostgresDocumentDispositionRepository`;
- script incremental `006_document_disposition_status.sql`.

Validacion realizada:
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`

Resultado:
- build exitoso;
- tests exitosos.

## Avance nuevo incorporado en la iteracion Flutter modular

Se inicio el frontend real del sistema:
- reemplazo completo del contador de ejemplo por un shell GDMS;
- features iniciales para `auth`, `documents`, `records` y `admin`;
- `design_system` con tema, metric tiles, section cards, page headers y status badges;
- pruebas unitarias y widget tests por modulo;
- convención Android mediante plugin `gdms.android.application`;
- validacion de `flutter analyze`, `flutter test` y `gradlew help`.

Archivos principales nuevos:
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_app.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\shell_banner.dart`
- `C:\IA\codex\client\apps\gdms_app\android\build-logic\build.gradle.kts`
- `C:\IA\codex\client\apps\gdms_app\android\build-logic\src\main\kotlin\gdms.android.application.gradle.kts`

Validacion realizada:
- `flutter analyze` en app y paquetes;
- `flutter test` en app y paquetes;
- `C:\IA\codex\client\apps\gdms_app\android\gradlew.bat help`

Resultado:
- analisis sin issues;
- tests en verde;
- Gradle funcional con warnings del SDK Android por directorios `.backup`.

## Avance nuevo incorporado en la iteracion de integracion frontend-backend

Se conecto la app Flutter con el backend real:
- login local contra `POST /api/auth/token`;
- bootstrap de `ORGANIZATION_ADMIN` y `PLATFORM_ADMIN` desde la UI;
- lectura de identidad con `GET /api/auth/me`;
- carga real de documentos y records desde la API;
- tablero admin parcialmente conectado segun rol;
- configuracion de CORS en el backend para clientes browser locales.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\apps\gdms_app\lib\src\auth\application\app_session_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\auth\presentation\sign_in_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\api\gdms_api_client.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_documents_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_records_repository.dart`
- `C:\IA\codex\server\src\Gdms.Api\Program.cs`
- `C:\IA\codex\server\src\Gdms.Api\Configuration\CorsOptions.cs`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- control de archivos por debajo de 300 lineas en verde.

## Avance nuevo incorporado en la iteracion de upload y search documental

Se avanzo sobre el nucleo ECM operativo:
- upload binario real a traves de multipart form-data;
- descarga del binario mas reciente por documento;
- storage local desacoplado mediante puerto `IDocumentBinaryStore`;
- busqueda documental por organización desde PostgreSQL;
- UI Flutter para subir documentos y buscar por titulo o tipo documental.

Endpoints nuevos:
- `POST /api/organization/documents/upload`
- `GET /api/organization/documents/{documentId}/download`
- `GET /api/organization/documents/search`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Api\Controllers\DocumentContentController.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Storage\IDocumentBinaryStore.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Storage\LocalFileDocumentBinaryStore.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresDocumentSearchRepository.cs`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\upload_document_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_upload_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\api\gdms_api_client.dart`
- `C:\IA\codex\client\packages\feature_documents\lib\src\presentation\documents_dashboard_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Actualizacion mas reciente

Se agregaron permisos documentales finos scoped a organización:
- tabla `documents.document_access_entries`;
- endpoint `GET /api/organization/documents/{documentId}/access-entries`;
- endpoint `POST /api/organization/documents/{documentId}/access-entries`;
- enforcement de `READ`, `DOWNLOAD`, `EDITMETADATA` y `UPLOADVERSION` sobre detalle, metadata y contenido documental;
- dialogo Flutter para consulta y otorgamiento de permisos desde el detalle documental.

Se agrego vertical inmobiliario real:
- tablas `documents.property_files` y `documents.property_file_documents`;
- endpoint `GET /api/organization/property-files`;
- endpoint `POST /api/organization/property-files`;
- endpoint `GET /api/organization/property-files/{propertyFileId}/documents`;
- endpoint `POST /api/organization/property-files/{propertyFileId}/documents`;
- dashboard inmobiliario con creacion de legajos, detalle de legajo y vinculacion de documentos.

Se agrego vertical corporativo real:
- tablas `documents.corporate_record_files` y `documents.corporate_record_file_documents`;
- endpoint `GET /api/organization/corporate-record-files`;
- endpoint `POST /api/organization/corporate-record-files`;
- endpoint `GET /api/organization/corporate-record-files/{corporateRecordFileId}/documents`;
- endpoint `POST /api/organization/corporate-record-files/{corporateRecordFileId}/documents`;
- dashboard corporativo con creacion de legajos, detalle de legajo y vinculacion de documentos.

Se mejoro la busqueda documental:
- endpoint `GET /api/organization/documents/search` ahora acepta `documentTypeCode`, `status` y `onLegalHold`;
- la UI de busqueda permite combinar texto libre con filtros por tipo documental, estado y legal hold;
- el backend audita tambien los filtros usados en `DOCUMENT_SEARCH`.

Se mejoro workflow documental:
- endpoint `GET /api/organization/workflow/tasks` ahora acepta `mine=true`;
- las tareas soportan `assignedToUserId` opcional;
- la UI permite asignar un responsable al crear una tarea;
- el dashboard de workflow permite filtrar por `Solo mis tareas`.

Se integro workflow al detalle documental:
- cada documento muestra sus tareas de workflow asociadas;
- desde el detalle documental se pueden crear tareas con el documento preseleccionado;
- desde el detalle documental se pueden completar tareas abiertas del mismo documento.

Validacion mas reciente:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\check_line_limits.ps1`
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`
- `flutter analyze` en `client\apps\gdms_app`
- `flutter test` en `client\apps\gdms_app`
- `flutter analyze` en `client\packages\feature_search`
- `flutter test` en `client\packages\feature_search`
- `flutter analyze` en `client\packages\feature_workflow`
- `flutter test` en `client\packages\feature_workflow`
- `flutter analyze` en `client\packages\feature_sector_corporate`
- `flutter test` en `client\packages\feature_sector_corporate`

Estado del roadmap estimado al 21/03/2026:
- avance general: `83%`;
- Fase 0: completa;
- Fase 1: muy avanzada;
- Fase 2: avanzada;
- Fase 3: parcial;
- Fase 4: avanzada;
- Fase 5: avanzada en legal, inmobiliario y corporativo;
- Fase 6: parcial;
- Fase 7: inicial.

## Avance nuevo incorporado en la iteracion del modulo reports

Se incorporo una primera capa real de reportes operativos:
- backend scoped a organización para resumen operativo consolidado;
- backend platform-scoped para vista global visible solo a `PLATFORM_ADMIN`;
- paquete `feature_reports` agregado al workspace;
- shell principal extendida con seccion dedicada de reportes;
- dashboard Flutter con métricas organización y bloque extra de plataforma cuando corresponde.

Endpoints nuevos:
- `GET /api/organization/reports/operational-summary`
- `GET /api/reports/platform-summary`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Reports\ReportsService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Reports\OperationalReportSummary.cs`
- `C:\IA\codex\server\src\Gdms.Application\Reports\PlatformReportSummary.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\ReportsController.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Reports\OperationalReportResponse.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Reports\PlatformReportResponse.cs`
- `C:\IA\codex\client\packages\feature_reports\lib\feature_reports.dart`
- `C:\IA\codex\client\packages\feature_reports\lib\src\presentation\reports_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_reports_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\shell_destination.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\shell_content.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_reports`.

## Avance nuevo incorporado en la iteracion de metadatos y taxonomias

Se avanzo sobre la capa tipada de metadata documental:
- catalogo de tipos documentales orientado a organización con prioridad a overrides dla organización;
- endpoint Swagger para listar tipos documentales visibles por organización;
- validacion y normalizacion de metadatos segun esquema JSON del tipo documental;
- persistencia de metadatos actuales en `documents.document_metadata`;
- carga Flutter con selector de tipo documental, campos dinamicos y validacion en UI;
- lectura de detalle documental con consulta de metadatos reales desde backend;
- descarga binaria real desde el detalle documental;
- edicion de metadatos desde Flutter con validacion y persistencia contra la API.

Endpoints nuevos:
- `GET /api/organization/document-types`
- `GET /api/organization/documents/{documentId}/metadata`
- `PUT /api/organization/documents/{documentId}/metadata`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Documents\DocumentTypeCatalogService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Documents\DocumentMetadataSchemaValidator.cs`
- `C:\IA\codex\server\src\Gdms.Application\Documents\DocumentMetadataService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\DocumentTypesController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\DocumentMetadataController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresDocumentTypeRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresDocumentMetadataRepository.cs`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\upload_document_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_upload_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_details_view_model.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion de records operativos en frontend

Se llevo la cola de records hacia una operacion real desde la UI:
- el dashboard de records ahora conserva `documentId` y codigos de accion reales;
- los items elegibles muestran accion `Ejecutar` con confirmacion;
- la ejecucion consume el endpoint de disposicion del backend y refresca la cola;
- la UI respeta las restricciones de negocio: no ejecuta `REVIEW` ni items con `legal hold`;
- se agrego un dialogo operativo para aplicar politicas de retencion y crear/liberar `legal holds`.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\packages\feature_records\lib\src\domain\records_overview.dart`
- `C:\IA\codex\client\packages\feature_records\lib\src\domain\records_repository.dart`
- `C:\IA\codex\client\packages\feature_records\lib\src\application\records_view_model.dart`
- `C:\IA\codex\client\packages\feature_records\lib\src\presentation\records_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_records_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\records\application\records_item_management_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\records\presentation\records_item_management_dialog.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion de administracion y auditoria

Se completo otra capa real del modulo admin:
- backend con lectura de eventos recientes de auditoria a nivel plataforma y organización;
- dashboard admin con organizaciónes recientes y actividad auditada real;
- alta de organización desde la UI para `PLATFORM_ADMIN`;
- listado y alta basica de usuarios dla organización actual desde la UI para perfiles con gobierno de identidades;
- asignacion de roles a usuarios existentes desde la misma UI, reutilizando el endpoint scoped a organización del backend.

Endpoints nuevos:
- `GET /api/audit/events/recent`
- `GET /api/organization/audit/events/recent`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Audit\AuditEventService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\AuditController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresAuditEventRepository.cs`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\create_organization_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\identity_management_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\assign_user_role_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\organization_user_card.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\application\create_organization_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\application\identity_management_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_admin_repository.dart`
- `C:\IA\codex\client\packages\feature_admin\lib\src\presentation\admin_dashboard_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion de trazabilidad documental visible

Se amplio la trazabilidad operativa del nucleo documental:
- endpoint scoped a organización para consultar auditoria reciente por documento;
- detalle Flutter enriquecido con historial de eventos recientes del documento;
- continuidad de administracion de identidades con asignacion de roles a usuarios ya existentes desde la UI.

Endpoint nuevo:
- `GET /api/organization/documents/{documentId}/audit-events`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Api\Controllers\AuditController.cs`
- `C:\IA\codex\server\src\Gdms.Application\Audit\AuditEventService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Persistence\IAuditEventRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresAuditEventRepository.cs`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\assign_user_role_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\organization_user_card.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\presentation\identity_management_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\admin\application\identity_management_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\domain\document_audit_event.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_audit_trail_section.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_details_view_model.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion del modulo audit

Se incorporo un bounded context nuevo en Flutter:
- paquete `feature_audit` agregado al workspace;
- shell principal extendida con seccion dedicada de auditoria;
- consumo real de endpoints de auditoria de plataforma o organización segun el rol autenticado;
- quality gates actualizados para validar tambien el nuevo modulo.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\packages\feature_audit\lib\feature_audit.dart`
- `C:\IA\codex\client\packages\feature_audit\lib\src\application\audit_overview_view_model.dart`
- `C:\IA\codex\client\packages\feature_audit\lib\src\domain\audit_event_item.dart`
- `C:\IA\codex\client\packages\feature_audit\lib\src\domain\audit_overview.dart`
- `C:\IA\codex\client\packages\feature_audit\lib\src\domain\audit_repository.dart`
- `C:\IA\codex\client\packages\feature_audit\lib\src\presentation\audit_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_audit_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\pubspec.yaml`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_audit`.

## Avance nuevo incorporado en la iteracion del modulo workflow

Se incorporo la primera capa real de workflow documental:
- backend scoped a organización para listar, crear y completar tareas documentales simples;
- script relacional para `workflow.workflow_tasks`;
- shell Flutter extendida con modulo `feature_workflow`;
- dialogo de alta de tarea con seleccion de documento, notas y vencimiento;
- cierre de tareas desde la UI y recarga de la cola operativa.

Endpoints nuevos:
- `GET /api/organization/workflow/tasks`
- `POST /api/organization/workflow/tasks`
- `POST /api/organization/workflow/tasks/{taskId}/complete`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Domain\Workflow\WorkflowTask.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Workflow\WorkflowTaskStatus.cs`
- `C:\IA\codex\server\src\Gdms.Application\Workflow\WorkflowService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Persistence\IWorkflowTaskRepository.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\WorkflowController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresWorkflowTaskRepository.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Workflow\CreateWorkflowTaskRequest.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Workflow\WorkflowTaskResponse.cs`
- `C:\IA\codex\database\scripts\009_workflow_tasks.sql`
- `C:\IA\codex\client\packages\feature_workflow\lib\feature_workflow.dart`
- `C:\IA\codex\client\packages\feature_workflow\lib\src\presentation\workflow_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\workflow\presentation\create_workflow_task_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\workflow\application\create_workflow_task_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_workflow_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_workflow`.

## Avance nuevo incorporado en la iteracion del modulo search

Se incorporo un bounded context nuevo en Flutter para busqueda:
- paquete `feature_search` agregado al workspace;
- shell principal extendida con seccion dedicada de busqueda documental;
- consumo real del endpoint scoped a organización `/documents/search`;
- apertura del detalle documental desde resultados de busqueda;
- quality gates actualizados para validar tambien el nuevo modulo.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\packages\feature_search\lib\feature_search.dart`
- `C:\IA\codex\client\packages\feature_search\lib\src\application\search_view_model.dart`
- `C:\IA\codex\client\packages\feature_search\lib\src\domain\search_overview.dart`
- `C:\IA\codex\client\packages\feature_search\lib\src\domain\search_repository.dart`
- `C:\IA\codex\client\packages\feature_search\lib\src\domain\search_result_item.dart`
- `C:\IA\codex\client\packages\feature_search\lib\src\presentation\search_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_search_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\client\apps\gdms_app\pubspec.yaml`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_search`.

## Avance nuevo incorporado en la iteracion del modulo config y Firebase

Se incorporo la primera capa real de configuracion dinamica:
- paquete `feature_config` agregado al workspace;
- shell principal extendida con seccion dedicada de configuracion;
- integracion segura con `Firebase Remote Config` para flags no sensibles;
- integracion segura con `Cloud Firestore` para preferencias no relacionales por usuario;
- fallback local cuando Firebase todavia no esta provisionado en el entorno;
- `feature_search` ya usa Remote Config para resolver el limite de resultados.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\packages\feature_config\lib\feature_config.dart`
- `C:\IA\codex\client\packages\feature_config\lib\src\application\config_view_model.dart`
- `C:\IA\codex\client\packages\feature_config\lib\src\domain\config_overview.dart`
- `C:\IA\codex\client\packages\feature_config\lib\src\domain\config_repository.dart`
- `C:\IA\codex\client\packages\feature_config\lib\src\presentation\config_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\config\application\firebase_runtime_state.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\firebase_config_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_search_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_app.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\client\apps\gdms_app\pubspec.yaml`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_config`.

## Avance nuevo incorporado en la iteracion del modulo notifications

Se incorporo un inbox operativo transversal:
- backend scoped a organización para notificaciones accionables;
- agregacion sobre workflow, records y auditoria de seguridad existentes;
- paquete `feature_notifications` agregado al workspace;
- shell principal extendida con seccion dedicada de notificaciones.

Endpoint nuevo:
- `GET /api/organization/notifications`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Notifications\NotificationItem.cs`
- `C:\IA\codex\server\src\Gdms.Application\Notifications\NotificationsService.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Notifications\NotificationResponse.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\NotificationsController.cs`
- `C:\IA\codex\client\packages\feature_notifications\lib\feature_notifications.dart`
- `C:\IA\codex\client\packages\feature_notifications\lib\src\presentation\notifications_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_notifications_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_notifications`.

## Avance nuevo incorporado en la iteracion del vertical sector_legal

Se inicio el primer vertical sectorial de frontend:
- paquete `feature_sector_legal` agregado al workspace;
- tablero juridico construido sobre workflow, records y auditoria;
- metricas iniciales para tareas abiertas, evidencia bajo revision e incidentes de seguridad;
- shell principal extendida con seccion dedicada `Legal`.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\packages\feature_sector_legal\lib\feature_sector_legal.dart`
- `C:\IA\codex\client\packages\feature_sector_legal\lib\src\application\legal_dashboard_view_model.dart`
- `C:\IA\codex\client\packages\feature_sector_legal\lib\src\presentation\legal_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_legal_dashboard_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\client\apps\gdms_app\pubspec.yaml`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_sector_legal`.

## Avance nuevo incorporado en la iteracion de verticales inmobiliario y corporativo

Se incorporaron dos verticales sectoriales nuevos en Flutter:
- paquete `feature_sector_real_estate` agregado al workspace;
- paquete `feature_sector_corporate` agregado al workspace;
- shell principal extendida con secciones dedicadas para `Inmobiliario` y `Corporativo`;
- tableros compuestos sobre datos reales de documentos, workflow y notificaciones;
- quality gates actualizados y validados con ambos modulos.

Archivos principales nuevos o modificados:
- `C:\IA\codex\client\packages\feature_sector_real_estate\lib\feature_sector_real_estate.dart`
- `C:\IA\codex\client\packages\feature_sector_real_estate\lib\src\presentation\real_estate_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_real_estate_dashboard_repository.dart`
- `C:\IA\codex\client\packages\feature_sector_corporate\lib\feature_sector_corporate.dart`
- `C:\IA\codex\client\packages\feature_sector_corporate\lib\src\presentation\corporate_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_corporate_dashboard_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_sector_real_estate` y `feature_sector_corporate`.

## Avance nuevo incorporado en la iteracion del modulo signature

Se incorporo la primera capa real de firma documental:
- backend scoped a organización para listar, crear y completar solicitudes de firma;
- esquema PostgreSQL nuevo para `signature.signature_envelopes`;
- auditoria para `SIGNATURE_REQUESTED` y `SIGNATURE_COMPLETED`;
- inbox de notificaciones ampliado con alertas de firma pendiente;
- paquete `feature_signature` agregado al workspace;
- shell principal extendida con seccion dedicada de firma documental;
- dialogo Flutter para crear solicitudes de firma sobre documentos recientes;
- cierre de solicitudes desde la UI y quality gates actualizados.

Endpoints nuevos:
- `GET /api/organization/signature/envelopes`
- `POST /api/organization/signature/envelopes`
- `POST /api/organization/signature/envelopes/{envelopeId}/complete`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Domain\Signatures\SignatureEnvelope.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Signatures\SignatureEnvelopeStatus.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Persistence\ISignatureEnvelopeRepository.cs`
- `C:\IA\codex\server\src\Gdms.Application\Signatures\SignatureService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\SignaturesController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresSignatureEnvelopeRepository.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Signature\CreateSignatureEnvelopeRequest.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Signature\CompleteSignatureEnvelopeRequest.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Signature\SignatureEnvelopeResponse.cs`
- `C:\IA\codex\database\scripts\010_signature_envelopes.sql`
- `C:\IA\codex\client\packages\feature_signature\lib\feature_signature.dart`
- `C:\IA\codex\client\packages\feature_signature\lib\src\presentation\signature_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_signature_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\signature\presentation\create_signature_request_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_signature`.

## Avance nuevo incorporado en la iteracion del modulo integrations y hooks de firma

Se incorporo una nueva capa de integraciones y se preparo firma para proveedores externos:
- backend scoped a organización para listar el estado de integraciones configuradas;
- puerto `ISignatureProviderGateway` agregado para desacoplar firma de futuros proveedores PKI;
- adaptador `InternalSignatureProviderGateway` agregado como placeholder productivo para entornos sin proveedor externo;
- configuracion nueva `SignatureProvider` en `appsettings`;
- paquete `feature_integrations` agregado al workspace;
- shell principal extendida con seccion dedicada de integraciones;
- dashboard Flutter con estado de PostgreSQL, Firebase, storage y proveedor de firma.

Endpoint nuevo:
- `GET /api/organization/integrations/status`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Integrations\ISignatureProviderGateway.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Integrations\IIntegrationStatusCatalogProvider.cs`
- `C:\IA\codex\server\src\Gdms.Application\Integrations\IntegrationsService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\IntegrationsController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Integrations\InternalSignatureProviderGateway.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Integrations\ConfiguredIntegrationStatusCatalogProvider.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Configuration\SignatureProviderOptions.cs`
- `C:\IA\codex\server\src\Gdms.Application\Signatures\SignatureService.cs`
- `C:\IA\codex\server\src\Gdms.Api\appsettings.json`
- `C:\IA\codex\server\src\Gdms.Api\appsettings.Development.json`
- `C:\IA\codex\client\packages\feature_integrations\lib\feature_integrations.dart`
- `C:\IA\codex\client\packages\feature_integrations\lib\src\presentation\integrations_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_integrations_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_home_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde, incluyendo `feature_integrations`.

## Avance nuevo incorporado en la iteracion de exportacion probatoria

Se incorporo una primera capa real de exportacion de evidencia documental:
- backend scoped a organización para construir y descargar paquetes de evidencia por documento;
- consolidacion de versiones, metadatos, auditoria, workflow, firmas y legal holds en un JSON exportable;
- auditoria del evento `EVIDENCE_PACKAGE_EXPORTED`;
- boton nuevo en el detalle documental Flutter para descargar el paquete probatorio.

Endpoint nuevo:
- `GET /api/organization/documents/{documentId}/evidence-package`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Evidence\DocumentEvidencePackage.cs`
- `C:\IA\codex\server\src\Gdms.Application\Evidence\DocumentEvidencePackageService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\EvidencePackagesController.cs`
- `C:\IA\codex\server\src\Gdms.Application\DependencyInjection.cs`
- `C:\IA\codex\server\tests\Gdms.ArchitectureTests\SolutionSmokeTests.cs`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_details_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_actions_bar.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion de expedientes y vínculo jurídico

Se incorporó una capa operativa real para expedientes del vertical legal:
- backend scoped a organización para crear y listar expedientes;
- persistencia PostgreSQL nueva para `documents.case_files`;
- vínculo documento-expediente con integridad referencial en `documents.case_file_documents`;
- auditoría del evento `CASE_FILE_CREATED` y `CASE_FILE_DOCUMENT_ATTACHED`;
- botón nuevo en detalle documental para vincular un documento a un expediente;
- dashboard legal extendido con expedientes recientes navegables;
- diálogo de expediente con listado de documentos vinculados y apertura del detalle documental.

Endpoints nuevos:
- `GET /api/organization/cases`
- `POST /api/organization/cases`
- `GET /api/organization/cases/{caseFileId}/documents`
- `POST /api/organization/cases/{caseFileId}/documents`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Domain\Cases\CaseFile.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Cases\CaseFileDocumentLink.cs`
- `C:\IA\codex\server\src\Gdms.Application\Cases\CaseFileService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Abstractions\Persistence\ICaseFileRepository.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\CaseFilesController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresCaseFileRepository.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Cases\CreateCaseFileRequest.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Cases\AttachDocumentToCaseFileRequest.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Cases\CaseFileResponse.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Cases\CaseFileDocumentResponse.cs`
- `C:\IA\codex\database\scripts\011_case_files.sql`
- `C:\IA\codex\database\scripts\012_case_file_document_links.sql`
- `C:\IA\codex\client\packages\feature_sector_legal\lib\src\presentation\legal_dashboard_page.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\legal\presentation\create_case_file_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\legal\presentation\link_document_to_case_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\legal\presentation\case_file_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_actions_bar.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_authenticated_shell.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\app\gdms_root_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion de versionado documental operativo

Se fortaleció el núcleo ECM con versionado real:
- backend scoped a organización para subir una nueva versión sobre un documento existente;
- endpoint para consultar historial de versiones por documento;
- endpoint para descargar una versión específica, además de la última;
- refactor interno para separar `DocumentService` de `DocumentContentService` y mantener el límite de 300 líneas;
- UI Flutter para subir nuevas versiones desde el detalle documental;
- historial visible de versiones con descarga puntual desde la misma pantalla.

Endpoints nuevos:
- `POST /api/organization/documents/{documentId}/versions/upload`
- `GET /api/organization/documents/{documentId}/versions`
- `GET /api/organization/documents/{documentId}/versions/{versionNumber}/download`

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Documents\DocumentContentService.cs`
- `C:\IA\codex\server\src\Gdms.Application\Documents\DocumentService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\DocumentContentController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\DocumentsController.cs`
- `C:\IA\codex\server\src\Gdms.Api\Models\Documents\UploadDocumentVersionForm.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Documents\DocumentVersionResponse.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresDocumentRepository.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresDocumentRepository.Helpers.cs`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_version_upload_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_details_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\upload_document_version_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_version_history_section.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_actions_bar.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\validate_workspace.ps1`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde.

## Avance nuevo incorporado en la iteracion de firma documental contextual y cancelacion

Se completo la integracion de firma directamente dentro del detalle documental:
- el detalle documental ya lista solicitudes de firma asociadas al documento actual;
- desde el detalle se pueden crear solicitudes con documento preseleccionado;
- desde el detalle se pueden completar solicitudes pendientes;
- el endpoint `GET /api/organization/signature/envelopes` ahora acepta `documentId` opcional para filtrar por documento.

Se amplio ademas el ciclo de vida de firma con cancelacion controlada:
- nuevo estado `CANCELLED` en firma documental;
- persistencia PostgreSQL extendida con `cancelled_by_user_id`, `cancelled_at_utc` y `cancellation_reason`;
- endpoint nuevo `POST /api/organization/signature/envelopes/{envelopeId}/cancel`;
- auditoria nueva `SIGNATURE_CANCELLED`;
- dashboard de firma y detalle documental ya permiten cancelar solicitudes pendientes con motivo.

Se incorporo tambien visibilidad operativa en reportes:
- reportes organización y plataforma ahora incluyen el KPI `cancelledSignatures`;
- el dashboard Flutter de reportes muestra firmas canceladas junto a pendientes, workflow y disposición.

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Domain\Signatures\SignatureEnvelope.cs`
- `C:\IA\codex\server\src\Gdms.Domain\Signatures\SignatureEnvelopeStatus.cs`
- `C:\IA\codex\server\src\Gdms.Application\Signatures\SignatureService.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\SignaturesController.cs`
- `C:\IA\codex\server\src\Gdms.Infrastructure\Persistence\PostgresSignatureEnvelopeRepository.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Signature\CancelSignatureEnvelopeRequest.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Signature\SignatureEnvelopeResponse.cs`
- `C:\IA\codex\server\src\Gdms.Application\Reports\ReportsService.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Reports\OperationalReportResponse.cs`
- `C:\IA\codex\server\src\Gdms.Contracts\Reports\PlatformReportResponse.cs`
- `C:\IA\codex\server\src\Gdms.Api\Controllers\ReportsController.cs`
- `C:\IA\codex\server\src\Gdms.Application\Reports\OperationalReportSummary.cs`
- `C:\IA\codex\server\src\Gdms.Application\Reports\PlatformReportSummary.cs`
- `C:\IA\codex\database\scripts\010_signature_envelopes.sql`
- `C:\IA\codex\database\scripts\019_signature_cancellation.sql`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\application\document_signatures_view_model.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_signature_requests_section.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\documents\presentation\document_details_dialog_actions.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_signature_repository.dart`
- `C:\IA\codex\client\apps\gdms_app\lib\src\infrastructure\repositories\api_reports_repository.dart`
- `C:\IA\codex\client\packages\feature_signature\lib\src\presentation\signature_dashboard_page.dart`
- `C:\IA\codex\client\packages\feature_reports\lib\src\presentation\reports_dashboard_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\check_line_limits.ps1`
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`
- `flutter analyze` en `C:\IA\codex\client\apps\gdms_app`
- `flutter test` en `C:\IA\codex\client\apps\gdms_app`
- `flutter analyze` en `C:\IA\codex\client\packages\feature_signature`
- `flutter test` en `C:\IA\codex\client\packages\feature_signature`
- `flutter analyze` en `C:\IA\codex\client\packages\feature_reports`
- `flutter test` en `C:\IA\codex\client\packages\feature_reports`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde para app, firma y reportes.

## Avance nuevo incorporado en la iteracion de notificaciones de firma cancelada

Se extendio el inbox operativo para reflejar cancelaciones recientes de firma:
- las notificaciones scoped a organización ahora incluyen solicitudes de firma canceladas en los ultimos 7 dias;
- se conserva tambien la visibilidad de firmas pendientes con vencimiento;
- la UI del inbox ya comunica que cubre tareas, records, firmas y alertas de seguridad.

Archivos principales nuevos o modificados:
- `C:\IA\codex\server\src\Gdms.Application\Notifications\NotificationsService.cs`
- `C:\IA\codex\client\packages\feature_notifications\lib\src\presentation\notifications_dashboard_page.dart`

Validacion realizada:
- `powershell -ExecutionPolicy Bypass -File C:\IA\codex\scripts\quality\check_line_limits.ps1`
- `dotnet build C:\IA\codex\server\Gdms.sln`
- `dotnet test C:\IA\codex\server\Gdms.sln`
- `flutter analyze` en `C:\IA\codex\client\apps\gdms_app`
- `flutter test` en `C:\IA\codex\client\apps\gdms_app`
- `flutter analyze` en `C:\IA\codex\client\packages\feature_notifications`
- `flutter test` en `C:\IA\codex\client\packages\feature_notifications`

Resultado:
- backend build y test en verde;
- frontend analyze y test en verde;
- quality gates en verde para app y notificaciones.

## Limitaciones detectadas en la maquina anterior

- Docker Desktop no pudo instalarse o no estaba disponible.
- En un momento el entorno local tenia solo SDK `.NET 7`, por eso `dotnet build` fallaba contra `net10.0` con `NETSDK1045`.
- No se pudo validar contenedores localmente por falta de Docker.

## Programas ya instalados por el usuario en la maquina anterior

El usuario informo que ya tenia instalados:
- `Microsoft.DotNet.SDK.10` `10.0.201`
- `Git.Git` `2.53.0.2`
- `Microsoft.VisualStudioCode` `1.112.0`
- `OpenJS.NodeJS.LTS` `24.14.0`
- `Google.AndroidStudio` `2025.3.1.8`
- `Microsoft.OpenJDK.21` `21.0.10.7`
- `Google.PlatformTools` `37.0.0`
- `pingbird.Puro` `1.5.0`
- `Google.FirebaseCLI` `20.18.2`
- `DBeaver.DBeaver.Community` `26.0.0`
- `Microsoft.PowerShell` `7.6.0.0`

## Scripts de setup guardados

Se guardaron scripts PowerShell por fases en:
- `C:\IA\codex\scripts\setup\windows\01-system-prereqs.ps1`
- `C:\IA\codex\scripts\setup\windows\02-install-core-dev-tools.ps1`
- `C:\IA\codex\scripts\setup\windows\03-post-install-docker.ps1`
- `C:\IA\codex\scripts\setup\windows\README.md`
- `C:\IA\codex\scripts\setup\windows\10-base-config.ps1`
- `C:\IA\codex\scripts\setup\windows\11-flutter-android-setup.ps1`
- `C:\IA\codex\scripts\setup\windows\12-vscode-extensions.ps1`
- `C:\IA\codex\scripts\setup\windows\13-local-postgres-optional.ps1`
- `C:\IA\codex\scripts\setup\windows\14-verify-environment.ps1`
- `C:\IA\codex\scripts\setup\windows\15-workspace-bootstrap.ps1`
- `C:\IA\codex\scripts\setup\windows\16-run-gdms-docker.ps1`
- `C:\IA\codex\scripts\setup\windows\17-stop-gdms-docker.ps1`
- `C:\IA\codex\scripts\setup\windows\18-codex-bootstrap-prompt.md`
- `C:\IA\codex\scripts\setup\windows\18-copy-codex-bootstrap-prompt.ps1`

Guia adicional para migracion con Docker:
- `C:\IA\codex\docs\migracion_nueva_pc_windows_docker.md`

## Quality gates y CI

Se agregaron validaciones reutilizables para el workspace:
- `C:\IA\codex\scripts\quality\check_line_limits.ps1`
- `C:\IA\codex\scripts\quality\validate_workspace.ps1`
- `C:\IA\codex\.github\workflows\ci.yml`

Cobertura actual del pipeline:
- control de archivos `.cs` y `.dart` por debajo de 300 lineas;
- `dotnet build`;
- `dotnet test`;
- `flutter analyze`;
- `flutter test`.

## Proximo paso recomendado al retomar en otra maquina

1. Abrir este workspace en la nueva maquina.
2. Ejecutar los scripts de `C:\IA\codex\scripts\setup\windows`.
3. Confirmar resultado de `flutter doctor`.
4. Confirmar si PostgreSQL 18 quedo instalado localmente.
5. Retomar desarrollo con una de estas prioridades:
- integrar `Firebase Remote Config` y `Cloud Firestore` con limites claros de ownership;
- ampliar consulta/edicion documental con metadata completa, descarga y acciones por documento;
- agregar busqueda, workflow, audit, signature e integraciones en frontend;
- agregar guardado/descarga amigable de archivos en cliente final;
- ampliar metadata, taxonomias y permisos documentales finos;
- ampliar records con legal holds, politicas de retencion y trazabilidad operativa desde UI;
- ampliar admin con endpoints reales de auditoria y plataforma;
- ampliar admin con asignacion de roles a usuarios ya existentes y gestion mas rica de organizaciónes;
- ampliar verticales de frontend faltantes: search, workflow, audit, signature e integraciones;
- integrar Firebase Remote Config y Cloud Firestore segun ownership definido;
- avanzar el modulo `signature` hacia hooks reales de proveedor PKI/sellado temporal;
- sumar `feature_integrations` y `feature_signature` avanzada con evidencia externa;
- adaptacion completa para correr sin Docker.

## Nota de continuidad

Si se pierde el contexto del chat, este archivo debe usarse como punto de reingreso para continuar el desarrollo sin depender de la conversacion previa.




