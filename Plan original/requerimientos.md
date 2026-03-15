# Sistema de Gestión Documental (SGD) - Argentina
## Documento de Requerimientos

---

## 1. INTRODUCCIÓN

### 1.1 Propósito del Sistema
Desarrollar un Sistema de Gestión Documental (SGD) integral para PYMEs, estudios jurídicos, estudios contables, bibliotecas y organizaciones argentinas que requieran resguardar información con fines legales y administrativos, cumpliendo con normativas internacionales ISO y legislación nacional.

### 1.2 Alcance
El sistema cubrirá todo el ciclo de vida documental desde la creación/captura hasta la disposición final, garantizando trazabilidad, seguridad, cumplimiento legal y eficiencia operativa.

### 1.3 Marco Normativo

#### Normas ISO
- **ISO 30300/30301**: Sistema de gestión para documentos (MSR - Management System for Records)
- **ISO 9001**: Sistema de gestión de calidad
- **ISO 27001**: Sistema de gestión de seguridad de la información
- **ISO 15489**: Gestión de documentos y registros
- **ISO 23081**: Metadatos para la gestión de documentos

#### Legislación Argentina
- **Ley 25.506**: Firma Digital - Marco legal para firma electrónica y digital
- **Ley 25.326**: Protección de Datos Personales (Habeas Data)
- **Decreto 1023/2001**: Reglamentación de Firma Digital
- **Disposición 11/2006 DNPDP**: Medidas de seguridad para datos personales

---

## 2. REQUERIMIENTOS FUNCIONALES

### 2.1 Gestión del Ciclo de Vida Documental (ISO 15489, ISO 30301)

#### 2.1.1 Captura e Ingreso
- **REQ-F-001**: El sistema debe permitir la captura de documentos por múltiples vías:
  - Carga manual (drag & drop, formulario)
  - Escaneo directo con interfaz de control:
    - Selección de dispositivo (SANE/TWAIN compatible)
    - Configuración de resolución (200, 300, 600 DPI)
    - Modo de color (Color, Gris, B&N)
    - Soporte ADF y Duplex (doble cara)
  - Importación masiva (batch upload)
  - Captura desde email
  - Integración con sistemas externos vía API
  
- **REQ-F-002**: Debe capturar metadatos obligatorios y específicos según el tipo documental (ISO 23081):
  - **Metadatos Base**: Título, Autor, Fecha, Tipo, Clasificación, Serie/Expediente.
  - **Metadatos Dinámicos**: Capacidad de definir campos adicionales por tipo documental (ej: CUIT/Proveedor en Facturas, Escribano en Escrituras).


- **REQ-F-003**: Debe validar formato, tamaño y tipo de archivo permitido según políticas configurables

- **REQ-F-004**: Debe generar automáticamente metadatos técnicos:
  - Hash criptográfico (SHA-256 mínimo) para integridad
  - Timestamp de ingreso
  - Identificador único (UUID)
  - Formato y tamaño del archivo
  - Usuario que realizó la carga

#### 2.1.2 Clasificación y Organización
- **REQ-F-005**: Debe implementar un sistema de clasificación jerárquico basado en:
  - Cuadro de clasificación documental personalizable
  - Series y subseries documentales
  - Tipos documentales predefinidos y personalizables
  
- **REQ-F-006**: Debe permitir la gestión integral de expedientes/casos:
  - Creación de expedientes con numeración configurable (ej. EXP-YYYY-XXXX).
  - Metadatos de expediente: Título, Responsable, Prioridad (Baja, Media, Alta, Urgente), Estado (Activo, Pendiente, Cerrado, Archivado).
  - Asociación de documentos existentes a expedientes desde la interfaz de selección.
  - Trazabilidad de documentos dentro de un expediente.


- **REQ-F-007**: Debe soportar taxonomías y tesauros para facilitar búsqueda y recuperación

#### 2.1.3 Versionado Inmutable
- **REQ-F-008**: Debe implementar versionado automático con las siguientes características:
  - Cada modificación genera una nueva versión inmutable
  - Preservación de todas las versiones históricas
  - Registro de quién, cuándo y qué cambió
  - Imposibilidad de eliminar versiones anteriores
  - Versionado semántico (major.minor.patch) para control riguroso

- **REQ-F-009**: Debe bloquear la edición directa de documentos originales, requiriendo check-out/check-in

- **REQ-F-010**: Debe mantener cadena de custodia documental verificable

#### 2.1.4 Almacenamiento y Preservación
- **REQ-F-011**: Debe almacenar documentos con redundancia y respaldo automático

- **REQ-F-012**: Debe implementar estrategias de preservación digital a largo plazo:
  - Migración de formatos obsoletos
  - Validación periódica de integridad (verificación de hash)
  - Almacenamiento en formatos abiertos y estándares (PDF/A para documentos finales)

- **REQ-F-013**: Debe soportar almacenamiento en diferentes capas según criticidad:
  - Almacenamiento primario (alto rendimiento)
  - Almacenamiento secundario (archivo histórico)
  - Almacenamiento en frío (documentos de largo plazo)

#### 2.1.5 Búsqueda y Recuperación
- **REQ-F-014**: Debe proveer búsqueda avanzada por:
  - Metadatos (todos los campos)
  - Texto completo (OCR para documentos escaneados)
  - Rangos de fechas
  - Tipo documental
  - Estado del documento
  - Expediente/Serie
  - Tags y categorías

- **REQ-F-015**: Debe implementar filtros dinámicos y búsqueda facetada

- **REQ-F-016**: Debe mostrar resultados con vista previa sin necesidad de descarga

- **REQ-F-017**: Debe registrar auditoría de todas las búsquedas realizadas

