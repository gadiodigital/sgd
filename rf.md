# Requisitos Funcionales

Fecha de corte: 2026-03-18

## 1. Objetivo del sistema

Diseñar un sistema de gestión documental y ECM para Argentina, modular, híbrido y orientado a seguridad desde el inicio, apto para empresas, inmobiliarias, estudios jurídicos y organizaciones similares.

## 2. Principios obligatorios de diseño

- Arquitectura backend: `.NET 10 LTS`, `modular monolith`, Clean Architecture por módulo.
- Frontend: `Flutter` con `MVVM` en la capa visual y Clean Architecture para el resto.
- Despliegue: híbrido, con soporte de instalación dedicada en nube u on-premise.
- Persistencia base: `PostgreSQL 18.3` sobre la rama mayor `18` vigente al `2026-03-18` para metadatos relacionales y transaccionales; `Firebase Remote Config` para configuración dinámica no sensible; `Cloud Firestore` para datos y proyecciones no relacionales; almacenamiento `S3-compatible` para binarios; `OpenSearch` para búsqueda.
- Eventos: `Outbox` para integración confiable.
- Seguridad: MFA, RBAC/ABAC, cifrado, claves por organización, auditoría inmutable.
- Validaciones: todas las entradas y persistencias deben contemplar validaciones de dominio, integridad referencial y tipos de datos en UI, API, dominio y base de datos.
- Modularidad: el proyecto debe dividirse en módulos; en frontend debe usarse `convention plugins` para build/config compartida.

## 3. Actores principales

- Administrador de plataforma
- Administrador de organización
- Oficial de cumplimiento
- Responsable de seguridad
- Operador documental
- Usuario de negocio
- Abogado o analista jurídico
- Corredor o agente inmobiliario
- Auditor interno o externo
- Cliente o tercero externo autorizado
- Sistema externo integrado

## 4. Módulos funcionales previstos

- `app_shell`
- `design_system`
- `auth`
- `documents`
- `search`
- `workflow`
- `records`
- `audit`
- `admin`
- `config`
- `integrations`
- `notifications`
- `signature`
- `sector_real_estate`
- `sector_legal`
- `sector_corporate`

## 5. Requisitos funcionales por capacidad

## 5.1 Identidad y acceso

## RF-001 Gestión del ciclo de vida de usuarios

- Descripción: el sistema debe permitir alta, modificación, suspensión, baja lógica y reactivación de usuarios internos y externos.
- Actor: administrador de plataforma, administrador de organización.
- Precondiciones: organización creada; política de identidad definida.
- Reglas de negocio: toda alta debe asociarse a organización, rol y estado; toda baja debe preservar trazabilidad histórica.
- Criterios de aceptación:
  - se puede invitar un usuario y asignarle perfil inicial;
  - la baja lógica impide acceso futuro sin borrar trazas previas;
  - la reactivación conserva el historial de auditoría.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.326, ISO/IEC 27001, OWASP ASVS.
- Módulo: `auth`, `admin`.
- Observaciones sectoriales: en jurídico e inmobiliario debe contemplarse personal tercerizado y acceso temporal.

## RF-002 Autenticación multifactor por perfil y riesgo

- Descripción: el sistema debe exigir MFA para perfiles críticos y permitir políticas adaptativas según riesgo, ubicación, dispositivo o sensibilidad documental.
- Actor: usuario, administrador.
- Precondiciones: identidad registrada.
- Reglas de negocio: MFA es obligatorio para administradores, oficiales de cumplimiento y accesos externos privilegiados.
- Criterios de aceptación:
  - se pueden configurar políticas MFA por rol;
  - el sistema bloquea acceso privilegiado sin segundo factor;
  - queda registro auditable del método usado.
- Prioridad: Crítica.
- Normas relacionadas: Ley 26.388, ISO/IEC 27001, OWASP ASVS.
- Módulo: `auth`.
- Observaciones sectoriales: para estudios jurídicos debe ser obligatorio en expedientes reservados.

## RF-003 Autorización RBAC y ABAC

- Descripción: el sistema debe combinar roles con atributos de contexto para controlar acceso a documentos, carpetas, expedientes, reportes y funciones administrativas.
- Actor: administrador, usuario de negocio.
- Precondiciones: usuarios, roles y atributos definidos.
- Reglas de negocio: la decisión de acceso debe evaluar organización, rol, confidencialidad, área, asunto, sector y estado documental.
- Criterios de aceptación:
  - puede negarse acceso a un usuario con rol válido pero sin atributo contextual;
  - se soportan niveles de clasificación documental;
  - toda denegación queda registrada.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.326, ISO/IEC 27002, OWASP API Security.
- Módulo: `auth`, `documents`, `audit`.
- Observaciones sectoriales: en jurídico debe soportar `ethical walls`.

## RF-004 Federación de identidad y SSO

- Descripción: el sistema debe integrarse con proveedores externos de identidad para SSO y sincronización de grupos.
- Actor: administrador de plataforma.
- Precondiciones: IdP corporativo disponible.
- Reglas de negocio: el sistema debe soportar al menos OIDC/SAML y mapear grupos a roles internos.
- Criterios de aceptación:
  - una organización puede autenticar con su IdP;
  - la sincronización de grupos actualiza permisos sin tocar el dominio documental;
  - la pérdida de federación no elimina auditoría previa.
- Prioridad: Alta.
- Normas relacionadas: ISO/IEC 27001, ISO/IEC 27017.
- Módulo: `auth`, `admin`.
- Observaciones sectoriales: clave para empresas grandes con Active Directory o Microsoft Entra.

