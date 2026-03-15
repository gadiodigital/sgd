## Reglas de trabajo

- Cada vez que se haga un cambio en el repo, este archivo debe mantenerse actualizado.
- Si hay diferencias entre una propuesta y la implementación real, la fuente de verdad técnica pasa a ser la implementación real.
- No limpiar ni borrar la base de datos de desarrollo salvo que sea estrictamente necesario.
- Si hace falta resetear o borrar datos de prueba, avisar antes.

## Visión general

SGD es un sistema de gestión documental orientado a organizar documentos físicos y digitales, con trazabilidad y estructura flexible.

La organización documental debe permitir:

- documentos con tipos configurables
- atributos dinámicos tipados por tipo de documento
- contenedores o nodos con atributos dinámicos tipados
- jerarquías configurables por cada empresa o proyecto
- asociación entre documento lógico y archivo físico/digital

## Estado actual del repo

### Documentación general

- [documentacion.md](C:/Users/Gabriel/Desktop/SGD/documentacion.md): idea general del proyecto SGD.
- [propuesta-db.md](C:/Users/Gabriel/Desktop/SGD/propuesta-db.md): propuesta funcional/técnica de base de datos.
- [db/exports/sgd_dev_snapshot.sql](C:/Users/Gabriel/Desktop/SGD/db/exports/sgd_dev_snapshot.sql): dump SQL plano versionable de la base local `sgd`, generado para poder subir un snapshot de desarrollo al repo.
- [.gitignore](C:/Users/Gabriel/Desktop/SGD/.gitignore): ignora artefactos generados pesados de Flutter, Dart y `windows-twain`, además de logs y caches locales.
- [Plan original/requerimientos.md](C:/Users/Gabriel/Desktop/SGD/Plan%20original/requerimientos.md): referencia base para RBAC, auditoría y auth federada futura.
- [Plan original/especificaciones-detalladas.md](C:/Users/Gabriel/Desktop/SGD/Plan%20original/especificaciones-detalladas.md): referencia para separar autenticación, autorización y auditoría.
- [Plan original/arquitectura-detallada.md](C:/Users/Gabriel/Desktop/SGD/Plan%20original/arquitectura-detallada.md): referencia para desacoplar proveedor de identidad y sesión interna del sistema.
- PDFs usados como insumo para la implementación actual de seguridad:
  - [Especificación Técnica SGD Argentina Gemini.pdf](C:/Users/Gabriel/Desktop/SGD/Ideas%20Sistemas%20de%20gestion%20documental/Especificaci%C3%B3n%20T%C3%A9cnica%20SGD%20Argentina%20Gemini.pdf)
  - [Especificación Técnica Integral SGD Legal-CloudGeminiCompleto.pdf](C:/Users/Gabriel/Desktop/SGD/Ideas%20Sistemas%20de%20gestion%20documental/Especificaci%C3%B3n%20T%C3%A9cnica%20Integral%20SGD%20Legal-CloudGeminiCompleto.pdf)
  - [Especificación Técnica Integral SGD Legal-CloudCompletoGemini.pdf](C:/Users/Gabriel/Desktop/SGD/Ideas%20Sistemas%20de%20gestion%20documental/Especificaci%C3%B3n%20T%C3%A9cnica%20Integral%20SGD%20Legal-CloudCompletoGemini.pdf)
  - [Especificación Técnica Detallada SGDGeminiVersion2.pdf](C:/Users/Gabriel/Desktop/SGD/Ideas%20Sistemas%20de%20gestion%20documental/Especificaci%C3%B3n%20T%C3%A9cnica%20Detallada%20SGDGeminiVersion2.pdf)
  - [Especificación Técnica Detallada SGD PYMEGemini.pdf](C:/Users/Gabriel/Desktop/SGD/Ideas%20Sistemas%20de%20gestion%20documental/Especificaci%C3%B3n%20T%C3%A9cnica%20Detallada%20SGD%20PYMEGemini.pdf)

### Conector de escáner local

- [windows-twain](C:/Users/Gabriel/Desktop/SGD/windows-twain): conector local TWAIN para acceder al escáner desde la interfaz.
- La API local corre por defecto en `http://127.0.0.1:43127`.
- La documentación de endpoints está en [documentacion.md](C:/Users/Gabriel/Desktop/SGD/windows-twain/documentacion.md).

### Propuestas de UI de escaneo

- [ui1.html](C:/Users/Gabriel/Desktop/SGD/ui1.html)
- [ui2.html](C:/Users/Gabriel/Desktop/SGD/ui2.html)
- [ui3.html](C:/Users/Gabriel/Desktop/SGD/ui3.html)