#### 2.1.6 Retención y Disposición Automática
- **REQ-F-018**: Debe implementar tablas de retención documental configurables por:
  - Tipo de documento
  - Serie documental
  - Requisitos legales específicos
  - Valor administrativo, legal, fiscal o histórico

- **REQ-F-019**: Debe calcular automáticamente fechas de disposición final basándose en:
  - Fecha de creación + período de retención
  - Eventos disparadores (cierre de caso, finalización de proyecto)

- **REQ-F-020**: Debe notificar proactivamente antes de vencimientos de retención

- **REQ-F-021**: Debe ejecutar disposiciones finales según políticas:
  - Eliminación segura (borrado criptográfico certificado)
  - Transferencia a archivo histórico
  - Marcado como preservación permanente
  - Exportación para custodia externa

- **REQ-F-022**: Debe requerir aprobación multinivel para disposiciones críticas

- **REQ-F-023**: Debe generar certificados de destrucción documental

#### 2.1.7 Workflow y Procesos
- **REQ-F-024**: Debe implementar motor de workflows configurable para:
  - Revisión y aprobación de documentos
  - Firmas múltiples en cascada
  - Notificaciones y recordatorios automáticos
  - Escalamiento por incumplimiento de plazos

- **REQ-F-025**: Debe soportar workflows paralelos y condicionales

- **REQ-F-026**: Debe permitir delegación temporal de tareas

### 2.2 Control de Accesos y Seguridad (ISO 27001)

#### 2.2.1 Autenticación
- **REQ-F-027**: Debe implementar autenticación multifactor (MFA) obligatoria para:
  - Administradores
  - Usuarios con permisos de firma
  - Acceso a documentos clasificados como confidenciales

- **REQ-F-028**: Debe soportar integración con:
  - Active Directory / LDAP
  - OAuth 2.0 / OpenID Connect
  - SAML para SSO corporativo

- **REQ-F-029**: Debe implementar políticas de contraseñas robustas:
  - Mínimo 12 caracteres
  - Complejidad (mayúsculas, minúsculas, números, símbolos)
  - Expiración configurable
  - Historial de contraseñas (prevenir reutilización)

- **REQ-F-030**: Debe bloquear cuentas tras intentos fallidos configurables

#### 2.2.2 Autorización y RBAC
- **REQ-F-031**: Debe implementar control de acceso basado en roles (RBAC) con:
  - Roles predefinidos (Administrador, Gestor Documental, Usuario, Auditor, Invitado)
  - Roles personalizables por organización
  - Asignación de permisos granulares

- **REQ-F-032**: Debe soportar permisos a nivel de:
  - Documento individual
  - Serie/Expediente
  - Tipo documental
  - Área organizacional

- **REQ-F-033**: Debe implementar matriz de permisos con acciones:
  - Crear
  - Leer/Ver
  - Editar/Modificar
  - Eliminar
  - Descargar
  - Imprimir
  - Compartir
  - Firmar
  - Aprobar
  - Administrar metadatos
  - Gestionar permisos

- **REQ-F-034**: Debe implementar herencia de permisos con capacidad de override

- **REQ-F-035**: Debe soportar grupos de usuarios para asignación masiva de permisos

- **REQ-F-036**: Debe implementar segregación de funciones críticas (SoD - Separation of Duties)

#### 2.2.3 Clasificación de Información
- **REQ-F-037**: Debe implementar niveles de clasificación de seguridad:
  - Público
  - Interno
  - Confidencial
  - Estrictamente Confidencial

- **REQ-F-038**: Debe aplicar marcas visuales (watermarks) según clasificación

- **REQ-F-039**: Debe restringir acciones según clasificación (ej: documentos confidenciales no descargables)

### 2.3 Firma Digital y Trazabilidad Legal (Ley 25.506)

#### 2.3.1 Firma Digital
- **REQ-F-040**: Debe implementar firma digital conforme a Ley 25.506 y Decreto 1023/2001:
  - Integración con Certificadores Licenciados argentinos.
  - Soporte para certificados X.509 v3.
  - Interfaz de firma con vista previa interactiva del documento.
  - Visualización detallada del certificado: Titular, CUIL, Emisor, Fechas de validez.
  - Uso de algoritmos aprobados por PKI argentina.

- **REQ-F-041**: Debe soportar múltiples tipos de firma:
  - Firma simple (electrónica)
  - Firma avanzada
  - Firma digital calificada (con certificado homologado)

- **REQ-F-042**: Debe permitir firma de documentos individuales y lotes

- **REQ-F-043**: Debe validar certificados en tiempo real:
  - Verificación de vigencia
  - Consulta a listas de revocación (CRL)
  - Validación OCSP (Online Certificate Status Protocol)

- **REQ-F-044**: Debe incrustar firma en el documento (formato PAdES para PDFs)

- **REQ-F-045**: Debe soportar firmas múltiples y contrafirmas

- **REQ-F-046**: Debe generar evidencia de firma con timestamp certificado (TSA - Time Stamping Authority)

#### 2.3.2 Estampado de Tiempo
- **REQ-F-047**: Debe integrar con Autoridad de Sellado de Tiempo (TSA) certificada

- **REQ-F-048**: Debe aplicar timestamp a:
  - Ingreso de documentos
  - Modificaciones
  - Firmas digitales
  - Eventos críticos de auditoría

#### 2.3.3 No Repudio
- **REQ-F-049**: Debe garantizar no repudio mediante:
  - Evidencia criptográfica de firma
  - Registro inmutable de acciones
  - Cadena de custodia verificable

### 2.4 Auditoría y Trazabilidad Completa (ISO 30301, ISO 27001)

