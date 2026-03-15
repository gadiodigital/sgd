# Propuesta inicial de base de datos

## Estado

Esta propuesta ya fue aterrizada parcialmente en la implementación real de la `v1`.

La fuente técnica concreta para la base inicial hoy es:

- [V202603151410__init_projects_hierarchy_v1.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603151410__init_projects_hierarchy_v1.sql)
- [V202603151730__extend_dynamic_attributes_v2.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603151730__extend_dynamic_attributes_v2.sql)

La principal corrección respecto de la versión conceptual inicial es esta:

- el esquema arrancó priorizando `proyectos` aislados y `jerarquías flexibles por proyecto`
- esa prioridad quedó por encima del modelo documental completo, porque es la primera necesidad real de la UI
- los atributos dinámicos quedaron extendidos para `contenedores` y `documentos` con validación tipada en base
- las opciones de atributos de tipo `list` ahora viven en `attribute_options`

## Objetivo

Definir una base mínima para empezar la interfaz visual del SGD sin cerrar decisiones que todavía pueden cambiar.

La idea es cubrir desde el día 1:

- ABM de tipos de documento.
- ABM de tipos de contenedor.
- Jerarquía flexible de contenedores.
- Alta y edición básica de documentos.
- Atributos dinámicos por tipo.
- Asociación entre documento lógico y archivo físico/digital.
- Capacidad de evolucionar luego a versionado fuerte, auditoría, permisos, workflow y búsqueda avanzada.

## Criterios de diseño

- Empezar simple, pero sin romper el crecimiento futuro.
- Separar configuración de catálogo de datos operativos.
- Soportar atributos dinámicos sin tener que alterar tablas por cada tipo nuevo.
- Mantener el documento lógico separado de sus archivos/versiones.
- Evitar meter workflow, firma digital, retención y permisos finos en la primera iteración.

## Motor recomendado

Para la base principal, usar `PostgreSQL`.

Motivos:

- maneja bien relaciones y jerarquías
- permite índices y constraints sólidos
- sirve tanto para un MVP como para una etapa más seria
- funciona bien con migraciones SQL versionadas
- deja abierta la puerta a `JSONB`, búsqueda y extensiones más adelante

## Alcance mínimo para arrancar la UI

La UI inicial debería poder hacer estas pantallas con esta base:

- listado de contenedores
- árbol o breadcrumb de contenedores
- alta/edición de tipos de documento
- alta/edición de tipos de contenedor
- alta/edición de documentos
- formulario dinámico de atributos según el tipo elegido
- detalle de documento con archivo principal y metadatos

No incluir todavía como requisito de esquema inicial:

- permisos granulares
- firma digital
- workflow completo
- comentarios
- auditoría forense completa
- OCR/indexación full-text
- links externos compartidos

## Modelo mínimo propuesto

## 1. Tabla de migraciones

### `schema_migrations`

Sirve para saber qué versión de esquema está aplicada.

Campos:

- `version` `varchar(64)` PK
- `name` `varchar(200)` not null
- `applied_at` `timestamptz` not null default `now()`
- `checksum` `varchar(128)` not null

## 2. Catálogos de tipos

### `document_types`

Define tipos de documento como `contrato`, `factura`, `recibo`.

Campos:

- `id` `uuid` PK
- `code` `varchar(80)` unique not null
- `name` `varchar(120)` not null
- `description` `text` null
- `is_active` `boolean` not null default `true`
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

### `container_types`

Define tipos físicos o lógicos como `caja`, `carpeta`, `bibliorato`.

Campos:

- `id` `uuid` PK
- `code` `varchar(80)` unique not null
- `name` `varchar(120)` not null
- `description` `text` null
- `is_active` `boolean` not null default `true`
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

## 3. Definición de atributos dinámicos

### `attribute_definitions`

Permite definir atributos para documentos o contenedores sin alterar el esquema.

Campos:

- `id` `uuid` PK
- `scope` `varchar(20)` not null
  Valores iniciales:
  - `document`
  - `container`
- `name` `varchar(120)` not null
- `code` `varchar(80)` not null
- `data_type` `varchar(30)` not null
  Valores iniciales:
  - `text`
  - `number`
  - `date`
  - `boolean`
  - `json`
- `is_required` `boolean` not null default `false`
- `is_multiple` `boolean` not null default `false`
- `default_value` `text` null
- `help_text` `text` null
- `is_active` `boolean` not null default `true`
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

Restricciones:

- unique `scope + code`

### `document_type_attributes`

Relaciona qué atributos aplica cada tipo de documento.

Campos:

