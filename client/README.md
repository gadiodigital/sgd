# GDMS Flutter Workspace

Workspace modular del frontend Flutter para el sistema de gestion documental.

Configuración actual del monorepo:

- raíz del workspace: [pubspec.yaml](C:\IA\codex\client\pubspec.yaml)
- resolución compartida Dart/Flutter: `resolution: workspace` en apps y packages
- orquestación: `melos`

## Modulos implementados

- `apps/gdms_app`
- `packages/core`
- `packages/design_system`
- `packages/feature_auth`
- `packages/feature_config`
- `packages/feature_documents`
- `packages/feature_integrations`
- `packages/feature_notifications`
- `packages/feature_records`
- `packages/feature_reports`
- `packages/feature_admin`
- `packages/feature_audit`
- `packages/feature_search`
- `packages/feature_signature`
- `packages/feature_sector_corporate`
- `packages/feature_sector_legal`
- `packages/feature_sector_real_estate`
- `packages/feature_workflow`

## Arquitectura

- `MVVM` para la capa visual
- `Clean Architecture` para dominio, aplicacion e infraestructura de cada feature
- login real contra el backend `.NET`
- integración segura con `Firebase Remote Config` y `Cloud Firestore` con fallback local
- repositorios HTTP reales para auth, documents, records y parte de admin
- upload documental real por multipart
- búsqueda documental conectada al backend
- catalogo de tipos documentales y metadatos dinamicos consumidos desde la API
- detalle documental con lectura, descarga y edicion de metadatos
- detalle documental con lectura, descarga, metadatos y auditoria reciente
- detalle documental con exportación de paquete de evidencia JSON
- detalle documental con vínculo a expedientes jurídicos
- detalle documental con carga de nuevas versiones e historial descargable
- detalle documental con solicitudes de firma contextualizadas, alta, cierre y cancelación
- records con ejecucion de disposicion y gestion de legal holds/politicas
- admin con tenants recientes, actividad auditada, alta de tenant y usuarios del tenant con asignacion de roles
- modulo dedicado de auditoria conectado a endpoints reales
- modulo dedicado de busqueda documental conectado a endpoints reales
- modulo dedicado de firma documental conectado a endpoints reales
- modulo dedicado de integraciones conectado a endpoints reales
- modulo dedicado de configuración conectado a Firebase con fallback local
- modulo dedicado de notificaciones conectado a un inbox operativo tenant-scoped
- modulo dedicado de reportes operativos conectado a endpoints reales
- modulo dedicado de workflow documental conectado a endpoints reales
- vertical jurídico inicial construido sobre workflow, records y auditoría
- vertical jurídico con creación de expedientes, vínculo expediente-documento y navegación de documentos por expediente
- vertical inmobiliario inicial construido sobre documentos, workflow y notificaciones
- vertical corporativo inicial construido sobre documentos, workflow y notificaciones
- datos demo solo como fallback en widgets aislados o previews de modulo
- shell responsive con `NavigationBar` y `NavigationRail`
- accesibilidad base alineada con `WCAG 2.2 AA`

## Build logic Android

La app Android usa convención compartida en:

- `apps/gdms_app/android/build-logic`

Plugin actual:

- `gdms.android.application`

Ese plugin concentra configuracion comun de Android y deja los valores
dependientes de Flutter en el modulo `app`.

## Comandos utiles

```powershell
cd client\apps\gdms_app
flutter pub get
flutter analyze
flutter test
```

Por defecto la app espera la API en:

```text
http://localhost:5012
```

Tambien podés cambiarla con:

```powershell
flutter run --dart-define=GDMS_API_BASE_URL=http://localhost:5012
```

Flujos principales ya conectados:

- login y bootstrap inicial
- dashboard documental con búsqueda
- upload con tipo documental y metadatos validados
- consulta de detalle documental, descarga y edición de metadatos
- consulta de detalle documental con auditoría reciente
- exportación de paquete probatorio por documento
- vínculo de documento a expediente jurídico desde el detalle documental
- carga de nuevas versiones documentales sobre documentos existentes
- descarga de una versión específica desde el historial del documento
- dashboard de records con ejecución de disposición y gestión operativa
- dashboard admin con auditoría real y acciones de gobierno básicas
- dashboard de auditoría dedicado con eventos recientes de plataforma o tenant
- dashboard de búsqueda dedicado con apertura de detalle documental
- dashboard de búsqueda con filtros por tipo documental, estado y legal hold
- dashboard de firma dedicado con creación y cierre de solicitudes
- dashboard de firma con cancelación de solicitudes pendientes
- dashboard de integraciones dedicado con estado de conectividad y configuración
- dashboard de configuración dedicado con Remote Config y preferencias Firestore
- dashboard de notificaciones dedicado con alertas operativas
- dashboard de notificaciones con eventos recientes de firma cancelada
- dashboard de reportes dedicado con resumen operativo tenant y vista de plataforma
- dashboard de reportes con KPI de firmas canceladas
- dashboard jurídico dedicado para sector legal
- dashboard jurídico con expedientes recientes y detalle navegable por expediente
- dashboard inmobiliario dedicado para sector real estate
- dashboard inmobiliario con creación de legajos, detalle y vínculo documento-legajo
- dashboard corporativo dedicado para sector corporate
- dashboard corporativo con creación de legajos, detalle y vínculo documento-legajo
- dashboard de workflow con alta y cierre de tareas documentales
- dashboard de workflow con asignación opcional y filtro de `Solo mis tareas`
- detalle documental con workflow asociado, creación y cierre de tareas por documento
- detalle documental con firma asociada y acciones de completar o cancelar solicitud
- gestion de usuarios del tenant con alta y asignacion de roles
- gestion de permisos documentales finos desde el detalle documental

```powershell
cd client
melos bootstrap
melos run analyze
melos run test
```

Si `melos` no entra por `PATH`, revisar que existan:

- `C:\Users\aleja\AppData\Local\Pub\Cache\bin`
- `C:\FlutterSDK\flutter\bin`
- `C:\FlutterSDK\flutter\bin\cache\dart-sdk\bin`

```powershell
powershell -ExecutionPolicy Bypass -File ..\scripts\quality\validate_workspace.ps1
```