#### 2.4.1 Registro de Auditoría
- **REQ-F-050**: Debe registrar en log de auditoría inmutable:
  - Evento realizado (acción específica)
  - Usuario que ejecutó la acción
  - Fecha y hora exacta (timestamp)
  - Dirección IP y metadata del dispositivo
  - Resultado de la acción (éxito/fallo)
  - Datos antes/después del cambio (para modificaciones)

- **REQ-F-051**: Debe auditar como mínimo:
  - Autenticación (login exitoso y fallido)
  - Acceso a documentos (visualización, descarga, impresión)
  - Modificaciones de documentos
  - Cambios en metadatos
  - Creación/eliminación de documentos
  - Cambios de permisos
  - Cambios de configuración del sistema
  - Firmas digitales
  - Exportaciones masivas
  - Búsquedas realizadas

- **REQ-F-052**: Debe implementar logs de auditoría con:
  - Almacenamiento inmutable (append-only)
  - Protección criptográfica (firma de logs)
  - Redundancia geográfica
  - Retención mínima según normativa (10 años recomendado)

- **REQ-F-053**: Debe prevenir modificación o eliminación de registros de auditoría

- **REQ-F-054**: Debe alertar ante intentos de acceso no autorizado o comportamientos anómalos

#### 2.4.2 Reportes de Auditoría
- **REQ-F-055**: Debe generar reportes de auditoría configurables:
  - Por usuario
  - Por documento/expediente
  - Por período de tiempo
  - Por tipo de acción
  - Por resultado (exitoso/fallido)

- **REQ-F-056**: Debe exportar reportes en formatos estándar (PDF, CSV, Excel)

- **REQ-F-057**: Debe permitir a auditores acceso de solo lectura a logs sin permisos sobre documentos

#### 2.4.3 Cadena de Custodia
- **REQ-F-058**: Debe mantener cadena de custodia completa de cada documento:
  - Histórico de poseedores
  - Transferencias entre usuarios/áreas
  - Modificaciones realizadas
  - Firmas aplicadas
  - Accesos realizados

- **REQ-F-059**: Debe generar certificado de cadena de custodia exportable

### 2.5 Protección de Datos Personales (Ley 25.326)

#### 2.5.1 Identificación de Datos Sensibles
- **REQ-F-060**: Debe permitir etiquetar documentos que contengan datos personales según Ley 25.326

- **REQ-F-061**: Debe clasificar datos personales en:
  - Datos personales comunes
  - Datos sensibles (origen racial, opiniones políticas, religiosas, salud, vida sexual, antecedentes penales)

- **REQ-F-062**: Debe implementar detección automática de datos sensibles (DLP - Data Loss Prevention)

#### 2.5.2 Derechos de Titulares
- **REQ-F-063**: Debe facilitar ejercicio de derechos ARCO:
  - **Acceso**: Búsqueda de documentos que contengan datos de una persona
  - **Rectificación**: Actualización de datos incorrectos
  - **Cancelación**: Eliminación de datos cuando corresponda
  - **Oposición**: Bloqueo de tratamiento de datos

- **REQ-F-064**: Debe registrar solicitudes de titulares y respuestas dadas

- **REQ-F-065**: Debe generar reportes de cumplimiento de plazos (10 días hábiles según ley)

#### 2.5.3 Anonimización y Pseudonimización
- **REQ-F-066**: Debe ofrecer herramientas de anonimización/pseudonimización para:
  - Vistas de documentos con datos sensibles redactados
  - Exportaciones para análisis estadístico
  - Compartición con terceros

#### 2.5.4 Transferencia Internacional
- **REQ-F-067**: Debe controlar y registrar transferencias internacionales de datos personales

- **REQ-F-068**: Debe validar nivel de protección adecuado en país destino

### 2.6 Colaboración y Compartición

#### 2.6.1 Compartición Interna
- **REQ-F-069**: Debe permitir compartir documentos/expedientes con:
  - Usuarios individuales
  - Grupos/Equipos
  - Áreas organizacionales

- **REQ-F-070**: Debe especificar permisos y vigencia de compartición

- **REQ-F-071**: Debe notificar a destinatarios de nuevos documentos compartidos

#### 2.6.2 Compartición Externa
- **REQ-F-072**: Debe permitir compartición segura con externos mediante:
  - Enlaces con expiración temporal
  - Acceso con contraseña
  - Límite de descargas/visualizaciones
  - Marca de agua con identificación del receptor

- **REQ-F-073**: Debe registrar auditoría de accesos externos

#### 2.6.3 Comentarios y Anotaciones
- **REQ-F-074**: Debe permitir comentarios/anotaciones sobre documentos sin modificar el original

- **REQ-F-075**: Debe mantener hilo de conversación asociado a documentos

### 2.7 Integración y Extensibilidad

#### 2.7.1 APIs
- **REQ-F-076**: Debe proveer API RESTful completa para:
  - Carga y descarga de documentos
  - Gestión de metadatos
  - Búsquedas
  - Gestión de permisos
  - Consulta de auditoría

- **REQ-F-077**: Debe implementar autenticación API mediante tokens (JWT, API Keys)

- **REQ-F-078**: Debe proveer documentación OpenAPI/Swagger

- **REQ-F-079**: Debe implementar rate limiting y throttling

#### 2.7.2 Integraciones Predefinidas
- **REQ-F-080**: Debe integrarse con herramientas comunes:
  - Microsoft Office (edición online de documentos)
  - Suites ofimáticas (Google Workspace, LibreOffice)
  - Clientes de email
  - Sistemas ERP/CRM comunes en Argentina

#### 2.7.3 Webhooks
- **REQ-F-081**: Debe soportar webhooks para notificación de eventos a sistemas externos