- `document_type_id` `uuid` FK -> `document_types.id`
- `attribute_definition_id` `uuid` FK -> `attribute_definitions.id`
- `display_order` `int` not null default `0`

PK compuesta:

- `document_type_id`
- `attribute_definition_id`

### `container_type_attributes`

Relaciona qué atributos aplica cada tipo de contenedor.

Campos:

- `container_type_id` `uuid` FK -> `container_types.id`
- `attribute_definition_id` `uuid` FK -> `attribute_definitions.id`
- `display_order` `int` not null default `0`

PK compuesta:

- `container_type_id`
- `attribute_definition_id`

## 4. Jerarquía de contenedores

### `containers`

Representa la estructura física o lógica donde se ubican documentos.

Campos:

- `id` `uuid` PK
- `container_type_id` `uuid` FK -> `container_types.id`
- `parent_id` `uuid` FK -> `containers.id` null
- `code` `varchar(80)` null
- `name` `varchar(160)` not null
- `description` `text` null
- `location_note` `text` null
- `is_active` `boolean` not null default `true`
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

Índices recomendados:

- índice por `parent_id`
- índice por `container_type_id`
- índice único parcial por `parent_id, name` si queremos evitar duplicados entre hermanos

Decisión de jerarquía:

- arrancar con `adjacency list` usando `parent_id`
- no meter `nested sets` ni tabla de cierre todavía
- si luego la navegación o búsqueda jerárquica se vuelve costosa, migrar a:
  - `ltree`
  - closure table
  - materialized path

Para el MVP, `parent_id` alcanza y simplifica mucho la UI.

## 5. Documento lógico

### `documents`

Representa la entidad documental, independiente del archivo físico concreto.

Campos:

- `id` `uuid` PK
- `document_type_id` `uuid` FK -> `document_types.id`
- `container_id` `uuid` FK -> `containers.id` null
- `title` `varchar(240)` not null
- `description` `text` null
- `status` `varchar(30)` not null default `draft`
  Valores iniciales:
  - `draft`
  - `active`
  - `archived`
- `current_version_number` `int` not null default `1`
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

Notas:

- `container_id` es nullable para permitir documentos aún no ubicados físicamente.
- `status` es simple a propósito; el workflow real vendrá después.

## 6. Versiones del documento

### `document_versions`

Aunque el versionado completo puede crecer más adelante, conviene nacer con esta tabla para no acoplar el documento al archivo actual.

Campos:

- `id` `uuid` PK
- `document_id` `uuid` FK -> `documents.id`
- `version_number` `int` not null
- `source_type` `varchar(30)` not null
  Valores iniciales:
  - `upload`
  - `scan`
  - `generated`
- `notes` `text` null
- `created_at` `timestamptz` not null

Restricciones:

- unique `document_id + version_number`

Esto permite que la UI muestre:

- versión actual
- historial básico
- origen del archivo

Sin tener todavía control de aprobación, firmas o branchs.

## 7. Archivos de cada versión

### `document_files`

Guarda las referencias a los archivos físicos/digitales asociados a una versión.

Campos:

- `id` `uuid` PK
- `document_version_id` `uuid` FK -> `document_versions.id`
- `file_role` `varchar(30)` not null
  Valores iniciales:
  - `original`
  - `preview`
  - `pdf`
- `storage_path` `text` not null
- `original_name` `varchar(255)` not null
- `extension` `varchar(20)` null
- `mime_type` `varchar(120)` null
- `size_bytes` `bigint` null
- `checksum_sha256` `varchar(64)` null
- `page_count` `int` null
- `created_at` `timestamptz` not null

Restricciones:

- no hacer unique por `file_role` todavía
- una versión podría tener más de un archivo derivado

Notas:

- `storage_path` puede apuntar a disco local o storage externo.
- No acoplar el esquema a un proveedor puntual.

## 8. Valores de atributos para contenedores

### `container_attribute_values`

Campos:

- `id` `uuid` PK
- `container_id` `uuid` FK -> `containers.id`
- `attribute_definition_id` `uuid` FK -> `attribute_definitions.id`
- `value_text` `text` null
- `value_number` `numeric(18,4)` null
- `value_date` `date` null
- `value_boolean` `boolean` null
- `value_json` `jsonb` null
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

Restricciones:

- unique `container_id + attribute_definition_id`

## 9. Valores de atributos para documentos

### `document_attribute_values`

Campos:

