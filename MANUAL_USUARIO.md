# Manual de Usuario GDMS

## 1. Propósito

Este manual describe cómo usar el sistema `GDMS` desde la perspectiva del usuario final y del usuario operativo.

El sistema está orientado a:

- gestión documental;
- versionado de documentos;
- metadatos dinámicos;
- búsqueda documental;
- workflow de tareas;
- firma documental;
- records management;
- auditoría y trazabilidad;
- notificaciones operativas;
- reportes;
- verticales sectoriales legal, inmobiliario y corporativo;
- captura local de documentos por escáner en Windows.

## 2. Perfiles de uso

Según el rol y la organización, el usuario puede ver distintas secciones:

- usuario operativo documental;
- usuario jurídico;
- usuario de records/compliance;
- usuario de firma;
- administrador de organización;
- usuario con alcance de plataforma.

## 3. Acceso al sistema

### 3.1 Inicio de sesión

Para ingresar:

1. Abrir la aplicación.
2. Ingresar:
   - código de organización;
   - correo electrónico;
   - contraseña.
3. Presionar `Iniciar sesión`.

Si las credenciales son correctas, el sistema carga el dashboard inicial y las secciones habilitadas para el rol.

### 3.2 Cierre de sesión

Para salir:

1. Abrir el menú o la sección de cuenta.
2. Seleccionar `Cerrar sesión`.

## 4. Navegación general

La aplicación usa una navegación principal responsive. Según el ancho de pantalla puede verse como:

- `NavigationBar` en pantallas compactas;
- `NavigationRail` en pantallas amplias.

Las secciones más importantes pueden incluir:

- Documentos
- Búsqueda
- Workflow
- Firma
- Records
- Auditoría
- Notificaciones
- Reportes
- Integraciones
- Configuración
- Administración
- Legal
- Real Estate
- Corporate

## 5. Módulo Documentos

El módulo documental es el núcleo del sistema.

Permite:

- subir documentos;
- cargar metadatos;
- consultar detalle documental;
- descargar documentos;
- editar metadatos;
- exportar paquetes de evidencia;
- vincular documentos con expedientes o legajos;
- subir nuevas versiones;
- revisar historial de versiones;
- gestionar permisos finos;
- iniciar solicitudes de firma;
- operar tareas de workflow desde el propio detalle.

### 5.1 Dashboard documental

Desde el dashboard documental se puede:

1. Consultar documentos recientes o relevantes.
2. Buscar documentos.
3. Abrir el detalle de un documento.
4. Iniciar una carga nueva.

### 5.2 Subir un documento

Para subir un documento nuevo:

1. Ir a `Documentos`.
2. Seleccionar `Subir documento`.
3. Elegir el archivo por una de estas vías:
   - `Seleccionar archivo`
   - `Escanear documento` en Windows
4. Seleccionar el `tipo documental`.
5. Completar el `título`.
6. Completar los `metadatos` requeridos por el tipo documental.
7. Presionar `Subir`.

Resultado esperado:

- el documento queda registrado en el backend;
- se crea su primera versión;
- el sistema confirma la carga.

### 5.3 Metadatos dinámicos

Los metadatos cambian según el tipo documental.

El sistema puede mostrar campos de:

- texto;
- fecha;
- booleanos;
- otros campos tipados definidos por el esquema del tipo documental.

Recomendaciones:

- completar los campos obligatorios antes de subir;
- respetar el formato visible en cada control;
- revisar helpers o etiquetas contextuales antes de confirmar.

### 5.4 Detalle documental

Desde el detalle de un documento se puede:

- ver datos generales;
- descargar el binario;
- revisar y editar metadatos;
- ver actividad reciente;
- consultar auditoría reciente;
- exportar un paquete de evidencia JSON;
- vincular el documento a un expediente o legajo;
- iniciar o revisar firmas;
- revisar workflow relacionado;
- administrar permisos documentales finos.

## 6. Versionado documental

El sistema soporta nuevas versiones inmutables de un documento existente.

### 6.1 Subir nueva versión

Para cargar una nueva versión:

1. Abrir el detalle del documento.
2. Seleccionar `Subir nueva versión`.
3. Elegir archivo manual o escanear documento.
4. Confirmar con `Subir versión`.