### 2.8 Reportes y Analytics

#### 2.8.1 Dashboards
- **REQ-F-082**: Debe proveer dashboards configurables con:
  - Stats Cards principales:
    - Volumen documental total (con tendencia mensual).
    - Aprobaciones pendientes (identificando urgentes).
    - Documentos próximos a vencer retención (próximos 30 días).
    - Uso de espacio de almacenamiento (porcentaje y capacidad libre).
  - Gráficos de actividad reciente.
  - Alertas del sistema (intentos de acceso, backups, vencimientos).

#### 2.8.2 Reportes Gerenciales
- **REQ-F-083**: Debe generar reportes de:
  - Cumplimiento de políticas de retención
  - Estadísticas de uso
  - Tiempos de respuesta en workflows
  - Documentos sin clasificar
  - Usuarios inactivos
  - Documentos huérfanos (sin asignación)

---

## 3. REQUERIMIENTOS NO FUNCIONALES

### 3.1 Rendimiento
- **REQ-NF-001**: Tiempo de respuesta de búsquedas < 2 segundos para el 95% de consultas
- **REQ-NF-002**: Tiempo de carga de vista previa < 3 segundos
- **REQ-NF-003**: Debe soportar carga concurrente de al menos 100 usuarios simultáneos
- **REQ-NF-004**: Debe procesar ingesta masiva de al menos 1000 documentos/hora
- **REQ-NF-005**: Debe soportar repositorios de hasta 10TB inicialmente con escalabilidad a más

### 3.2 Disponibilidad
- **REQ-NF-006**: Disponibilidad del sistema ≥ 99.5% (downtime máximo ~3.65 horas/mes)
- **REQ-NF-007**: Ventanas de mantenimiento programadas fuera de horario laboral
- **REQ-NF-008**: RTO (Recovery Time Objective) < 4 horas
- **REQ-NF-009**: RPO (Recovery Point Objective) < 1 hora

### 3.3 Escalabilidad
- **REQ-NF-010**: Arquitectura horizontal escalable para crecer con la organización
- **REQ-NF-011**: Debe soportar multitenancy para ofrecer como servicio cloud
- **REQ-NF-012**: Debe particionar/archivar automáticamente datos históricos

### 3.4 Seguridad

#### 3.4.1 Cifrado
- **REQ-NF-013**: Cifrado en tránsito mediante TLS 1.3
- **REQ-NF-014**: Cifrado en reposo de documentos y base de datos (AES-256)
- **REQ-NF-015**: Gestión segura de claves mediante HSM o servicios KMS

#### 3.4.2 Hardening
- **REQ-NF-016**: Sistema operativo y aplicaciones con parches de seguridad actualizados
- **REQ-NF-017**: Principio de mínimo privilegio en todos los niveles
- **REQ-NF-018**: Segmentación de red (separación frontend/backend/datos)
- **REQ-NF-019**: Firewall de aplicación web (WAF)
- **REQ-NF-020**: Protección anti-DDoS

#### 3.4.3 Monitoreo de Seguridad
- **REQ-NF-021**: Sistema de detección de intrusos (IDS/IPS)
- **REQ-NF-022**: SIEM para correlación de eventos de seguridad
- **REQ-NF-023**: Escaneo de vulnerabilidades periódico
- **REQ-NF-024**: Análisis estático de código (SAST) en desarrollo
- **REQ-NF-025**: Análisis dinámico (DAST) pre-producción

### 3.5 Usabilidad
- **REQ-NF-026**: Interfaz intuitiva con curva de aprendizaje < 2 horas para usuario básico.
- **REQ-NF-026-B**: Feedback visual inline para validación de formularios:
  - Uso de bordes de colores (Rojo para error, Verde para éxito) en los inputs.
  - Mensajes de error descriptivos ubicados inmediatamente debajo del campo afectado.
  - Evitar el uso de diálogos de alerta (popups) para validaciones de campos individuales.
- **REQ-NF-027**: Diseño responsive basado en Material Design 3 para acceso desde desktop, tablet y móvil.
- **REQ-NF-028**: Interfaz en español argentino con opción multiidioma
- **REQ-NF-029**: Accesibilidad WCAG 2.1 nivel AA
- **REQ-NF-030**: Tooltips y ayuda contextual

### 3.6 Compatibilidad
- **REQ-NF-031**: Navegadores soportados: Chrome, Firefox, Edge, Safari (últimas 2 versiones)
- **REQ-NF-032**: Soporte de formatos documentales:
  - Ofimática: PDF, DOCX, DOC, XLSX, XLS, PPTX, PPT, ODT, ODS
  - Imágenes: JPG, PNG, TIFF, BMP, GIF
  - CAD: DWG, DXF (para estudios técnicos)
  - Email: MSG, EML
  - Comprimidos: ZIP, RAR
- **REQ-NF-033**: OCR para escaneos e imágenes

### 3.7 Mantenibilidad
- **REQ-NF-034**: Código modular y bien documentado
- **REQ-NF-035**: Logs estructurados para troubleshooting
- **REQ-NF-036**: Despliegue mediante contenedores (Docker/Kubernetes)
- **REQ-NF-037**: CI/CD para actualizaciones frecuentes y seguras

### 3.8 Backup y Recuperación
- **REQ-NF-038**: Backup automático diario incremental
- **REQ-NF-039**: Backup semanal completo
- **REQ-NF-040**: Retención de backups: diarios 30 días, semanales 12 semanas, mensuales 12 meses
- **REQ-NF-041**: Backups cifrados
- **REQ-NF-042**: Almacenamiento de backups en ubicación geográfica diferente
- **REQ-NF-043**: Pruebas de restauración trimestrales