## RF-005 Delegación controlada y acceso de emergencia

- Descripción: el sistema debe permitir delegar funciones por período y habilitar acceso extraordinario de emergencia con trazabilidad reforzada.
- Actor: administrador, responsable de seguridad.
- Precondiciones: política de delegación definida.
- Reglas de negocio: toda delegación debe tener inicio, fin, alcance y motivo; el acceso de emergencia requiere justificación.
- Criterios de aceptación:
  - se puede otorgar delegación temporal;
  - el acceso de emergencia genera evento de alto riesgo;
  - la delegación expira automáticamente.
- Prioridad: Alta.
- Normas relacionadas: ISO/IEC 27002, NIST SSDF.
- Módulo: `auth`, `audit`.
- Observaciones sectoriales: útil para reemplazos de oficiales de cumplimiento o socios responsables.

## 5.2 Organización y parametrización

## RF-006 Configuración de organización única

- Descripción: el sistema debe permitir configurar la organización principal de la instalación con branding, dominios, cuotas y políticas base.
- Actor: administrador de plataforma.
- Precondiciones: plataforma operativa.
- Reglas de negocio: una instalación GDMS opera para una única organización; no debe existir alta operativa de organizaciones adicionales como modalidad de producto.
- Criterios de aceptación:
  - se configura la organización principal;
  - usuarios y documentos quedan asociados a esa organización;
  - la configuración puede actualizarse sin perder historial.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.326, ISO/IEC 27017, ISO/IEC 27018.
- Módulo: `admin`.
- Observaciones sectoriales: fundamental para instalaciones dedicadas y despliegues on-premise.

## RF-007 Parametrización por sector y jurisdicción

- Descripción: el sistema debe permitir activar verticales, tipos documentales, plazos de retención y políticas de compliance por organización.
- Actor: administrador de organización.
- Precondiciones: organización creada.
- Reglas de negocio: la parametrización no debe requerir recompilar el producto.
- Criterios de aceptación:
  - se puede activar el pack inmobiliario, jurídico o corporativo;
  - cambian formularios, catálogos y reglas visibles;
  - los cambios quedan versionados.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.246, UIF 43/2024, UIF 48/2024, ISO 30301.
- Módulo: `admin`, `sector_real_estate`, `sector_legal`, `sector_corporate`.
- Observaciones sectoriales: permite go-to-market escalable sin forks del producto.

## RF-008 Administración de catálogos y políticas

- Descripción: el sistema debe administrar catálogos de tipos documentales, esquemas de metadatos, niveles de confidencialidad, calendarios de retención, plantillas y reglas de workflow.
- Actor: administrador de organización, oficial de cumplimiento.
- Precondiciones: organización configurada.
- Reglas de negocio: toda política debe estar versionada y con vigencia.
- Criterios de aceptación:
  - se pueden crear políticas y activarlas por fecha;
  - el sistema conserva histórico de cambios;
  - los documentos nuevos adoptan la versión vigente.
- Prioridad: Crítica.
- Normas relacionadas: ISO 30301, ISO 23081, ISO 15489.
- Módulo: `admin`, `records`, `workflow`.
- Observaciones sectoriales: los calendarios de retención deben poder diferir por rubro y tipo documental.

## 5.3 Captura e ingreso documental

## RF-009 Carga individual de documentos

- Descripción: el sistema debe permitir subir un documento individual con metadatos mínimos y validaciones de seguridad.
- Actor: operador documental, usuario de negocio.
- Precondiciones: permiso de carga vigente.
- Reglas de negocio: la carga debe asociarse a tipo documental, propietario lógico y clasificación.
- Criterios de aceptación:
  - se puede subir archivo y completar metadatos mínimos;
  - el documento queda visible según permisos;
  - el sistema registra hash y hora de ingreso.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.506, ISO 15489, ISO 23081.
- Módulo: `documents`.
- Observaciones sectoriales: en jurídico puede requerir asociación a asunto; en inmobiliaria, a inmueble o cliente.

## RF-010 Carga masiva e importación

- Descripción: el sistema debe admitir importación masiva desde carpetas, repositorios legacy o planillas de control.
- Actor: administrador de organización, operador documental.
- Precondiciones: mapeo de origen definido.
- Reglas de negocio: toda importación masiva debe soportar prevalidación, reintentos y reporte de errores.
- Criterios de aceptación:
  - se puede importar lote con metadatos asociados;
  - el sistema informa altas, rechazos y duplicados;
  - cada lote queda auditado.
- Prioridad: Alta.
- Normas relacionadas: ISO 15489, ISO 16175.
- Módulo: `documents`, `admin`.
- Observaciones sectoriales: clave para migraciones desde carpetas compartidas o ECM previos.

## RF-011 Recepción multicanal

- Descripción: el sistema debe recibir documentos por UI, API, correo, scanner o integraciones.
- Actor: usuario, sistema externo.
- Precondiciones: canal habilitado.
- Reglas de negocio: cada canal debe normalizar metadatos de origen y evidencias de recepción.
- Criterios de aceptación:
  - el mismo documento puede ingresar por distintos canales controlados;
  - el origen queda identificado;
  - la trazabilidad no depende del canal.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.506, ISO 16175.
- Módulo: `documents`, `integrations`.
- Observaciones sectoriales: útil para legajos híbridos digitalizados.

## RF-012 Validación de seguridad y cuarentena