Resultado esperado:

- la nueva versión queda asociada al documento existente;
- el historial se actualiza;
- el usuario puede descargar versiones específicas.

### 6.2 Historial de versiones

El historial permite:

- ver versiones previas;
- identificar la versión activa o más reciente;
- descargar una versión específica.

## 7. Escaneo de documentos

El sistema integra un flujo de escaneo local en Windows mediante `windows-twain`.

### 7.1 Cuándo usarlo

Usar el escaneo cuando:

- el documento todavía está en papel;
- se requiere capturar desde ADF o cama plana;
- se desea revisar el PDF antes de subirlo.

### 7.2 Flujo general de escaneo

1. Abrir `Escanear documento` desde upload o nueva versión.
2. Seleccionar escáner.
3. Elegir origen:
   - `ADF`
   - `Cama plana`
4. Configurar:
   - `simplex` o `duplex`;
   - DPI;
   - color;
   - descarte de páginas en blanco.
5. Ejecutar el escaneo.
6. Revisar la preview.
7. Si corresponde:
   - agregar páginas;
   - insertar páginas;
   - eliminar páginas;
   - exportar PDF local;
   - descartar la sesión.
8. Confirmar con `Usar escaneo`.

### 7.3 Señales de ayuda del formulario de escaneo

El sistema muestra:

- resumen efectivo de configuración;
- checklist de readiness;
- estado del host local;
- sugerencias rápidas;
- presets de escaneo;
- detalle del escáner seleccionado;
- sesiones activas reanudables.

### 7.4 Gestión de sesiones activas

La bandeja de sesiones activas permite:

- buscar;
- filtrar;
- ordenar;
- resumir el lote visible;
- reanudar sesiones;
- descartar sesiones;
- exportar sesiones visibles;
- copiar IDs visibles;
- limpiar sesiones problemáticas o rehidratadas.

## 8. Búsqueda documental

El módulo de búsqueda permite localizar documentos por distintos criterios.

Puede incluir:

- texto libre;
- tipo documental;
- estado;
- legal hold;
- apertura directa del detalle documental.

Uso recomendado:

1. Abrir `Búsqueda`.
2. Ingresar texto o aplicar filtros.
3. Ejecutar la búsqueda.
4. Abrir el documento desde resultados.

## 9. Workflow documental

El sistema incluye tareas de workflow asociadas a documentos.

Permite:

- listar tareas;
- filtrar `Solo mis tareas`;
- crear tareas;
- completar tareas;
- revisar tareas vinculadas desde el detalle documental.

Uso típico:

1. Abrir `Workflow`.
2. Revisar tareas activas.
3. Filtrar si hace falta.
4. Abrir una tarea o documento asociado.
5. Completar la tarea cuando corresponda.

## 10. Firma documental

El módulo de firma gestiona solicitudes de firma sobre documentos.

Permite:

- crear solicitudes de firma;
- revisar solicitudes abiertas;
- completar firmas;
- cancelar solicitudes pendientes;
- ver firmas desde el detalle documental;
- recibir notificaciones sobre estados de firma.

Uso general:

1. Abrir `Firma` o el detalle de un documento.
2. Crear una solicitud de firma o abrir una existente.
3. Completar, cerrar o cancelar según el estado del proceso.

## 11. Records Management

El módulo de records cubre operaciones de disposición y cumplimiento.

Incluye:

- políticas de retención;
- legal holds;
- liberación de holds;
- candidatos de disposición;
- ejecución de disposición;
- trazabilidad de acciones.

Uso típico:

1. Abrir `Records`.
2. Revisar candidatos y estado de cumplimiento.
3. Aplicar la acción correspondiente.
4. Confirmar la operación.

## 12. Auditoría

El módulo de auditoría permite revisar actividad relevante del sistema.

Puede incluir:

- eventos de autenticación;
- actividad administrativa;
- actividad documental;
- firmas;
- records;
- eventos de plataforma o organización.

Uso recomendado:

1. Abrir `Auditoría`.
2. Filtrar por ámbito, tipo o período si corresponde.
3. Revisar eventos recientes.