### UI principal Flutter

- [ui_sgd](C:/Users/Gabriel/Desktop/SGD/ui_sgd): proyecto Flutter inicial para el ABM de proyectos y jerarquía documental.
- Estado actual:
  - el acceso ahora pasa por una pantalla de login
  - en desarrollo local el usuario `admin` queda precargado en el formulario para agilizar pruebas manuales
  - la sesión de la app se mantiene en memoria y se envía por token Bearer a `sgd_api`
  - CRUD real de `proyectos` vía API local
  - CRUD real de `tipos de contenedor` por proyecto
  - CRUD real de relaciones `padre -> hijo` por proyecto
  - CRUD real del árbol jerárquico por proyecto
  - pantalla nueva de `Accesos` por proyecto para administrar perfiles, permisos y usuarios locales
  - la UI muestra de forma explícita el proyecto actual también en contenedores y jerarquía
  - atributos configurables por tipo de contenedor
  - cada atributo puede definir:
    - código
    - tipo de dato
    - extensión o largo máximo
    - validación regex
    - opciones cuando el tipo es `list`
  - cada tipo de contenedor puede elegir un icono del catálogo de Material Design
  - al crear/editar instancias del árbol se pueden cargar valores de atributos
  - los atributos `list` se representan en la UI como combo desplegable
  - los nodos finales con `acceptsDocs = true` ahora abren un `Centro de escaneo` integrado en Flutter, basado visualmente en `ui3.html`
  - el centro de escaneo consume `windows-twain` en forma directa para:
    - descubrir escáneres
    - escanear ADF simplex/duplex
    - ver previews
    - rotar páginas
    - mover páginas dentro del lote
    - ajustar brillo/contraste
    - eliminar páginas
    - fusionar una segunda sesión para insertar hojas
    - exportar PDF temporal
  - el centro de escaneo permite además capturar metadatos del documento antes de guardar
  - esos metadatos se basan hoy en los atributos definidos en el tipo del nodo y se persisten como atributos de documento generados para el flujo de escaneo
  - corre en web sin depender de `dart:io`
  - los diálogos principales validan en cliente antes de cerrar
  - cuando un campo es inválido el diálogo queda abierto y muestra el error en el campo
  - navegación por teclado mejorada en formularios principales (`Tab` y `Enter` en campos de una línea)
  - la jerarquía volvió a renderizar sin pantalla roja; se ajustó el trailing de acciones por nodo
  - en escritorio, si la API local no responde en `127.0.0.1:8081`, la app intenta levantar `sgd_api` automáticamente antes de mostrar error
  - la carga del snapshot tolera claves en minúscula devueltas por PostgreSQL/driver (`projectid`, `acceptsdocs`, `iconkey`, etc.) para no ocultar tipos o nodos existentes
  - en `Jerarquía`, cada nodo ahora muestra el estado de sus atributos definidos por tipo, incluso si fueron creados después del nodo
  - si un atributo existe pero todavía no tiene dato cargado, la UI lo marca explícitamente como `Sin valor`
  - las pantallas y acciones visibles dependen del perfil del usuario en el proyecto actual
  - ya puede listar documentos existentes por nodo y guardar documentos escaneados en PostgreSQL
  - todavía no expone ABM real de tipos de documento ni de sus atributos como módulo independiente

### API local para UI principal

- [sgd_api](C:/Users/Gabriel/Desktop/SGD/sgd_api): backend HTTP local de desarrollo para `ui_sgd`.
- Base URL por defecto: `http://127.0.0.1:8081`
- Funciones actuales:
  - login local con usuario/contraseña contra PostgreSQL
  - sesión interna propia del SGD con token Bearer
  - endpoint `auth/me` para refrescar el contexto del usuario actual
  - CRUD de proyectos
  - CRUD de tipos de contenedor
  - sincronización de atributos por tipo de contenedor
  - CRUD de reglas padre-hijo
  - CRUD de nodos jerárquicos
  - CRUD de perfiles y membresías por proyecto
  - listado de documentos por nodo
  - guardado de documentos escaneados desde sesiones de `windows-twain`
  - descarga del PDF actual del documento
  - auditoría funcional de lectura/escritura y eventos de autenticación
  - lectura agregada por proyecto (`snapshot`) para hidratar la UI
  - el `snapshot` normaliza aliases SQL para devolver atributos, reglas y nodos con claves estables en camelCase
  - publicación local de `ui1.html`, `ui2.html` y `ui3.html`
  - el guardado documental persiste:
    - `documents`
    - `document_versions`
    - `document_files`
    - `document_attribute_values`
  - el backend genera un `document_type` técnico por tipo de nodo para el flujo de escaneo y espeja allí los atributos del nodo como atributos de documento
  - los PDFs se guardan en `sgd_storage/documents/...` dentro del repo local