- Descripción: el sistema debe inspeccionar archivos cargados y aislar los sospechosos antes de exponerlos.
- Actor: sistema, responsable de seguridad.
- Precondiciones: motor antimalware o servicio equivalente disponible.
- Reglas de negocio: ningún archivo sospechoso puede pasar a estado usable sin resolución explícita.
- Criterios de aceptación:
  - un archivo malicioso queda en cuarentena;
  - el usuario recibe estado de revisión;
  - el evento queda auditado.
- Prioridad: Crítica.
- Normas relacionadas: Ley 26.388, ISO/IEC 27002, OWASP.
- Módulo: `documents`, `audit`.
- Observaciones sectoriales: obligatorio para estudios y empresas con recepción externa de documentos.

## RF-013 OCR y extracción de texto

- Descripción: el sistema debe ejecutar OCR y extracción de texto para soportar búsqueda, clasificación y evidencias.
- Actor: sistema.
- Precondiciones: documento soportado y motor OCR disponible.
- Reglas de negocio: el texto extraído debe almacenarse separado del binario original y quedar versionado.
- Criterios de aceptación:
  - un PDF escaneado queda indexable;
  - el resultado de OCR puede revisarse;
  - se conserva el archivo original sin alteraciones.
- Prioridad: Alta.
- Normas relacionadas: ISO 15489, ISO 19005.
- Módulo: `documents`, `search`.
- Observaciones sectoriales: crítico para escaneos notariales, contratos y expedientes físicos.

## RF-014 Clasificación automática asistida

- Descripción: el sistema debe sugerir tipo documental, etiquetas o metadatos a partir del contenido y del contexto.
- Actor: sistema, operador documental.
- Precondiciones: taxonomía configurada.
- Reglas de negocio: la sugerencia no reemplaza validación humana cuando la política lo exija.
- Criterios de aceptación:
  - el sistema sugiere clasificación;
  - el usuario puede aceptar, corregir o rechazar;
  - queda registro del resultado final.
- Prioridad: Media.
- Normas relacionadas: ISO 15489, ISO 23081.
- Módulo: `documents`, `search`.
- Observaciones sectoriales: recomendable en legajos masivos o migraciones.

## 5.4 Metadatos, taxonomía y repositorio

## RF-015 Gestión de metadatos documentales

- Descripción: el sistema debe gestionar metadatos obligatorios, opcionales, heredados y calculados para cada documento o expediente.
- Actor: operador documental, administrador.
- Precondiciones: esquema de metadatos publicado.
- Reglas de negocio: los metadatos obligatorios no pueden omitirse; los cambios deben quedar auditados.
- Criterios de aceptación:
  - los metadatos se validan según esquema;
  - se pueden heredar desde carpeta, caso o legajo;
  - cada cambio deja rastro de autor y momento.
- Prioridad: Crítica.
- Normas relacionadas: ISO 23081, ISO 15489, Ley 25.506.
- Módulo: `documents`.
- Observaciones sectoriales: los datos AML y de secreto profesional deben tratarse como metadatos sensibles.

## RF-016 Esquemas dinámicos por tipo documental

- Descripción: el sistema debe permitir definir distintos formularios y validaciones para cada tipo documental.
- Actor: administrador de organización.
- Precondiciones: catálogo documental activo.
- Reglas de negocio: el esquema debe ser versionable y compatible con cambios progresivos.
- Criterios de aceptación:
  - diferentes tipos documentales muestran campos distintos;
  - una nueva versión no rompe documentos históricos;
  - la consulta histórica respeta el esquema vigente al momento del alta.
- Prioridad: Alta.
- Normas relacionadas: ISO 23081, ISO 16175.
- Módulo: `documents`, `admin`.
- Observaciones sectoriales: esencial para escalabilidad multi-industria.

## RF-017 Versionado y control de cambios

- Descripción: el sistema debe versionar documentos y permitir check-in/check-out, comparación lógica y restauración controlada.
- Actor: usuario de negocio, operador documental.
- Precondiciones: permiso de edición.
- Reglas de negocio: una versión declarada como record no puede reemplazarse libremente.
- Criterios de aceptación:
  - cada modificación crea nueva versión;
  - se visualiza historial completo;
  - la restauración no borra la secuencia anterior.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.506, ISO 15489, ISO 16175.
- Módulo: `documents`, `records`.
- Observaciones sectoriales: en jurídico debe distinguir borrador, versión presentada y copia certificada.

## RF-018 Búsqueda full text y facetada

- Descripción: el sistema debe permitir buscar por texto, metadatos, etiquetas, estados, fechas, actores y relaciones.
- Actor: todos los usuarios con permiso.
- Precondiciones: índice disponible.
- Reglas de negocio: los resultados deben respetar permisos y ocultar documentos no autorizados.
- Criterios de aceptación:
  - se puede buscar por palabra del contenido;
  - se puede filtrar por facetas;
  - no se devuelve contenido fuera de permisos.
- Prioridad: Crítica.
- Normas relacionadas: ISO 15489, ISO 23081, Ley 25.326.
- Módulo: `search`, `documents`.
- Observaciones sectoriales: en inmobiliaria se buscará por inmueble; en jurídico por asunto, cliente o tribunal.

## RF-019 Previsualización segura y marca de agua

- Descripción: el sistema debe previsualizar documentos sin exigir descarga y aplicar marca de agua cuando la política lo requiera.
- Actor: usuario autorizado.
- Precondiciones: documento apto para render.
- Reglas de negocio: la marca de agua debe poder incluir usuario, fecha y organización.
- Criterios de aceptación:
  - se visualiza el documento en navegador o app;
  - la política puede forzar watermark;
  - la descarga puede deshabilitarse por tipo documental.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.326, ISO/IEC 27002.
