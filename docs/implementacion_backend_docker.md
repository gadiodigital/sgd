# Implementación Backend y Despliegue con Docker

## Objetivo

Poner en marcha la base del backend del sistema de gestión documental con:

- API `.NET` modular.
- Swagger visible desde el arranque.
- PostgreSQL con scripts iniciales.
- Configuración y datos no relacionales previstos para Firebase.
- Base documental compatible con comentarios XML para documentación automática.

## Estructura creada

- `server/`
  - solución `.NET`
  - API HTTP
  - capas `Application`, `Domain`, `Infrastructure`, `Contracts`
- `client/`
  - workspace Flutter modular
  - app `gdms_app`
  - paquetes `core`, `design_system`, `feature_auth`, `feature_documents`, `feature_records`, `feature_admin`
- `database/scripts/`
  - scripts de bootstrap PostgreSQL
- `docker-compose.yml`
  - API + PostgreSQL
- `docs/`
  - guías de implementación y documentación

## Paso a paso recomendado

### 1. Instalar herramientas base

- Docker Desktop o motor Docker compatible.
- Acceso a un proyecto Firebase para `Remote Config` y `Cloud Firestore`.
- SDK `.NET 10` si se quiere compilar fuera de contenedores.
- La solución fija el SDK esperado en `server/global.json`.

### 2. Revisar configuración

Validar antes del primer arranque:

- `server/src/Gdms.Api/appsettings.json`
- `server/src/Gdms.Api/appsettings.Development.json`
- variables de entorno en `docker-compose.yml`

Puntos clave:

- `Postgres__MainDatabase`
- `Firebase__ProjectId`
- `Firebase__UseEmulator`
- `Firebase__RemoteConfigTemplateName`
- `Jwt__Issuer`
- `Jwt__Audience`
- `Jwt__SigningKey`
- `Jwt__AccessTokenMinutes`

### 3. Levantar los servicios

Desde la raíz del workspace:

```powershell
docker compose up --build
```

Resultado esperado:

- PostgreSQL inicia y ejecuta los scripts de `database/scripts`.
- La API compila dentro de la imagen `.NET 10`.
- Swagger queda visible en `http://localhost:8080/swagger`.

### 4. Probar endpoints base

Endpoints iniciales expuestos:

- `GET /api/health`
- `GET /api/organization`
- `POST /api/organization`
- `GET /api/organization/documents`
- `GET /api/organization/documents/{documentId}`
- `GET /api/organization/documents/{documentId}/metadata`
- `PUT /api/organization/documents/{documentId}/metadata`
- `POST /api/organization/documents`
- `POST /api/organization/documents/upload`
- `GET /api/organization/documents/{documentId}/download`
- `POST /api/organization/documents/{documentId}/versions/upload`
- `GET /api/organization/documents/{documentId}/versions`
- `GET /api/organization/documents/{documentId}/versions/{versionNumber}/download`
- `GET /api/organization/documents/search`
- `GET /api/organization/cases`
- `POST /api/organization/cases`
- `GET /api/organization/cases/{caseFileId}/documents`
- `POST /api/organization/cases/{caseFileId}/documents`
- `GET /api/organization/signature/envelopes`
- `POST /api/organization/signature/envelopes`
- `POST /api/organization/signature/envelopes/{envelopeId}/complete`
- `POST /api/organization/signature/envelopes/{envelopeId}/cancel`
- `GET /api/organization/property-files`
- `POST /api/organization/property-files`
- `GET /api/organization/property-files/{propertyFileId}/documents`
- `POST /api/organization/property-files/{propertyFileId}/documents`
- `GET /api/organization/corporate-record-files`
- `POST /api/organization/corporate-record-files`
- `GET /api/organization/corporate-record-files/{corporateRecordFileId}/documents`
- `POST /api/organization/corporate-record-files/{corporateRecordFileId}/documents`
- `GET /api/organization/documents/{documentId}/access-entries`
- `POST /api/organization/documents/{documentId}/access-entries`
- `GET /api/organization/document-types`
- `GET /api/roles`
- `GET /api/organization/users`
- `GET /api/organization/users/{userId}`
- `POST /api/organization/users`
- `POST /api/organization/users/{userId}/roles`
- `POST /api/auth/bootstrap-platform-admin`
- `POST /api/auth/bootstrap-organization-admin`
- `POST /api/auth/token`
- `GET /api/auth/me`
- `GET /api/organization/records/retention-policies`
- `POST /api/organization/records/documents/{documentId}/retention-policy`
- `GET /api/organization/records/documents/{documentId}/legal-holds`
- `POST /api/organization/records/documents/{documentId}/legal-holds`
- `POST /api/organization/records/legal-holds/{legalHoldId}/release`

