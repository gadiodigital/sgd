# Estructura Documental Configurable

Este modulo incorpora al GDMS el patron principal descrito en `C:\IA\SGD\contexto.md`: proyectos documentales con jerarquia flexible de contenedores.

## Alcance Implementado

- Proyectos documentales dentro de una organización.
- Tipos de contenedor por proyecto.
- Esquema JSON de atributos por tipo de contenedor.
- Reglas padre-hijo entre tipos de contenedor.
- Nodos concretos dentro del arbol jerarquico.
- Validacion de raiz y reglas padre-hijo en backend y PostgreSQL.
- Vinculo entre nodos que aceptan documentos y documentos existentes.
- Pantalla Flutter `Estructura` en `gdms_app`.

## Modelo De Datos

La migracion aditiva esta en:

- `database/scripts/020_document_structure_hierarchy.sql`
- `database/updates/update_document_structure_hierarchy.sql` para aplicar la actualizacion sobre una base existente con `psql`.
- `scripts/ops/apply_document_structure_db_update.ps1` para aplicar la actualizacion sobre el PostgreSQL de Docker sin requerir `psql` local.

Tablas principales:

- `documents.projects`
- `configuration.container_types`
- `configuration.container_type_rules`
- `documents.containers`
- `documents.container_documents`

El modelo usa `organization_id` y `project_id` para mantener aislamiento logico. PostgreSQL tambien valida:

- que un tipo no raiz no pueda crearse como nodo raiz;
- que un hijo solo pueda colgar de un padre permitido por regla;
- que un nodo solo reciba documentos si su tipo tiene `accepts_documents = true`;
- que el documento vinculado pertenezca al mismo organización.

## Actualizacion En Docker Local

Con el stack levantado:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ops\apply_document_structure_db_update.ps1
```

El script aplica `020_document_structure_hierarchy.sql` dentro del servicio `postgres` y verifica que existan las tablas, funciones y triggers esperados.

## API

Base:

```text
/api/organization/structure/projects
```

Endpoints principales:

```text
GET  /api/organization/structure/projects
POST /api/organization/structure/projects

GET  /api/organization/structure/projects/{projectId}/container-types
POST /api/organization/structure/projects/{projectId}/container-types

GET  /api/organization/structure/projects/{projectId}/container-type-rules
POST /api/organization/structure/projects/{projectId}/container-type-rules

GET  /api/organization/structure/projects/{projectId}/containers
GET  /api/organization/structure/projects/{projectId}/tree
POST /api/organization/structure/projects/{projectId}/containers

GET  /api/organization/structure/projects/{projectId}/containers/{containerId}/documents
POST /api/organization/structure/projects/{projectId}/containers/{containerId}/documents
```

## UI

En `gdms_app` se agrego la seccion `Estructura`.

Permite:

- crear proyecto documental;
- crear tipos de contenedor;
- crear reglas padre-hijo;
- crear nodos con atributos tipados generados desde el esquema del tipo de contenedor;
- seleccionar nodos;
- vincular documentos existentes cuando el tipo del nodo acepta documentos.
- subir o escanear documentos desde el nodo seleccionado y vincularlos automaticamente.

## Decisiones

- No se copio `sgd_api` ni `ui_sgd`; se absorbio el concepto dentro de GDMS.
- Los atributos dinamicos se modelan como `metadata_schema` JSONB, igual que los tipos documentales actuales de GDMS.
- El modelo relacional tipado de atributos de SGD puede incorporarse despues con una migracion expand/migrate/contract si se requiere validacion SQL campo por campo.

## Siguiente Paso Recomendado

Completar escenarios automatizados end-to-end con PostgreSQL real para cubrir creacion de proyecto, jerarquia, carga documental y vinculo al nodo.