- Módulo: `documents`.
- Observaciones sectoriales: muy útil en documentación reservada o borradores de contratos.

## RF-020 Carpetas, expedientes y casos

- Descripción: el sistema debe agrupar documentos en carpetas, expedientes, asuntos o legajos según la vertical activa.
- Actor: usuario de negocio, operador documental.
- Precondiciones: esquema de agrupación configurado.
- Reglas de negocio: una agrupación debe tener identificador, estado, responsable y metadatos propios.
- Criterios de aceptación:
  - se puede crear expediente o legajo;
  - los documentos heredan contexto;
  - la consulta muestra historia consolidada del conjunto.
- Prioridad: Crítica.
- Normas relacionadas: ISO 15489, ISO 16175.
- Módulo: `documents`, `workflow`, `sector_*`.
- Observaciones sectoriales: expediente jurídico, legajo inmobiliario y carpeta corporativa son variantes del mismo patrón.

## 5.5 Flujos y colaboración

## RF-021 Flujos simples de revisión y aprobación

- Descripción: el sistema debe ejecutar workflows básicos de revisión, aprobación, rechazo y publicación interna.
- Actor: usuario de negocio, aprobador.
- Precondiciones: plantilla de workflow activa.
- Reglas de negocio: el workflow no debe alterar la integridad del documento original.
- Criterios de aceptación:
  - se inicia flujo sobre documento o expediente;
  - el aprobador puede aprobar o rechazar con motivo;
  - el estado final queda reflejado en auditoría.
- Prioridad: Alta.
- Normas relacionadas: ISO 30301, ISO 16175.
- Módulo: `workflow`, `documents`.
- Observaciones sectoriales: útil en aprobación contractual y revisión documental interna.

## RF-022 Tareas, vencimientos y recordatorios

- Descripción: el sistema debe crear tareas manuales o automáticas con fecha de vencimiento, responsable y recordatorios.
- Actor: usuario, sistema.
- Precondiciones: workflow o política activa.
- Reglas de negocio: las tareas vencidas deben poder escalarse.
- Criterios de aceptación:
  - una tarea aparece en bandeja del responsable;
  - se envían recordatorios;
  - queda histórico de cumplimiento o incumplimiento.
- Prioridad: Alta.
- Normas relacionadas: ISO 30301, ISO 22301.
- Módulo: `workflow`, `notifications`.
- Observaciones sectoriales: muy relevante para plazos legales y renovaciones documentales.

## RF-023 Comentarios internos y anotaciones

- Descripción: el sistema debe permitir comentarios internos, observaciones y anotaciones separadas del contenido original.
- Actor: usuario autorizado.
- Precondiciones: permiso sobre documento o caso.
- Reglas de negocio: las anotaciones no deben sobrescribir el documento base.
- Criterios de aceptación:
  - se agregan comentarios visibles según permisos;
  - queda autor, fecha y contexto;
  - las anotaciones pueden excluirse de exportaciones probatorias.
- Prioridad: Media.
- Normas relacionadas: ISO 16175.
- Módulo: `workflow`, `documents`.
- Observaciones sectoriales: en jurídico debe distinguir observación interna de documento de prueba.

## RF-024 Compartición segura interna y externa

- Descripción: el sistema debe compartir documentos o expedientes con usuarios internos y externos mediante permisos controlados, expiración y restricciones.
- Actor: usuario autorizado, cliente externo.
- Precondiciones: política de compartición definida.
- Reglas de negocio: no debe haber links públicos sin expiración ni trazabilidad.
- Criterios de aceptación:
  - se puede generar acceso externo temporal;
  - se puede revocar antes de vencimiento;
  - toda apertura externa queda auditada.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.326, ISO/IEC 27002.
- Módulo: `documents`, `auth`.
- Observaciones sectoriales: útil para compartir carpeta de cierre inmobiliario o documentación con cliente.

## RF-025 Notificaciones y comunicaciones

- Descripción: el sistema debe emitir notificaciones por eventos, tareas, vencimientos, cambios de estado y alertas de cumplimiento.
- Actor: sistema, usuario.
- Precondiciones: canal de notificación configurado.
- Reglas de negocio: el contenido de la notificación debe minimizar datos sensibles.
- Criterios de aceptación:
  - el usuario recibe avisos por tareas y vencimientos;
  - las alertas pueden ser parametrizadas;
  - cada envío queda registrado.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.326, ISO/IEC 27018.
- Módulo: `workflow`, `admin`.
- Observaciones sectoriales: importante para vencimientos regulatorios o de causas.

## 5.6 Records management, retención y evidencia

## RF-026 Calendario de retención y disposición

- Descripción: el sistema debe aplicar calendarios de retención por tipo documental, sector, organización y estado del expediente.
- Actor: oficial de cumplimiento, administrador.
- Precondiciones: política aprobada y publicada.
- Reglas de negocio: el plazo debe ser parametrizable y soportar excepciones justificadas.
- Criterios de aceptación:
  - cada documento conoce su regla de retención;
  - el sistema calcula fecha de revisión o disposición;
  - los cambios de política no destruyen histórico.
- Prioridad: Crítica.
- Normas relacionadas: CCyC arts. 328-330, ISO 15489, ISO 16175.
- Módulo: `records`.
- Observaciones sectoriales: los plazos deben variar entre contable, contractual, societario, AML y jurídico.

## RF-027 Legal hold o bloqueo legal