### 3.9 Licenciamiento
- **REQ-NF-044**: Uso preferente de software libre/open source (FOSS)
- **REQ-NF-045**: Evitar vendor lock-in mediante estándares abiertos

---

## 4. ARQUITECTURA TÉCNICA PROPUESTA

### 4.1 Stack Tecnológico (Herramientas Open Source)

#### 4.1.1 Backend
- **Lenguaje y Framework**: **Go (Golang) 1.21+**
  - **Framework Web**: Gin o Fiber (alto rendimiento, bajo footprint)
  - **Arquitectura**: Clean Architecture + MVVM
  - **Estructura**: Modular usando plugin conventions
  
- **Gestor Documental Base**: 
  - **Alfresco Community Edition**: Sistema ECM maduro, open source
  - **Nuxeo Platform**: Alternativa moderna y extensible
  - **Desarrollo a medida** sobre framework elegido

#### 4.1.2 Base de Datos
- **Metadatos y Relacional**: PostgreSQL 15+
- **Documental/NoSQL**: MongoDB o CouchDB (para metadatos flexibles)
- **Full-Text Search**: Elasticsearch o Apache Solr

#### 4.1.3 Almacenamiento
- **Sistema de archivos**: 
  - MinIO (S3-compatible, open source)
  - Ceph (almacenamiento distribuido)
  - Sistema de archivos local con redundancia RAID

#### 4.1.4 Frontend

##### Opción 1: Flutter (Multiplataforma)
- **Framework**: Flutter 3.x (Dart)
- **Arquitectura**: MVVM + Clean Architecture
- **UI**: Material Design 3 / Cupertino
- **Gestión de Estado**: Riverpod o Bloc
- **Navegación**: go_router
- **Plataformas**: Web, Android, iOS, Windows, Linux, macOS

##### Opción 2: Kotlin Multiplatform + Jetpack Compose
- **KMP**: Kotlin Multiplatform para lógica compartida
- **UI Android/Desktop**: Jetpack Compose Desktop
- **UI iOS**: Compose Multiplatform (experimental) o SwiftUI nativo
- **UI Web**: Compose for Web (Kotlin/JS)
- **Arquitectura**: MVVM + Clean Architecture
- **Inyección de Dependencias**: Koin
- **Navegación**: Voyager o Decompose

##### Estructura Modular (Ambas opciones)
- **Plugin Conventions**: Separación en módulos/features independientes
- **Core Module**: Utilidades, networking, persistencia compartida
- **Feature Modules**: Cada funcionalidad como módulo independiente
- **Domain Layer**: Use cases y entidades de negocio
- **Data Layer**: Repositories, data sources (remote/local)
- **Presentation Layer**: ViewModels, UI components

#### 4.1.5 Seguridad y Autenticación
- **Autenticación**: Keycloak (Identity and Access Management open source)
- **Firma Digital**: 
  - DSS (Digital Signature Service) de European Commission
  - Integración con certificadores argentinos vía PKCS#11
- **Cifrado**: OpenSSL, GnuPG

#### 4.1.6 OCR y Procesamiento
- **OCR**: Tesseract OCR
- **Conversión de formatos**: LibreOffice headless, ImageMagick, Ghostscript
- **Procesamiento de PDFs**: PyPDF2, pdf.js

#### 4.1.7 Mensajería y Colas
- **Message Broker**: RabbitMQ o Apache Kafka
- **Task Queue**: 
  - **Para Go**: Asynq (Redis-based) o Machinery
  - Workers concurrentes nativos de Go (goroutines + channels)

#### 4.1.8 Monitoreo y Logs
- **Logs**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Monitoreo**: Prometheus + Grafana
- **APM**: Jaeger para tracing distribuido

#### 4.1.9 Contenedores y Orquestación
- **Contenedores**: Docker
- **Orquestación**: Kubernetes (K8s) o Docker Swarm

### 4.2 Arquitectura Clean Architecture + MVVM

#### 4.2.1 Capas de Clean Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ UI (Flutter/Compose) ←→ ViewModel (MVVM Pattern)           │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                ↓↑
┌──────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Use Cases (Interactors) + Entities + Repository Interfaces │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                ↓↑
┌──────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                               │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Repository Impl + Data Sources (Remote API, Local DB)      │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

#### 4.2.2 Estructura Modular por Features

```
/sgd-backend (Golang)
├── cmd/
│   └── api/              # Entry point principal
├── internal/
│   ├── core/             # Módulo core compartido
│   │   ├── domain/       # Entidades de negocio
│   │   ├── ports/        # Interfaces (repositories, services)
│   │   └── utils/        # Utilidades compartidas
│   ├── features/         # Módulos por funcionalidad
│   │   ├── document-management/
│   │   │   ├── domain/       # Entidades del módulo
│   │   │   ├── usecase/      # Casos de uso
│   │   │   ├── repository/   # Implementación de repos
│   │   │   ├── handler/      # HTTP handlers (presentation)
│   │   │   └── dto/          # Data Transfer Objects
│   │   ├── authentication/
│   │   ├── digital-signature/
│   │   ├── audit/
│   │   ├── retention/
│   │   └── workflow/
│   ├── adapters/         # Adaptadores externos
│   │   ├── postgres/
│   │   ├── mongodb/
│   │   ├── minio/
│   │   ├── elasticsearch/
│   │   └── keycloak/
│   └── infrastructure/   # Configuración, middleware
├── pkg/                  # Paquetes públicos reutilizables
└── api/                  # OpenAPI specs

/sgd-frontend (Flutter o KMP)
├── lib/ (Flutter) o src/ (KMP)
│   ├── core/
│   │   ├── network/      # HTTP client, interceptors
│   │   ├── storage/      # Local persistence
│   │   ├── di/           # Dependency Injection
│   │   └── utils/
│   ├── features/
│   │   ├── document_management/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/  # Interfaces
│   │   │   │   └── usecases/
│   │   │   ├── data/
│   │   │   │   ├── models/        # DTOs
│   │   │   │   ├── datasources/   # Remote/Local
│   │   │   │   └── repositories/  # Implementaciones
│   │   │   └── presentation/
│   │   │       ├── viewmodels/
│   │   │       ├── pages/
│   │   │       └── widgets/
│   │   ├── authentication/
│   │   ├── search/
│   │   ├── audit/
│   │   └── settings/
│   └── app/              # App configuration, routes
```