- `id` `uuid` PK
- `document_id` `uuid` FK -> `documents.id`
- `attribute_definition_id` `uuid` FK -> `attribute_definitions.id`
- `value_text` `text` null
- `value_number` `numeric(18,4)` null
- `value_date` `date` null
- `value_boolean` `boolean` null
- `value_json` `jsonb` null
- `created_at` `timestamptz` not null
- `updated_at` `timestamptz` not null

Restricciones:

- unique `document_id + attribute_definition_id`

## Diagrama lógico resumido

```text
document_types
  └──< document_type_attributes >── attribute_definitions

container_types
  └──< container_type_attributes >── attribute_definitions

containers
  └── parent_id -> containers.id
  └──< container_attribute_values >── attribute_definitions

documents
  └── belongs to document_types
  └── belongs to containers
  └──< document_attribute_values >── attribute_definitions
  └──< document_versions
         └──< document_files
```

## Qué permite construir ya en la UI

Con este esquema mínimo se puede implementar:

- pantalla de administración de tipos de documento
- pantalla de administración de tipos de contenedor
- pantalla de árbol de contenedores
- formulario dinámico de alta de documento
- listado de documentos por contenedor
- ficha de documento
- historial básico de versiones
- vista de archivo principal y derivados

## Qué dejamos explícitamente para una fase siguiente

Para no sobredimensionar la primera base, estas piezas deberían entrar después:

- `users`, `roles`, `permissions`
- `audit_events`
- `tags`
- `retention_policies`
- `workflow_definitions`, `workflow_instances`, `workflow_tasks`
- `comments`
- `document_links` para compartición externa
- `ocr_jobs` y tabla de texto indexado
- multitenancy

## Estrategia de versionado y migración

La base va a cambiar. No hay que pelearse con eso; hay que diseñar para cambiar con control.

### Principios

- toda modificación de esquema entra por migración versionada
- nunca editar manualmente una base productiva como mecanismo normal
- las migraciones deben ser idempotentes cuando aplique y auditables siempre
- separar cambios de esquema de carga de datos semilla
- preferir cambios aditivos antes que destructivos

### Convención recomendada

Estructura:

```text
db/
  migrations/
    V202603151330__init_schema.sql
    V202603151400__add_document_status_index.sql
  seeds/
    S202603151430__basic_types.sql
```

Formato de versión:

- `VYYYYMMDDHHMM__descripcion.sql`

Metadatos registrados en `schema_migrations`:

- versión
- nombre
- checksum
- fecha de aplicación

### Estrategia de cambios

#### Cambios seguros

Primero permitir:

- agregar tablas
- agregar columnas nullable
- agregar índices
- agregar catálogos
- backfill de datos

Después, en otra migración:

- imponer `not null`
- agregar unique constraints
- borrar columnas viejas sólo cuando el código ya no dependa

#### Cambios peligrosos

Evitar en una sola release:

- renombrar y borrar a la vez
- cambiar semántica de columnas sin período de convivencia
- migraciones que bloqueen tablas grandes sin ventana controlada

### Patrón expand / migrate / contract

Para cambios futuros importantes:

1. `expand`
   agregar nueva tabla o columna sin romper el código actual
2. `migrate`
   copiar o recalcular datos y adaptar la aplicación
3. `contract`
   eliminar lo viejo en una release posterior

### Seeds iniciales

Separar datos semilla del esquema.

Semillas mínimas sugeridas:

- tipos de documento:
  - `contrato`
  - `factura`
  - `recibo`
- tipos de contenedor:
  - `caja`
  - `carpeta`
  - `bibliorato`

No llenar más que eso hasta que la UI real obligue más catálogo.

## Riesgos y decisiones conscientes

### EAV para atributos dinámicos

Ventaja:

- máxima flexibilidad para la UI

Costo:

- consultas más complejas
- validaciones más delicadas

Se acepta ese costo porque el problema de negocio pide tipos con atributos variables.

### Jerarquía por `parent_id`

Ventaja:

- simple y suficiente para arrancar

Costo:

- consultas recursivas para árboles profundos

Se acepta para el MVP.

### Versionado simple desde el inicio

Ventaja:

- evita rediseñar luego cuando aparezca historial real

Costo:

- una tabla más en la primera versión

Vale la pena.

## Recomendación concreta para la primera iteración

Implementar sólo estas tablas en la `v1`:

- `schema_migrations`
- `document_types`
- `container_types`
- `attribute_definitions`
- `document_type_attributes`
- `container_type_attributes`
- `containers`
- `documents`
- `document_versions`
- `document_files`
- `container_attribute_values`
- `document_attribute_values`

Eso es lo mínimo razonable para empezar la interfaz visual sin hipotecar el crecimiento del sistema.