- Descripción: el sistema debe bloquear eliminación, sobreescritura o disposición cuando exista litigio, auditoría, investigación o requerimiento regulatorio.
- Actor: abogado interno, auditor, oficial de cumplimiento.
- Precondiciones: caso o requerimiento identificado.
- Reglas de negocio: el legal hold prevalece sobre la regla de disposición normal.
- Criterios de aceptación:
  - se puede activar bloqueo legal sobre documentos o conjuntos;
  - el sistema impide su destrucción;
  - la liberación del hold requiere autorización explícita.
- Prioridad: Crítica.
- Normas relacionadas: CCyC, Ley 25.506, ISO 16175.
- Módulo: `records`, `audit`.
- Observaciones sectoriales: esencial en estudios jurídicos y compliance.

## RF-028 Declaración de record y congelamiento

- Descripción: el sistema debe permitir declarar una versión como record definitivo y congelar ciertos atributos.
- Actor: operador documental, oficial de cumplimiento.
- Precondiciones: documento completo.
- Reglas de negocio: un record declarado no debe alterarse sin generar nueva evidencia y autorización extraordinaria.
- Criterios de aceptación:
  - se puede marcar versión como record;
  - el sistema bloquea edición directa;
  - se conserva vínculo entre borradores y record final.
- Prioridad: Alta.
- Normas relacionadas: ISO 15489, ISO 16175.
- Módulo: `records`, `documents`.
- Observaciones sectoriales: útil para pólizas, contratos firmados, escritos presentados y legajos cerrados.

## RF-029 Eliminación controlada y certificado de disposición

- Descripción: el sistema debe ejecutar disposición o eliminación controlada y emitir evidencia del proceso.
- Actor: oficial de cumplimiento, administrador autorizado.
- Precondiciones: vencimiento sin hold vigente.
- Reglas de negocio: la disposición debe respetar doble control cuando la política lo exija.
- Criterios de aceptación:
  - el sistema propone lote elegible para disposición;
  - la aprobación queda registrada;
  - se genera certificado o acta de disposición.
- Prioridad: Alta.
- Normas relacionadas: CCyC, ISO 15489, ISO 30301.
- Módulo: `records`, `audit`.
- Observaciones sectoriales: para información sensible debe registrarse motivo, aprobadores y método.

## RF-030 Auditoría inmutable y trazabilidad de eventos

- Descripción: el sistema debe registrar eventos de acceso, creación, edición, visualización, firma, exportación, compartición, eliminación y administración.
- Actor: sistema, auditor.
- Precondiciones: subsistemas integrados.
- Reglas de negocio: la bitácora debe ser tamper-evident y exportable.
- Criterios de aceptación:
  - toda acción relevante genera evento;
  - el evento incluye actor, organización, timestamp, origen y objeto;
  - un auditor puede consultar secuencia cronológica verificable.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.506, Ley 26.388, ISO/IEC 27001, ISO/IEC 27037.
- Módulo: `audit`.
- Observaciones sectoriales: los accesos a expedientes reservados deben destacar riesgo alto.

## RF-031 Exportación probatoria y paquete de evidencia

- Descripción: el sistema debe exportar documentos y evidencias asociadas en un paquete verificable.
- Actor: auditor, abogado, oficial de cumplimiento.
- Precondiciones: permiso para exportación probatoria.
- Reglas de negocio: la exportación debe incluir contexto, hashes, historial relevante y cadena de custodia.
- Criterios de aceptación:
  - se genera paquete con binario, metadatos y auditoría;
  - el paquete es verificable externamente;
  - el sistema registra quién exportó y por qué.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.506, ISO 19005, ISO/IEC 27037, IRAM 36100.
- Módulo: `audit`, `records`.
- Observaciones sectoriales: clave para litigios, inspecciones y auditorías externas.

## 5.7 Privacidad, firma e integraciones

## RF-032 Gestión de derechos del titular de datos

- Descripción: el sistema debe soportar la localización, revisión, exportación, rectificación, bloqueo o supresión de información vinculada a una persona.
- Actor: administrador de organización, DPO o responsable designado.
- Precondiciones: identidad del solicitante validada.
- Reglas de negocio: el cumplimiento puede estar limitado por retención legal, hold o base legal prevalente.
- Criterios de aceptación:
  - se puede buscar información por persona;
  - se genera caso de atención de derecho;
  - el sistema deja constancia del resultado y fundamento.
- Prioridad: Crítica.
- Normas relacionadas: Constitución Nacional art. 43, Ley 25.326, ISO/IEC 27701.
- Módulo: `admin`, `documents`, `audit`.
- Observaciones sectoriales: en jurídico debe contemplarse tensión entre secreto profesional y derechos del titular.

## RF-033 Gestión de encargados, terceros y transferencias

- Descripción: el sistema debe identificar procesadores, subprocesadores, integraciones externas y transferencias de datos vinculadas a la organización.
- Actor: administrador de plataforma, administrador de organización.
- Precondiciones: integraciones configuradas.
- Reglas de negocio: toda integración que procese datos personales debe registrarse con finalidad y responsable.
- Criterios de aceptación:
  - se puede registrar proveedor o subprocesador;
  - se puede marcar si interviene transferencia internacional;
  - la configuración queda auditada.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.326, Decreto 1558/2001, ISO/IEC 27701, ISO/IEC 27018.
- Módulo: `admin`, `integrations`.
- Observaciones sectoriales: especialmente importante para OCR, firma, mailing y almacenamiento externo.

## RF-034 Integración con firma electrónica y digital

- Descripción: el sistema debe integrarse con proveedores de firma mediante adaptadores desacoplados del dominio.
- Actor: sistema externo, usuario firmante.
- Precondiciones: proveedor configurado.
- Reglas de negocio: el sistema debe distinguir evidencia de firma electrónica de evidencia de firma digital.
- Criterios de aceptación:
  - se puede iniciar proceso de firma desde un documento o expediente;
  - el adaptador devuelve estado y evidencia;
  - el documento firmado queda vinculado al original.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.506, Decreto 182/2019.