### Seguridad y acceso

- El modelo vigente separa:
  - identidad global del usuario
  - membresía del usuario a cada proyecto
  - perfil/permisos del usuario dentro de cada proyecto
- El proveedor implementado hoy es `local`, con password hasheada en PostgreSQL.
- La sesión del SGD queda desacoplada del proveedor de identidad:
  - hoy autentica contra base local
  - a futuro puede autenticar contra AD/LDAP, OIDC/OAuth2 o SAML y seguir emitiendo la misma sesión interna del SGD
- La autorización vigente es RBAC por proyecto.
- Los permisos base hoy cubren:
  - `project.read` / `project.write`
  - `types.read` / `types.write`
  - `hierarchy.read` / `hierarchy.write`
  - `documents.read` / `documents.write`
  - `security.read` / `security.write`
- Cada proyecto se inicializa con perfiles por defecto:
  - `admin`
  - `editor`
  - `viewer`
- El usuario local `admin` queda como `is_platform_admin = true` para bootstrap del entorno.
- La auditoría registra eventos funcionales, no sólo endpoints:
  - actor
  - proyecto
  - acción
  - tipo de acceso `read` o `write`
  - recurso
  - resultado
  - IP y user agent cuando están disponibles

Las tres propuestas consumen la API local de `windows-twain` y ya cubren:

- selección de escáner
- modo simplex/duplex
- color
- DPI
- descarte de páginas en blanco
- timeout
- vista previa
- rotación
- eliminación de páginas
- descarga de PDF

## Prioridad funcional inmediata

La primera necesidad de la UI principal no es el workflow documental completo.

La prioridad inmediata es poder hacer ABM de:

1. proyectos
2. tipos de nodo jerárquico
3. reglas padre-hijo entre tipos de nodo
4. nodos reales dentro de la jerarquía

El primer paso de la interfaz será crear un proyecto.

Cada proyecto debe quedar totalmente aislado de otro aunque compartan la misma base de datos.

## Modelo conceptual vigente

La organización documental ahora se piensa así:

- un `proyecto` define su propia estructura
- cada proyecto configura sus `tipos de contenedor`
- cada tipo de contenedor define:
  - icono
  - si puede ser raíz
  - si acepta documentos finales
  - atributos propios
- cada proyecto define qué tipos pueden colgar de qué otros tipos
- cada proyecto carga nodos concretos dentro de esa jerarquía
- los documentos luego se ubican dentro de nodos de esa jerarquía

Ejemplos de tipos de nodo posibles:

- caja
- carpeta
- bibliorato
- legajo
- cliente
- sector
- expediente

La clave es que no deben venir fijados por el sistema; cada empresa/proyecto debe poder definirlos.

## Base de datos actual

### Motor y conexión local

- PostgreSQL local disponible en `localhost:5432`
- usuario: `postgres`
- la base creada para desarrollo inicial es `sgd`

### Implementación vigente

La base inicial ya fue implementada y luego extendida de forma aditiva.

Archivos principales:

- [V202603151410__init_projects_hierarchy_v1.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603151410__init_projects_hierarchy_v1.sql)
- [V202603151730__extend_dynamic_attributes_v2.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603151730__extend_dynamic_attributes_v2.sql)
- [V202603151900__add_node_type_icon_key.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603151900__add_node_type_icon_key.sql)
- [V202603152130__add_auth_profiles_and_audit_v3.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603152130__add_auth_profiles_and_audit_v3.sql)
- [V202603152245__add_document_permissions_v4.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603152245__add_document_permissions_v4.sql)
- [V202603152245__add_document_permissions_v4.sql](C:/Users/Gabriel/Desktop/SGD/db/migrations/V202603152245__add_document_permissions_v4.sql)
- [sgd_dev_snapshot.sql](C:/Users/Gabriel/Desktop/SGD/db/exports/sgd_dev_snapshot.sql)

Estado:

- base `sgd` creada
- migraciones `V202603151410`, `V202603151730`, `V202603151900`, `V202603152130` y `V202603152245` aplicadas
- la migración `V202603152245` ya existe en `db/migrations` pero todavía no está aplicada en la base local `sgd`
- validada la jerarquía por proyecto
- validados atributos dinámicos en `node_attribute_values` y `document_attribute_values`
- `hierarchy_node_types` ahora persiste también `icon_key`
- la base ahora incluye usuarios locales, perfiles por proyecto, permisos, sesiones y auditoría
- se generó un dump versionable en `db/exports/sgd_dev_snapshot.sql` con el estado actual de desarrollo
- conservar los datos de prueba actuales salvo necesidad explícita de limpieza