#### 4.2.3 Plugin Conventions

**Backend (Golang)**:
```go
// Cada feature expone un plugin con interfaz estándar
type Feature interface {
    Name() string
    RegisterRoutes(router *gin.Engine)
    RegisterDependencies(container *di.Container)
    Migrate(db *sql.DB) error
}

// Registro automático de features
func main() {
    features := []Feature{
        documentmanagement.NewFeature(),
        authentication.NewFeature(),
        audit.NewFeature(),
    }
    // Inicialización dinámica
}
```

**Frontend (Flutter con build.yaml / KMP con Gradle Convention Plugins)**:
- Cada feature como paquete/módulo independiente
- Configuración mediante convention plugins
- Dependencias explícitas entre módulos

### 4.3 Módulos del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                      │
├─────────────────────────────────────────────────────────────┤
│  App Mobile  │  Portal Web  │  API REST  │  Integraciones   │
│ (Flutter/KMP)│              │  (Golang)  │                  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   CAPA DE AUTENTICACIÓN                      │
├─────────────────────────────────────────────────────────────┤
│   Keycloak    │    MFA     │   SSO/SAML  │   LDAP/AD        │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     CAPA DE SERVICIOS                        │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   Gestión    │  Versionado  │  Búsqueda y  │  Workflow y    │
│  Documental  │  y Auditoría │  Recuperación│   Procesos     │
├──────────────┼──────────────┼──────────────┼────────────────┤
│   Firma      │  Seguridad y │  Retención y │  Reportes y    │
│   Digital    │   Control    │  Disposición │   Analytics    │
│              │   Accesos    │              │                │
└──────────────┴──────────────┴──────────────┴────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE DATOS                             │
├──────────────┬──────────────┬──────────────┬────────────────┤
│  PostgreSQL  │   MongoDB    │Elasticsearch │   MinIO/Ceph   │
│  (Metadatos) │ (Flexible)   │  (Búsqueda)  │ (Archivos)     │
└──────────────┴──────────────┴──────────────┴────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                  CAPA DE INFRAESTRUCTURA                     │
├─────────────────────────────────────────────────────────────┤
│  Kubernetes  │  Docker  │  ELK Stack  │  Prometheus/Grafana│
└─────────────────────────────────────────────────────────────┘
```

### 4.4 Modelo de Datos Básico

#### 4.4.1 Entidades Principales (Domain Layer)

**Ejemplo en Golang**:
```go
// internal/core/domain/document.go
package domain

import (
    "time"
    "github.com/google/uuid"
)

type Document struct {
    ID                  uuid.UUID
    Title               string
    ContentHash         string    // SHA-256
    Format              string
    Size                int64
    Status              DocumentStatus
    SecurityClass       SecurityClassification
    CreatedAt           time.Time
    UpdatedAt           time.Time
    CreatedBy           uuid.UUID
    CurrentVersion      int
    RetentionDate       *time.Time
    DispositionAction   DispositionType
}

type DocumentVersion struct {
    ID          uuid.UUID
    DocumentID  uuid.UUID
    Version     string    // Semantic versioning: 1.0.0
    ContentHash string
    CreatedAt   time.Time
    CreatedBy   uuid.UUID
    Changes     string
    FilePath    string    // MinIO object path
}

type DocumentMetadata struct {
    DocumentID  uuid.UUID
    Key         string
    Value       string
    Type        MetadataType
}

type DocumentSeries struct {
    ID              uuid.UUID
    Name            string
    Description     string
    RetentionYears  int
    Classification  SecurityClassification
    ParentID        *uuid.UUID  // Para jerarquías
}

type Expediente struct {
    ID              uuid.UUID
    Number          string
    SeriesID        uuid.UUID
    OpenedAt        time.Time
    ClosedAt        *time.Time
    ResponsibleID   uuid.UUID
    Status          ExpedienteStatus
}

type User struct {
    ID              uuid.UUID
    Username        string
    Email           string
    PasswordHash    string
    MFAEnabled      bool
    MFASecret       string
    RoleIDs         []uuid.UUID
    IsActive        bool
}

type Role struct {
    ID          uuid.UUID
    Name        string
    Description string
    Permissions []Permission
}

type Permission struct {
    ID       uuid.UUID
    Resource string    // "document", "user", "audit"
    Action   string    // "create", "read", "update", "delete", "sign"
}

type AuditLog struct {
    ID          uuid.UUID
    Timestamp   time.Time
    UserID      uuid.UUID
    Action      string
    ResourceID  uuid.UUID
    ResourceType string
    IPAddress   string
    UserAgent   string
    Result      AuditResult
    Details     map[string]interface{}
}

// Enums
type DocumentStatus string
const (
    StatusDraft      DocumentStatus = "draft"
    StatusActive     DocumentStatus = "active"
    StatusArchived   DocumentStatus = "archived"
    StatusDisposed   DocumentStatus = "disposed"
)