- Módulo: `integrations`, `documents`, `signature`.
- Observaciones sectoriales: la modalidad exigible dependerá del caso de uso y del nivel probatorio requerido.

## RF-035 Verificación de firmas y sellado temporal

- Descripción: el sistema debe verificar firmas recibidas, conservar evidencia de verificación y prever sellado temporal o constancia temporal cuando el proveedor lo soporte.
- Actor: sistema, auditor, usuario de negocio.
- Precondiciones: documento firmado disponible.
- Reglas de negocio: la verificación debe guardar fecha, estado, cadena certificante y resultado.
- Criterios de aceptación:
  - se puede validar firma de un documento;
  - el resultado se conserva como evidencia asociada;
  - se identifican firmas inválidas, vencidas o revocadas.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.506, Decreto 182/2019, ISO/IEC 27037.
- Módulo: `signature`, `audit`.
- Observaciones sectoriales: crítico en contratos, poderes y documentos a presentar ante terceros.

## RF-036 API pública, webhooks e interoperabilidad

- Descripción: el sistema debe exponer APIs y webhooks seguros para integrar ERP, CRM, correo, BPM, firma y sistemas verticales.
- Actor: sistema externo, integrador.
- Precondiciones: credenciales y scopes definidos.
- Reglas de negocio: toda integración debe operar bajo autorización fuerte y límites de tasa.
- Criterios de aceptación:
  - existen endpoints documentados;
  - se pueden recibir y emitir eventos;
  - la auditoría distingue llamadas humanas de llamadas técnicas.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.326, Ley 27.446, OWASP API Security.
- Módulo: `integrations`, `audit`.
- Observaciones sectoriales: imprescindible para adopción empresarial.

## RF-037 Reportes y tableros operativos y de compliance

- Descripción: el sistema debe generar reportes operativos, regulatorios y de auditoría sobre volúmenes, accesos, vencimientos, hold, disposición, AML y actividad de usuarios.
- Actor: administrador, oficial de cumplimiento, auditor.
- Precondiciones: datos operativos disponibles.
- Reglas de negocio: el acceso a reportes debe respetar el menor privilegio.
- Criterios de aceptación:
  - existe tablero de actividad;
  - se pueden exportar reportes;
  - los reportes pueden parametrizarse por organización y período.
- Prioridad: Alta.
- Normas relacionadas: ISO 30301, ISO/IEC 27001, UIF.
- Módulo: `admin`, `audit`, `sector_*`.
- Observaciones sectoriales: AML y jurídico requieren reportes diferenciados.

## 5.8 Vertical inmobiliario

## RF-038 Legajo de cliente e inmueble

- Descripción: el sistema debe mantener un legajo unificado por operación inmobiliaria con clientes, inmueble, documentación y estado.
- Actor: corredor, backoffice.
- Precondiciones: vertical inmobiliario activo.
- Reglas de negocio: el legajo debe relacionar personas, operación, inmueble y documentos asociados.
- Criterios de aceptación:
  - se crea legajo por operación;
  - pueden asociarse múltiples personas y documentos;
  - el usuario visualiza la trazabilidad completa del caso.
- Prioridad: Alta.
- Normas relacionadas: ISO 15489, UIF 43/2024.
- Módulo: `sector_real_estate`.
- Observaciones sectoriales: debe servir tanto para locación como para compraventa.

## RF-039 KYC, beneficiario final y AML inmobiliario

- Descripción: el vertical inmobiliario debe capturar información KYC, documentación respaldatoria, perfil de riesgo y evidencias de análisis.
- Actor: oficial de cumplimiento, corredor.
- Precondiciones: legajo inmobiliario creado.
- Reglas de negocio: la operación no debe avanzar a cierto estado si falta documentación AML obligatoria.
- Criterios de aceptación:
  - se captura documentación de identificación;
  - se puede registrar beneficiario final y perfil de riesgo;
  - se generan alertas por faltantes o umbrales configurados.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.246, Ley 27.739, UIF 43/2024.
- Módulo: `sector_real_estate`, `workflow`.
- Observaciones sectoriales: parametrizar umbrales y eventos reportables.

## 5.9 Vertical jurídico

## RF-040 Gestión de asuntos, expedientes y evidencia jurídica

- Descripción: el sistema debe administrar asuntos jurídicos, expedientes, documentos de trabajo, presentaciones y evidencia.
- Actor: abogado, procurador, paralegal.
- Precondiciones: vertical jurídico activo.
- Reglas de negocio: cada asunto debe tener responsable, cliente, contraparte y clasificación.
- Criterios de aceptación:
  - se crea asunto con documentación asociada;
  - se organiza por hitos o carpetas;
  - se puede exportar evidencia del caso.
- Prioridad: Alta.
- Normas relacionadas: ISO 16175, Ley 25.506, IRAM 36100.
- Módulo: `sector_legal`, `documents`, `audit`.
- Observaciones sectoriales: debe distinguir documento de trabajo, presentado y reservado.

## RF-041 Muros éticos y privilegio profesional

- Descripción: el sistema debe permitir separar equipos o usuarios para evitar accesos impropios entre asuntos o clientes con conflicto.
- Actor: socio responsable, administrador de organización.
- Precondiciones: asunto creado.
- Reglas de negocio: el muro ético debe impedir visibilidad, búsqueda y acceso indirecto.
- Criterios de aceptación:
  - se configura un `ethical wall`;
  - usuarios no autorizados no ven ni el asunto ni sus documentos;
  - todo intento denegado queda registrado.