### Tablas principales de la v1

- `projects`
- `hierarchy_node_types`
- `hierarchy_type_rules`
- `hierarchy_nodes`
- `attribute_definitions`
- `attribute_options`
- `node_type_attributes`
- `node_attribute_values`
- `document_types`
- `document_type_attributes`
- `documents`
- `document_attribute_values`
- `document_versions`
- `document_files`
- `auth_providers`
- `app_users`
- `auth_identities`
- `permission_catalog`
- `project_profiles`
- `project_profile_permissions`
- `project_memberships`
- `auth_sessions`
- `audit_events`
- `schema_migrations`

### Decisión de diseño importante

Toda tabla funcional queda vinculada a `project_id`.

El aislamiento entre proyectos no queda sólo en la aplicación; también queda respaldado por:

- claves foráneas compuestas por `project_id`
- constraints únicos por proyecto
- triggers para validar relaciones jerárquicas dentro del mismo proyecto

## Modelo de atributos dinámicos vigente

El modelo dinámico ya quedó unificado para `contenedores` y `documentos`.

Piezas:

- `attribute_definitions`: catálogo del atributo por proyecto y por scope
- `attribute_options`: opciones válidas cuando el atributo es de tipo `list`
- `node_type_attributes`: asigna atributos a tipos de contenedor
- `document_type_attributes`: asigna atributos a tipos de documento
- `node_attribute_values`: guarda el valor real por nodo
- `document_attribute_values`: guarda el valor real por documento

Tipos soportados actualmente:

- `string`
- `integer`
- `decimal`
- `date`
- `boolean`
- `list`
- `json`

Metadata disponible hoy en `attribute_definitions`:

- `data_type`
- `type_extension`
  - uso inicial: largo máximo para `string`
  - para tipos futuros puede complementar reglas más específicas desde `settings_json`
- `validation_regex`
- `validation_message`
- `settings_json`
- `is_required`
- `default_value`
- `help_text`

Almacenamiento de valores:

- `value_text`
- `value_number`
- `value_date`
- `value_boolean`
- `value_json`

Reglas ya resueltas en base:

- un atributo `node` no puede asignarse a `document_type_attributes`
- un atributo `document` no puede asignarse a `node_type_attributes`
- un valor dinámico debe usar la columna correcta según `data_type`
- un atributo de tipo `list` sólo acepta códigos existentes en `attribute_options`
- un valor de `string` respeta `type_extension` y `validation_regex`
- un valor dinámico sólo puede guardarse si el atributo está asignado al tipo del nodo o del documento correspondiente

## Alcance real de la v1 de base

La v1 está optimizada para habilitar la UI inicial.

Resuelve:

- creación de proyectos
- definición flexible de jerarquía por proyecto
- carga de nodos jerárquicos reales
- atributos dinámicos tipados para nodos y documentos
- opciones de lista para atributos dinámicos
- validación de tipos y bindings desde PostgreSQL
- ubicación futura de documentos dentro de la jerarquía
- versionado documental mínimo

No intenta resolver todavía:

- usuarios
- roles y permisos
- workflow
- auditoría avanzada
- OCR
- retención documental
- compartición externa
- firma digital

## Estrategia de evolución

La base está pensada para cambiar por migraciones versionadas.

Convención actual:

- carpeta: [db/migrations](C:/Users/Gabriel/Desktop/SGD/db/migrations)
- formato: `VYYYYMMDDHHMM__descripcion.sql`

Principios:

- cambios aditivos primero
- backfill de datos si hace falta
- endurecimiento de constraints después
- evitar cambios destructivos en la misma release

Patrón esperado para cambios grandes:

1. expand
2. migrate
3. contract

## Próximo foco probable de UI

Con la base actual, lo próximo razonable es construir pantallas para:

- crear proyecto
- listar proyectos
- crear tipos de contenedor
- definir atributos por tipo
- crear tipos de documento
- definir atributos por tipo de documento
- definir relaciones entre tipos de contenedor
- visualizar árbol jerárquico
- crear/editar nodos

Ese frente ya tiene una primera versión funcional en `ui_sgd`, hoy conectada a `sgd_api` y a PostgreSQL para proyectos, tipos, reglas y nodos.

Después de eso:

- completar ABM real de tipos de documento
- alta de documentos sobre nodos existentes
- atributos dinámicos en formularios para contenedores y documentos
- integración más cerrada entre `ui_sgd` y `windows-twain`
- adjuntos/versiones