### 5. Validar base de datos

Conectarse a PostgreSQL y revisar:

- `platform.organizations`
- `identity.users`
- `identity.roles`
- `configuration.document_types`
- `records.retention_policies`
- `documents.documents`
- `documents.document_versions`
- `documents.case_files`
- `documents.case_file_documents`
- `documents.property_files`
- `documents.property_file_documents`
- `documents.corporate_record_files`
- `documents.corporate_record_file_documents`
- `documents.document_access_entries`
- `documents.document_metadata`
- `records.legal_holds`
- `audit.audit_events`

### 6. Completar la siguiente iteración técnica

Backlog inmediato sugerido:

1. Conectar el frontend Flutter con autenticación JWT y endpoints reales.
2. Integrar `Firebase Remote Config`.
3. Integrar `Cloud Firestore` para proyecciones y configuraciones extendidas.
4. Agregar migraciones versionadas y pipeline CI/CD.
5. Completar verticales faltantes del frontend: workflow, audit, signature e integraciones.
6. Llevar el storage binario desde filesystem local a backend `S3-compatible`.

## Decisiones técnicas tomadas

- `PostgreSQL` es la fuente de verdad relacional.
- `Firebase Remote Config` se reserva para configuración dinámica no sensible.
- `Cloud Firestore` se reserva para datos no relacionales y proyecciones.
- Swagger debe estar habilitado también en el baseline inicial, no solo en desarrollo local.
- La documentación fuente nace en comentarios XML de C# para reutilizarse en Swagger y en la herramienta documental elegida.

## Limitaciones de esta iteración

- La persistencia real ya cubre organizaciones, documentos, usuarios, roles, credenciales locales, metadatos documentales y records management base.
- La persistencia real ya cubre expedientes scoped a organización y vínculo expediente-documento para el vertical jurídico.
- La persistencia real ya cubre legajos inmobiliarios y vínculo legajo-documento.
- La persistencia real ya cubre legajos corporativos y vínculo legajo-documento.
- El núcleo documental ya soporta ACL documentales explícitas con enforcement sobre lectura, descarga, metadata y versionado.
- La búsqueda documental ya soporta filtros por tipo documental, estado y presencia de `legal hold`.
- Workflow ya soporta asignación opcional de responsable y consulta `mine=true` para listar solo tareas asignadas al usuario actual.
- El frontend ya integra workflow directamente dentro del detalle documental para crear y completar tareas contextualizadas.
- Firma documental ya soporta filtrado opcional por `documentId`, cancelación controlada y operación contextual desde el detalle del documento.
- El núcleo documental ya soporta versionado operativo con upload de nueva versión e historial descargable por versión.
- La auditoría ya registra lectura, alta documental, búsquedas, descargas, lectura/edición de metadatos y operaciones iniciales de records management.
- La máquina actual no tiene Docker instalado, por lo que el build final en contenedores debe validarse en un entorno compatible.
- Firebase quedó preparado por configuración, no integrado todavía a nivel de runtime.
- El frontend Flutter ya tiene shell modular, pruebas, convención Gradle Android y capa HTTP real para auth, documents, records y parte de admin.