- Prioridad: Crítica.
- Normas relacionadas: Ley 25.326, buenas prácticas de secreto profesional, ISO/IEC 27002.
- Módulo: `sector_legal`, `auth`, `search`.
- Observaciones sectoriales: requisito diferencial para estudios y áreas legales internas.

## RF-042 Distinción entre defensa profesional y compliance UIF

- Descripción: el vertical jurídico debe diferenciar asuntos defensivos o no alcanzados de servicios u operaciones sujetas a requerimientos AML/CFT.
- Actor: oficial de cumplimiento, responsable jurídico.
- Precondiciones: asunto jurídico creado.
- Reglas de negocio: la clasificación del asunto condiciona formularios, controles y evidencias requeridas.
- Criterios de aceptación:
  - se puede tipificar el asunto;
  - el sistema cambia los controles visibles según tipificación;
  - queda fundada la clasificación adoptada.
- Prioridad: Alta.
- Normas relacionadas: Ley 25.246, Ley 27.739, UIF 48/2024.
- Módulo: `sector_legal`, `admin`.
- Observaciones sectoriales: evita sobrerregulación de asuntos no alcanzados y subcontrol de operaciones sí alcanzadas.

## 5.10 Vertical corporativo

## RF-043 Gestión de contratos corporativos

- Descripción: el sistema debe soportar ciclo básico de contratos: borrador, revisión, aprobación, firma, vigencia y renovación.
- Actor: usuario de negocio, compras, legales.
- Precondiciones: vertical corporativo activo.
- Reglas de negocio: cada contrato debe tener contraparte, vigencia, responsable y obligaciones documentales asociadas.
- Criterios de aceptación:
  - se crea carpeta contractual;
  - se versiona el documento;
  - se generan alertas por vencimiento o renovación.
- Prioridad: Alta.
- Normas relacionadas: ISO 30301, Ley 25.506.
- Módulo: `sector_corporate`, `workflow`, `documents`.
- Observaciones sectoriales: debe integrarse bien con firma posterior.

## RF-044 Archivo societario, contable y de respaldo

- Descripción: el sistema debe gestionar libros, actas, balances, comprobantes y documentación respaldatoria con plazos adecuados de conservación.
- Actor: administración, finanzas, legales.
- Precondiciones: vertical corporativo activo.
- Reglas de negocio: los tipos documentales societarios y contables deben tener retención reforzada y trazabilidad elevada.
- Criterios de aceptación:
  - se pueden clasificar actas, balances y soportes;
  - cada categoría hereda retención;
  - la exportación probatoria conserva contexto y secuencia.
- Prioridad: Alta.
- Normas relacionadas: CCyC arts. 328-330, ISO 15489.
- Módulo: `sector_corporate`, `records`.
- Observaciones sectoriales: útil para auditorías y litigios societarios.

## RF-045 Gestión documental de RR.HH. y proveedores

- Descripción: el sistema debe administrar documentación de personal, terceros y proveedores con controles de acceso diferenciados.
- Actor: RR.HH., compras, compliance.
- Precondiciones: vertical corporativo activo.
- Reglas de negocio: la documentación laboral y de terceros no debe ser visible para usuarios no autorizados.
- Criterios de aceptación:
  - se crean legajos de proveedor o empleado;
  - pueden adjuntarse vencimientos y certificados;
  - la consulta respeta clasificación sensible.
- Prioridad: Media.
- Normas relacionadas: Ley 25.326, ISO/IEC 27701.
- Módulo: `sector_corporate`, `auth`, `documents`.
- Observaciones sectoriales: importante para onboarding de terceros y control documental interno.

## 5.11 Validación, integridad y configuración dinámica

## RF-046 Validaciones de dominio por agregado y caso de uso

- Descripción: el sistema debe validar reglas de dominio antes de persistir o cambiar de estado cualquier entidad documental, expediente, legajo, workflow o configuración.
- Actor: sistema, usuario de negocio, administrador.
- Precondiciones: esquema de negocio y catálogos publicados.
- Reglas de negocio: las validaciones deben ejecutarse en backend aunque el frontend ya haya validado; una entidad inválida no puede avanzar de estado.
- Criterios de aceptación:
  - el backend rechaza documentos sin metadatos obligatorios o con estados incompatibles;
  - los mensajes de error identifican la regla violada;
  - el rechazo queda trazado cuando el evento es auditable.
- Prioridad: Crítica.
- Normas relacionadas: ISO 15489, ISO 23081, ISO 16175, OWASP ASVS.
- Módulo: `documents`, `records`, `workflow`, `admin`.
- Observaciones sectoriales: debe cubrir reglas específicas de AML, asuntos jurídicos y documentación societaria.

## RF-047 Validaciones referenciales entre entidades y catálogos

- Descripción: el sistema debe impedir referencias huérfanas o inconsistentes entre organizaciones, usuarios, documentos, expedientes, legajos, retenciones, holds, configuraciones y catálogos.
- Actor: sistema, administrador.
- Precondiciones: catálogos y entidades base existentes.
- Reglas de negocio: toda referencia a un objeto de negocio debe ser validada en capa de aplicación y reforzada con integridad relacional cuando corresponda.
- Criterios de aceptación:
  - no se puede asociar un documento a un expediente inexistente;
  - no se puede aplicar una política de retención no vigente;
  - las relaciones inválidas son rechazadas antes de persistir.