## 13. Notificaciones

El inbox de notificaciones consolida alertas operativas scoped a organización.

Puede mostrar:

- tareas de workflow;
- eventos de records;
- firmas pendientes;
- firmas canceladas;
- alertas de seguridad u operaciones relevantes.

## 14. Reportes

El módulo de reportes ofrece visibilidad operativa.

Puede incluir:

- KPIs de la organización;
- indicadores de plataforma;
- métricas documentales;
- métricas de workflow;
- firmas pendientes o canceladas;
- estado operativo general.

## 15. Integraciones

El dashboard de integraciones muestra el estado de conectividad del ecosistema técnico.

Puede incluir:

- PostgreSQL;
- Firebase;
- storage;
- proveedor de firma;
- otras integraciones configuradas.

## 16. Configuración

El módulo de configuración permite revisar y operar parámetros dinámicos.

Puede incluir:

- preferencias de la organización;
- configuración remota;
- valores provenientes de Firebase con fallback local.

## 17. Administración

El módulo administrativo permite operar entidades de gobierno del sistema.

Incluye:

- alta de organización;
- revisión de organizaciones recientes;
- gestión de usuarios de la organización;
- asignación de roles;
- visibilidad de actividad auditada reciente.

## 18. Vertical Legal

El vertical legal está orientado al manejo de expedientes jurídicos y documentos asociados.

Permite:

- crear expedientes;
- listar expedientes recientes;
- vincular documentos a expedientes;
- abrir detalle de expediente;
- navegar documentos asociados.

## 19. Vertical Real Estate

El vertical inmobiliario está orientado a legajos y documentación del sector real estate.

Permite:

- crear legajos;
- abrir detalle de legajo;
- vincular documentos a legajos.

## 20. Vertical Corporate

El vertical corporativo replica una lógica equivalente para documentación societaria o interna.

Permite:

- crear legajos corporativos;
- consultar su detalle;
- vincular documentos.

## 21. Estados y mensajes frecuentes

Algunas señales frecuentes del sistema:

- `Documento subido correctamente.`
- `Nueva versión subida correctamente.`
- `Selecciona un archivo antes de subir.`
- `No hay una sesión autenticada activa.`
- `No hay tipos documentales activos para este organización.`
- `Escaneo finalizado con N página(s).`
- `Servicio no disponible`
- `No hay escáneres detectados`

Recomendación:

- leer siempre el mensaje visible antes de reintentar una operación;
- si el problema involucra escaneo, revisar escáner seleccionado, host local y sesiones activas.

## 22. Buenas prácticas de uso

- Completar correctamente el tipo documental antes de subir.
- Revisar metadatos antes de confirmar.
- Usar nuevas versiones en vez de duplicar documentos cuando el contenido evoluciona.
- Usar vínculos a expedientes o legajos para mantener trazabilidad.
- Revisar workflow y firmas desde el detalle documental cuando el documento tenga tareas activas.
- Limpiar sesiones de escaneo viejas o erróneas para evitar ruido operativo.
- Usar reportes y auditoría para seguimiento, no solo para corrección reactiva.

## 23. Resolución básica de problemas

### No puedo iniciar sesión

- Verificar organización, correo y contraseña.
- Confirmar que el backend esté disponible.

### No puedo subir un documento

- Verificar que el archivo esté seleccionado.
- Confirmar que el tipo documental exista y esté activo.
- Revisar los metadatos obligatorios.

### No aparece el escáner

- Verificar que `windows-twain` esté corriendo.
- Reintentar descubrimiento.
- Confirmar que el escáner esté encendido y accesible por TWAIN.

### El submit queda bloqueado

- Verificar si la operación sigue en curso.
- Revisar si el diálogo está en estado `busy`.
- Esperar finalización o revisar el mensaje de error visible.

## 24. Cierre

`GDMS` centraliza operación documental, compliance y trazabilidad en una sola plataforma.

El recorrido recomendado para usuarios nuevos es:

1. iniciar sesión;
2. entrar a `Documentos`;
3. subir o escanear un documento;
4. revisar el detalle documental;
5. explorar búsqueda, workflow y firma;
6. usar records, auditoría y reportes según el rol.