type SecurityClassification string
const (
    ClassPublic         SecurityClassification = "public"
    ClassInternal       SecurityClassification = "internal"
    ClassConfidential   SecurityClassification = "confidential"
    ClassStrictConfidential SecurityClassification = "strict_confidential"
)

type DispositionType string
const (
    DispositionDelete   DispositionType = "delete"
    DispositionArchive  DispositionType = "archive"
    DispositionPreserve DispositionType = "preserve"
    DispositionTransfer DispositionType = "transfer"
)
```

#### 4.4.2 Repositorios (Puertos - Interfaces)

```go
// internal/core/ports/document_repository.go
package ports

type DocumentRepository interface {
    Create(ctx context.Context, doc *domain.Document) error
    GetByID(ctx context.Context, id uuid.UUID) (*domain.Document, error)
    Update(ctx context.Context, doc *domain.Document) error
    Delete(ctx context.Context, id uuid.UUID) error
    Search(ctx context.Context, filters SearchFilters) ([]*domain.Document, error)
    GetByRetentionDate(ctx context.Context, date time.Time) ([]*domain.Document, error)
}

type DocumentVersionRepository interface {
    CreateVersion(ctx context.Context, version *domain.DocumentVersion) error
    GetVersions(ctx context.Context, documentID uuid.UUID) ([]*domain.DocumentVersion, error)
    GetVersion(ctx context.Context, versionID uuid.UUID) (*domain.DocumentVersion, error)
}

type AuditRepository interface {
    Log(ctx context.Context, log *domain.AuditLog) error
    Search(ctx context.Context, filters AuditFilters) ([]*domain.AuditLog, error)
}
```

### 4.5 Seguridad en Profundidad (Defense in Depth)

```
Capa 1: Perímetro de Red
  ├── Firewall
  ├── WAF (Web Application Firewall)
  └── Anti-DDoS

Capa 2: Aplicación
  ├── Autenticación MFA
  ├── Control de sesiones
  ├── CSRF/XSS Protection
  └── Input Validation

Capa 3: Datos
  ├── Cifrado en tránsito (TLS 1.3)
  ├── Cifrado en reposo (AES-256)
  └── Hashing de contraseñas (bcrypt/Argon2)

Capa 4: Infraestructura
  ├── OS Hardening
  ├── Segmentación de red
  ├── Principio de mínimo privilegio
  └── Parches automatizados

Capa 5: Monitoreo y Respuesta
  ├── IDS/IPS
  ├── SIEM
  ├── Vulnerability Scanning
  └── Incident Response Plan