- Prioridad: Crítica.
- Normas relacionadas: CCyC, ISO 15489, ISO 23081.
- Módulo: `documents`, `records`, `admin`, `config`.
- Observaciones sectoriales: debe contemplar relaciones entre cliente, inmueble, operación y beneficiario final.

## RF-048 Validación estricta de tipos de datos, formatos y esquemas

- Descripción: el sistema debe validar tipos de datos, formatos, rangos, precision, unicidad lógica y compatibilidad de esquemas para datos estructurados y configuraciones.
- Actor: sistema, administrador de organización.
- Precondiciones: contratos, DTOs y esquemas versionados.
- Reglas de negocio: identificadores, fechas, importes, porcentajes, estados, enums y estructuras JSON deben ajustarse a contratos tipados explícitos.
- Criterios de aceptación:
  - un importe inválido o fuera de rango no se persiste;
  - una fecha inconsistente con la zona horaria o el flujo es rechazada;
  - una configuración JSON inválida no puede publicarse.
- Prioridad: Crítica.
- Normas relacionadas: ISO 23081, OWASP ASVS, NIST SSDF.
- Módulo: `admin`, `config`, `documents`, `integrations`.
- Observaciones sectoriales: clave para contratos, plazos legales, montos AML y metadatos con valor probatorio.

## RF-049 Configuración dinámica centralizada con Firebase Remote Config

- Descripción: el sistema debe administrar feature flags, parámetros operativos, umbrales, textos configurables y comportamiento no sensible mediante `Firebase Remote Config`.
- Actor: administrador de plataforma, administrador de organización.
- Precondiciones: proyecto Firebase configurado y credenciales de despliegue disponibles.
- Reglas de negocio: no se debe almacenar información confidencial ni secretos en Remote Config; toda publicación debe quedar versionada y poder revertirse.
- Criterios de aceptación:
  - se pueden publicar parámetros y condiciones por entorno o cohorte;
  - el sistema puede recuperar una versión anterior de configuración;
  - cada cambio de configuración queda asociado a autor y fecha.
- Prioridad: Alta.
- Normas relacionadas: NIST SSDF, OWASP ASVS.
- Módulo: `config`, `admin`.
- Observaciones sectoriales: útil para activar verticales, umbrales AML y experiencias diferenciadas por organización.

## RF-050 Uso de Cloud Firestore para datos no relacionales y proyecciones

- Descripción: el sistema debe utilizar `Cloud Firestore` para configuraciones extendidas, proyecciones de lectura, datos no relacionales y estados de experiencia que no reemplacen la verdad transaccional relacional.
- Actor: sistema, administrador de plataforma.
- Precondiciones: modelo de datos complementario definido.
- Reglas de negocio: Firestore no puede ser la fuente de verdad para retención, auditoría inmutable, relaciones críticas ni records regulados cuando la consistencia fuerte recaiga en PostgreSQL.
- Criterios de aceptación:
  - existen colecciones documentadas para datos no relacionales;
  - la sincronización con el core respeta ownership de datos;
  - las reglas de seguridad y acceso están definidas por colección.
- Prioridad: Alta.
- Normas relacionadas: ISO/IEC 27017, Firebase Security Rules.
- Módulo: `config`, `integrations`, `admin`.
- Observaciones sectoriales: conveniente para preferencias, dashboards materializados y configuraciones de organización no críticas.

## 6. Tipos y contratos públicos mínimos del dominio

- `Organización`
- `User`
- `Role`
- `Document`
- `DocumentVersion`
- `MetadataSchema`
- `ValidationRuleSet`
- `ReferenceCatalog`
- `ConfigProfile`
- `NonRelationalProjection`
- `FolderOrCase`
- `RetentionPolicy`
- `LegalHold`
- `AuditEvent`
- `SignatureEnvelope`
- `EvidencePackage`
- `SectorExtension`

Puertos mínimos:

- `IdentityPort`
- `StoragePort`
- `SearchPort`
- `OCRPort`
- `ConfigPort`
- `NoSqlPort`
- `SignatureProviderPort`
- `KmsPort`
- `NotificationPort`
- `AuditExportPort`

## 7. Plan de desarrollo por fases

| Fase | Objetivo | Entregables funcionales | Criterio de salida |
| --- | --- | --- | --- |
| 0 | análisis normativo y trazabilidad | matriz norma-requisito, glosario, backlog inicial | RF/RNF aprobados |
| 1 | fundación técnica y seguridad | skeleton modular, auth, organización única, auditoría, CI/CD, convenciones | plataforma base desplegable |
| 2 | núcleo documental | carga, metadatos, repositorio, búsqueda inicial, expedientes | operación documental básica estable |
| 3 | captura avanzada | OCR, clasificación asistida, notificaciones y workflows simples | productividad y búsquedas avanzadas operativas |
| 4 | records y compliance | retención, legal hold, record declaration, disposición, exportación probatoria | cumplimiento documental verificable |
| 5 | verticales sectoriales | inmobiliario, jurídico y corporativo | MVP sectorial demostrable |
| 6 | firma e integraciones | firma, sellado, APIs, conectores empresariales | interoperabilidad ampliada |
| 7 | hardening y salida | pentest, performance, DRP/BCP, piloto, observabilidad | go-live controlado |

## 8. Observaciones finales

- El MVP funcional no busca paridad total con Alfresco, pero sí cubrir las capacidades ECM esenciales para Argentina.
- La firma digital avanzada se deja preparada desde la fase 1 y se implementa funcionalmente en una fase posterior.
- La parametrización por organización y vertical es obligatoria para evitar forks del producto.