```

---

## 5. CUMPLIMIENTO NORMATIVO - MATRIZ DE TRAZABILIDAD

| Norma/Ley | Requisito Clave | Requerimientos SGD |
|-----------|-----------------|-------------------|
| **ISO 30301** | Sistema de gestión para documentos | REQ-F-001 a REQ-F-026 (Ciclo de vida completo) |
| **ISO 15489** | Gestión de documentos y registros | REQ-F-005 a REQ-F-023 (Clasificación, retención) |
| **ISO 23081** | Metadatos para gestión documental | REQ-F-002, REQ-F-004 (Captura metadatos) |
| **ISO 9001** | Gestión de calidad | REQ-F-024 a REQ-F-026 (Workflows), REQ-F-082, REQ-F-083 (Reportes) |
| **ISO 27001** | Seguridad de la información | REQ-F-027 a REQ-F-039 (Autenticación, control accesos), REQ-NF-013 a REQ-NF-025 (Seguridad técnica) |
| **Ley 25.506** | Firma Digital Argentina | REQ-F-040 a REQ-F-049 (Firma digital, no repudio) |
| **Ley 25.326** | Protección Datos Personales | REQ-F-060 a REQ-F-068 (Datos sensibles, derechos ARCO) |

---

## 6. CASOS DE USO POR SECTOR

### 6.1 Estudio Jurídico
**Escenarios**:
- Gestión de expedientes judiciales con vencimientos
- Firma de escrituras y contratos con validez legal
- Preservación de documentación probatoria con cadena de custodia
- Control de versiones de documentos legales
- Auditoría de accesos a casos confidenciales

**Flujo típico**: 
1. Ingreso de expediente nuevo (demanda, contrato, etc.)
2. Carga de documentación respaldatoria
3. Asignación a abogado responsable
4. Workflow de revisión y firma
5. Almacenamiento con retención legal obligatoria
6. Consulta y recuperación para audiencias
7. Disposición final tras sentencia firme + período legal

### 6.2 Estudio Contable
**Escenarios**:
- Gestión de documentación fiscal (facturas, recibos, balances)
- Retención por períodos legales (10 años para documentación impositiva)
- Firma digital de declaraciones juradas
- Auditoría para inspecciones de AFIP
- Compartición segura con clientes

**Flujo típico**:
1. Ingreso de documentación contable mensual de cliente
2. Clasificación por tipo (factura, recibo, balance, DDJJ)
3. Proceso de revisión y firma digital
4. Presentación a AFIP con constancia
5. Almacenamiento con retención automática de 10 años
6. Generación de reportes para auditorías

### 6.3 PYME
**Escenarios**:
- Gestión de contratos con proveedores/clientes
- Documentación de RRHH (legajos, contratos, recibos de sueldo)
- Manuales de procedimientos ISO 9001
- Registros de calidad y trazabilidad
- Control de documentación técnica de productos

**Flujo típico**:
1. Digitalización de legajos de empleados
2. Carga de contratos laborales con firma digital
3. Versionado de manuales de procedimientos
4. Control de acceso por departamento
5. Retención según normativa laboral
6. Facilitación de auditorías de calidad

### 6.4 Biblioteca
**Escenarios**:
- Digitalización de fondos documentales históricos
- Preservación digital de largo plazo
- Catálogo y búsqueda de materiales
- Control de préstamos y consultas
- Acceso público controlado a colecciones digitales

**Flujo típico**:
1. Escaneo de materiales con OCR
2. Catalogación con metadatos estandarizados
3. Clasificación y organización temática
4. Publicación controlada para consulta
5. Registro de accesos para estadísticas
6. Preservación permanente con migración de formatos

---

## 7. PLAN DE IMPLEMENTACIÓN SUGERIDO

### Fase 1: MVP (Mínimo Producto Viable) - 3 meses
- **Objetivos**:
  - Ingesta básica de documentos
  - Almacenamiento seguro con cifrado
  - Búsqueda por metadatos
  - Control de accesos RBAC básico
  - Auditoría de acciones críticas
  - Interfaz web funcional

### Fase 2: Cumplimiento Legal - 2 meses
- **Objetivos**:
  - Integración con firma digital argentina
  - Versionado inmutable completo
  - Retención y disposición automática
  - Cumplimiento Ley 25.326 (Protección Datos Personales)
  - Certificación de auditoría

### Fase 3: Workflows y Colaboración - 2 meses
- **Objetivos**:
  - Motor de workflows configurable
  - Firmas múltiples en cascada
  - Compartición interna/externa
  - Comentarios y anotaciones
  - Notificaciones

### Fase 4: Advanced Features - 3 meses
- **Objetivos**:
  - OCR completo
  - Detección automática de datos sensibles (DLP)
  - APIs completas
  - Integraciones con ERP/CRM
  - Analytics avanzado
  - App móvil

### Fase 5: Certificación y Hardening - 1 mes
- **Objetivos**:
  - Auditoría de seguridad completa
  - Pentest
  - Documentación ISO compliance
  - Optimización de rendimiento
  - Preparación para certificación ISO 27001

---

## 8. CONSIDERACIONES ESPECIALES

### 8.1 Multitenancy
Para ofrecer el sistema como SaaS a múltiples organizaciones:
- Aislamiento total de datos entre tenants
- Configuración personalizable por tenant
- Facturación por uso/espacio
- SLA diferenciados por plan

### 8.2 On-Premise vs Cloud
- **On-Premise**: Control total, para organizaciones con infraestructura propia
- **Cloud**: Menor inversión inicial, escalabilidad elástica
- **Híbrido**: Datos sensibles on-premise, almacenamiento archive en cloud

### 8.3 Disaster Recovery
- Plan de contingencia documentado
- Sitio de recuperación alternativo
- Procedimientos de failover automático
- Simulacros de recuperación periódicos

---

## 9. MÉTRICAS DE ÉXITO

| Métrica | Objetivo |
|---------|----------|
| Tiempo de onboarding de usuario nuevo | < 2 horas |
| Tiempo de búsqueda y recuperación | < 5 segundos |
| Cumplimiento de retención documental | 100% |
| Disponibilidad del sistema | ≥ 99.5% |
| Documentos con firma digital válida | ≥ 95% de documentos críticos |
| Incidentes de seguridad | 0 críticos/año |
| Satisfacción de usuarios | ≥ 4/5 |
| Tiempo de respuesta a solicitudes ARCO | < 10 días hábiles (100% cumplimiento legal) |

---

## 10. RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Invalidez de firmas digitales | Baja | Crítico | Integración exhaustiva con certificadores homologados + testing riguroso |
| Pérdida de documentos | Baja | Crítico | Backups redundantes + auditoría de integridad continua |
| Acceso no autorizado | Media | Alto | MFA obligatorio + monitoreo continuo + segregación de funciones |
| Incumplimiento normativo | Baja | Alto | Revisión legal periódica + auditorías de compliance |
| Fallo de disponibilidad | Media | Medio | Alta disponibilidad (HA) + plan DR robusto |
| Escalabilidad insuficiente | Media | Medio | Arquitectura cloud-native escalable desde diseño |
| Adopción de usuarios baja | Alta | Medio | UX intuitivo + capacitación + soporte continuo |

---

## 11. GLOSARIO

- **ARCO**: Acceso, Rectificación, Cancelación y Oposición (derechos de protección de datos)
- **DLP**: Data Loss Prevention (Prevención de pérdida de datos)
- **ECM**: Enterprise Content Management
- **HSM**: Hardware Security Module
- **KMS**: Key Management Service
- **MFA**: Multi-Factor Authentication
- **OCSP**: Online Certificate Status Protocol
- **PAdES**: PDF Advanced Electronic Signatures
- **RBAC**: Role-Based Access Control
- **RPO**: Recovery Point Objective
- **RTO**: Recovery Time Objective
- **SGD**: Sistema de Gestión Documental
- **TSA**: Time Stamping Authority
- **WAF**: Web Application Firewall

---

## 12. PRÓXIMOS PASOS

1. **Revisión y refinamiento** de este documento con stakeholders
2. **Priorización de requerimientos** (MoSCoW: Must have, Should have, Could have, Won't have)
3. **Elaboración de especificaciones técnicas detalladas** por módulo
4. **Selección definitiva del stack tecnológico**
5. **Estimación de esfuerzo** y planificación ágil (sprints)
6. **Configuración del entorno de desarrollo**
7. **Inicio del desarrollo iterativo**

---

**Documento vivo**: Este documento debe actualizarse continuamente conforme surjan nuevos requerimientos, cambios normativos o feedback de usuarios.

**Versión**: 1.0  
**Fecha**: Enero 2026  
**Autores**: Equipo de Análisis SGD
