# Requisitos No Funcionales

Fecha de corte: 2026-03-18

## 1. Contexto arquitectónico obligatorio

- Backend: `.NET 10 LTS`, Clean Architecture por módulo, estrategia `modular monolith`.
- Frontend: `Flutter` estable, `MVVM` para presentación y Clean Architecture para dominio, aplicación y datos.
- Infraestructura por defecto: `PostgreSQL 18.3` sobre rama `18` vigente al `2026-03-18` para datos transaccionales y relacionales; `Firebase Remote Config` para configuración dinámica no sensible; `Cloud Firestore` para datos no relacionales y proyecciones; `S3-compatible storage`; `OpenSearch`; `Outbox`.
- Despliegue: híbrido, con soporte SaaS multi-tenant y single-tenant/on-premise.
- Seguridad desde el diseño: controles técnicos, organizativos y de SDLC desde la primera fase.

## 2. Regla estructural obligatoria

- Ninguna clase de la solución debe superar `300` líneas de código.
- La verificación debe formar parte de CI.
- En frontend, la configuración compartida de módulos debe resolverse con `convention plugins`.

## 3. Requisitos no funcionales

## 3.1 Seguridad

## RNF-001 MFA obligatorio para perfiles críticos

- Categoría: Seguridad.
- Descripción: la autenticación multifactor debe ser obligatoria para administradores, oficiales de cumplimiento, perfiles con exportación probatoria y accesos externos privilegiados.
- Métrica/SLO: 100% de los perfiles críticos autenticados con MFA.
- Método de validación: pruebas de acceso, revisión de políticas y tests E2E de autenticación.
- Norma origen: ISO/IEC 27001, ISO/IEC 27002, OWASP ASVS.
- Impacto arquitectónico: capa de identidad desacoplada, soporte de MFA adaptativo y eventos de autenticación auditables.

## RNF-002 Cifrado en tránsito

- Categoría: Seguridad.
- Descripción: toda comunicación entre cliente, API, storage, search y servicios externos debe viajar cifrada.
- Métrica/SLO: 100% de endpoints productivos expuestos solo por TLS fuerte; cero tráfico sensible por HTTP plano.
- Método de validación: escaneos de configuración, pruebas de infraestructura y hardening review.
- Norma origen: ISO/IEC 27002, ISO/IEC 27017.
- Impacto arquitectónico: terminación TLS controlada, mTLS o equivalentes para tráfico interno sensible.

## RNF-003 Cifrado en reposo y separación por tenant

- Categoría: Seguridad.
- Descripción: documentos, índices, backups y secretos persistidos deben quedar cifrados; la solución debe admitir segregación de claves por tenant.
- Métrica/SLO: 100% de binarios y respaldos cifrados; soporte de clave lógica por tenant en diseño.
- Método de validación: revisión de arquitectura, pruebas de despliegue y checklist de seguridad.
- Norma origen: Ley 25.326, ISO/IEC 27001, ISO/IEC 27018.
- Impacto arquitectónico: `KmsPort`, abstracción de storage y separación entre cifrado aplicativo y de plataforma.

## RNF-004 Gestión segura de secretos

- Categoría: Seguridad.
- Descripción: claves, tokens, certificados y secretos de integración no deben almacenarse en código fuente ni archivos inseguros.
- Métrica/SLO: 0 secretos hardcodeados en repositorio; rotación configurable para secretos críticos.
- Método de validación: secret scanning, code review, verificación de pipelines.
- Norma origen: ISO/IEC 27002, NIST SSDF.
- Impacto arquitectónico: vault o gestor equivalente, inyección segura de configuración, separación por entorno.

## RNF-005 Sesiones y tokens robustos

- Categoría: Seguridad.
- Descripción: el manejo de sesión debe evitar fijación, reutilización indebida y sobreexposición de tokens.
- Métrica/SLO: expiración configurable; revocación efectiva de sesiones críticas en menos de 5 minutos.
- Método de validación: pruebas de seguridad manuales y automatizadas.
- Norma origen: OWASP ASVS, OWASP Top 10.
- Impacto arquitectónico: issuer centralizado, sesiones revocables, claims mínimos y tokens de corta vida.

## RNF-006 DevSecOps obligatorio

- Categoría: Seguridad.
- Descripción: la cadena de entrega debe incorporar SAST, SCA, secret scanning y verificación de licencias.
- Métrica/SLO: 100% de pipelines con controles activos; build bloqueado ante hallazgos críticos no aceptados.
- Método de validación: revisión de CI/CD y ejecuciones de pipeline.
- Norma origen: NIST SSDF, ISO/IEC 27001.
- Impacto arquitectónico: pipelines estandarizados, policy gates y backlog de remediación trazable.

## RNF-007 Remediación de vulnerabilidades

- Categoría: Seguridad.
- Descripción: la solución debe definir plazos de remediación según criticidad para código, dependencias e infraestructura.
- Métrica/SLO: críticas <= 72 horas; altas <= 7 días; medias <= 30 días salvo aceptación formal de riesgo.
- Método de validación: reportes de seguridad, auditoría de tickets y escaneos recurrentes.
- Norma origen: ISO/IEC 27001, ISO/IEC 27005, OWASP.
- Impacto arquitectónico: inventario de componentes, ownership por módulo y proceso de gestión de riesgos.

## RNF-008 Auditoría tamper-evident

- Categoría: Seguridad.
- Descripción: la auditoría debe ser resistente a manipulación y capaz de evidenciar alteraciones.
- Métrica/SLO: 100% de eventos críticos registrados; integridad verificable de la bitácora.
- Método de validación: pruebas de integridad, revisión de diseño y simulaciones de manipulación.
- Norma origen: Ley 25.506, ISO/IEC 27037, IRAM 36100.
- Impacto arquitectónico: append-only log, hash chaining o técnica equivalente, exportación verificable.

## 3.2 Privacidad y protección de datos

## RNF-009 Minimización y limitación de finalidad

- Categoría: Privacidad.
- Descripción: el sistema debe recolectar y exponer solamente los datos necesarios para cada proceso.
- Métrica/SLO: todos los formularios productivos asociados a finalidad y base de tratamiento; 0 campos sin justificación documental.
- Método de validación: revisión funcional y de privacidad por módulo.
- Norma origen: Ley 25.326, ISO/IEC 27701.
- Impacto arquitectónico: formularios versionados, catálogos de finalidad y metadatos de tratamiento.

## RNF-010 Atención de derechos del titular

- Categoría: Privacidad.
- Descripción: el sistema debe permitir cumplir plazos legales de acceso, rectificación, actualización o supresión, con bloqueo por excepciones legales cuando aplique.
- Métrica/SLO: caso registrado y trazable para 100% de solicitudes; plazo parametrizable alineado a ley vigente.
- Método de validación: pruebas de proceso, casos de auditoría y simulaciones operativas.
- Norma origen: Constitución Nacional art. 43, Ley 25.326.
- Impacto arquitectónico: búsquedas por sujeto de datos, expediente interno de privacidad y trazabilidad de resolución.

## RNF-011 Gestión de encargados y subencargados

- Categoría: Privacidad.
- Descripción: debe existir trazabilidad de todo tercero que procese datos personales por cuenta del tenant o de la plataforma.
- Métrica/SLO: 100% de integraciones externas con registro de responsable, finalidad y categoría de datos.
- Método de validación: revisión de inventario de integraciones y auditoría de configuración.
- Norma origen: Ley 25.326, Decreto 1558/2001, ISO/IEC 27701.
- Impacto arquitectónico: inventario de proveedores, metadata contractual y controles de integración.

## RNF-012 Transferencias y residencia de datos

- Categoría: Privacidad.
- Descripción: la arquitectura debe poder registrar residencia de datos y transferencias internacionales cuando existan.
- Métrica/SLO: 100% de flujos de datos externos etiquetados por región y proveedor.
- Método de validación: revisión de arquitectura, inventario de flujos y pruebas de despliegue.
- Norma origen: Ley 25.326, ISO/IEC 27018, ISO/IEC 27701.
- Impacto arquitectónico: configuración por tenant, storage regionalizable y documentación de flujos.

## 3.3 Trazabilidad probatoria y records management

## RNF-013 Preservación de integridad y procedencia

- Categoría: Trazabilidad probatoria.
- Descripción: cada documento debe poder asociarse a hash, origen, canal de ingreso, timestamps y cadena básica de custodia.
- Métrica/SLO: 100% de documentos con hash y metadatos mínimos de procedencia.
- Método de validación: pruebas funcionales, auditoría de muestras y exportaciones verificables.
- Norma origen: Ley 25.506, ISO 15489, ISO/IEC 27037, IRAM 36100.
- Impacto arquitectónico: `EvidencePackage`, sello temporal o constancia horaria, metadata de ingreso inmutable.

## RNF-014 Verificación reproducible de firma

- Categoría: Trazabilidad probatoria.
- Descripción: la verificación de firmas debe ser repetible y dejar constancia del resultado y del contexto de validación.
- Métrica/SLO: 100% de verificaciones guardan fecha, cadena certificante, estado y evidencia asociada.
- Método de validación: pruebas de firma y contrapruebas con certificados válidos, vencidos y revocados.
- Norma origen: Ley 25.506, Decreto 182/2019.
- Impacto arquitectónico: servicios de validación desacoplados, almacenamiento de evidencias de verificación.

## RNF-015 Retención, hold y disposición auditables

- Categoría: Trazabilidad probatoria.
- Descripción: las decisiones de retención, hold y disposición deben ser rastreables y justificables.
- Métrica/SLO: 100% de disposiciones con evidencia de aprobación; 0 eliminaciones definitivas sin evento asociado.
- Método de validación: pruebas de records, revisión de auditoría y muestreo de casos.
- Norma origen: CCyC arts. 328-330, ISO 15489, ISO 16175.
- Impacto arquitectónico: motor de políticas, doble control opcional y registros de decisión.

## RNF-016 Preservación a largo plazo

- Categoría: Trazabilidad probatoria.
- Descripción: la solución debe soportar formatos y estrategias aptas para conservación prolongada.
- Métrica/SLO: exportación soportada en formatos abiertos y capacidad de generar PDF/A cuando aplique.
- Método de validación: pruebas de exportación, preservación y lectura en entornos independientes.
- Norma origen: ISO 19005, ISO 15489.
- Impacto arquitectónico: pipeline de exportación y preservación desacoplado del viewer principal.

## 3.4 Disponibilidad, continuidad y resiliencia

## RNF-017 Disponibilidad del servicio

- Categoría: Disponibilidad.
- Descripción: la plataforma SaaS debe estar diseñada para alta disponibilidad; en on-prem debe documentarse el nivel esperable por topología.
- Métrica/SLO: objetivo SaaS de 99.9% mensual excluyendo mantenimientos programados.
- Método de validación: observabilidad, reportes de uptime y pruebas de failover.
- Norma origen: ISO 22301, ISO/IEC 27001.
- Impacto arquitectónico: separación de componentes stateless/stateful, health checks y despliegue redundante.

## RNF-018 Backups, RPO y RTO

- Categoría: Continuidad.
- Descripción: deben existir políticas de respaldo y restauración para metadata, documentos y auditoría.
- Métrica/SLO: objetivo de referencia SaaS RPO <= 15 minutos y RTO <= 4 horas para servicios críticos.
- Método de validación: pruebas de restauración y simulacros documentados.
- Norma origen: ISO 22301.
- Impacto arquitectónico: backups consistentes, snapshots coordinados y runbooks de recuperación.

## RNF-019 Pruebas de DRP/BCP

- Categoría: Continuidad.
- Descripción: la recuperación ante desastres y continuidad deben probarse periódicamente.
- Métrica/SLO: al menos 2 ejercicios formales por año en SaaS y 1 prueba documentada por despliegue on-prem relevante.
- Método de validación: actas de prueba y evidencias de restauración.
- Norma origen: ISO 22301.
- Impacto arquitectónico: infraestructura reproducible y procedimientos automatizables.

## RNF-020 Procesamiento resiliente de tareas

- Categoría: Resiliencia.
- Descripción: OCR, indexación, antivirus, notificaciones y flujos asíncronos deben tolerar reintentos y fallos parciales.
- Métrica/SLO: 0 pérdida silenciosa de tareas; 100% de jobs con estado rastreable.
- Método de validación: chaos testing, pruebas de cola y simulaciones de caída.
- Norma origen: ISO/IEC 27001, NIST SSDF.
- Impacto arquitectónico: outbox, workers idempotentes, colas con DLQ y trazabilidad.

## 3.5 Rendimiento y escalabilidad

## RNF-021 Rendimiento de carga y consulta

- Categoría: Rendimiento.
- Descripción: el sistema debe responder de forma consistente para operaciones frecuentes de carga, consulta y descarga.
- Métrica/SLO: búsqueda simple P95 <= 2 segundos; búsqueda facetada P95 <= 3 segundos en condiciones nominales.
- Método de validación: pruebas de performance con datasets realistas.
- Norma origen: ISO 30301, buenas prácticas de ECM.
- Impacto arquitectónico: OpenSearch, cachés prudentes y consultas paginadas.

## RNF-022 Procesamiento de OCR e indexación

- Categoría: Rendimiento.
- Descripción: los procesos asíncronos de OCR e indexación deben completarse dentro de ventanas operativas razonables.
- Métrica/SLO: 90% de documentos estándar indexados en menos de 5 minutos desde su ingreso, bajo carga nominal.
- Método de validación: pruebas de carga de workers y monitoreo en staging.
- Norma origen: ISO 15489.
- Impacto arquitectónico: cola de procesamiento, escalado horizontal de workers y métricas por pipeline.

## RNF-023 Escalabilidad horizontal

- Categoría: Escalabilidad.
- Descripción: la plataforma debe poder escalar sin rediseñar el dominio ni fragmentar prematuramente en microservicios.
- Métrica/SLO: incremento lineal aproximado de throughput en componentes stateless al agregar instancias.
- Método de validación: benchmarks controlados y pruebas de capacidad.
- Norma origen: ISO/IEC 27017, buenas prácticas cloud.
- Impacto arquitectónico: modular monolith, procesos stateless, storage externo y búsqueda separada.

## 3.6 Interoperabilidad y portabilidad

## RNF-024 Interoperabilidad basada en estándares

- Categoría: Interoperabilidad.
- Descripción: la solución debe privilegiar REST/JSON, formatos abiertos, OIDC/SAML, S3-compatible y exportaciones interoperables.
- Métrica/SLO: 100% de APIs documentadas y versionadas; formatos de exportación legibles sin dependencia del frontend.
- Método de validación: contract tests, revisión de API y pruebas de integración.
- Norma origen: Ley 27.446, ISO 19005.
- Impacto arquitectónico: contratos explícitos, versionado de API y formatos de salida estables.

## RNF-025 Portabilidad de proveedores

- Categoría: Portabilidad.
- Descripción: storage, firma, OCR y notificaciones deben quedar abstraídos detrás de puertos para evitar lock-in.
- Métrica/SLO: al menos un adaptador alternativo por servicio crítico diseñado en arquitectura.
- Método de validación: revisión de código y pruebas de intercambio de adaptadores en entorno controlado.
- Norma origen: NIST SSDF, ISO/IEC 27017.
- Impacto arquitectónico: `StoragePort`, `OCRPort`, `SignatureProviderPort`, `NotificationPort`.

## RNF-026 Soporte híbrido y on-premise

- Categoría: Portabilidad.
- Descripción: el producto debe poder desplegarse en nube y en entornos on-premise con configuración externalizada.
- Métrica/SLO: el mismo core funcional debe desplegarse en ambos modelos sin cambios de negocio.
- Método de validación: pruebas de despliegue en ambos escenarios.
- Norma origen: ISO/IEC 27017, ISO 22301.
- Impacto arquitectónico: contenedorización, variables externas, módulos desacoplados de la infraestructura.

## 3.7 Observabilidad y auditabilidad operativa

## RNF-027 Observabilidad transversal

- Categoría: Observabilidad.
- Descripción: logs, métricas y trazas deben estar correlacionados por tenant, usuario, request y evento de negocio.
- Métrica/SLO: 100% de requests críticas con correlation id; dashboards mínimos por API, workers y storage.
- Método de validación: inspección de telemetría y pruebas de incident response.
- Norma origen: ISO/IEC 27001, ISO 22301.
- Impacto arquitectónico: logging estructurado, tracing distribuido y telemetría por módulo.

## RNF-028 Alertas operativas y de compliance

- Categoría: Observabilidad.
- Descripción: la solución debe alertar por fallos de integración, jobs atascados, accesos anómalos, vencimientos regulatorios y errores de backup.
- Métrica/SLO: alertas críticas emitidas en menos de 5 minutos desde la detección.
- Método de validación: simulaciones de incidente y pruebas de monitoreo.
- Norma origen: ISO/IEC 27002, ISO 22301.
- Impacto arquitectónico: motor de alertas y reglas por severidad.

## 3.8 Mantenibilidad y calidad interna

## RNF-029 Enforzamiento de Clean Architecture

- Categoría: Mantenibilidad.
- Descripción: cada módulo debe respetar separación entre presentación, aplicación, dominio e infraestructura, evitando dependencias inversas indebidas.
- Métrica/SLO: 0 dependencias prohibidas en chequeos estáticos definidos.
- Método de validación: arquitectura tests y revisión de proyecto.
- Norma origen: NIST SSDF, buenas prácticas de diseño.
- Impacto arquitectónico: proyectos/capas por módulo y reglas de dependencia automatizadas.

## RNF-030 Límite de 300 líneas por clase

- Categoría: Mantenibilidad.
- Descripción: ninguna clase debe superar 300 líneas de código.
- Métrica/SLO: 100% del repositorio dentro del límite.
- Método de validación: script o regla de CI fallando si se excede el umbral.
- Norma origen: restricción arquitectónica del proyecto.
- Impacto arquitectónico: favorece SRP, casos de uso pequeños y adaptadores especializados.

## RNF-031 Configuración modular mediante convention plugins

- Categoría: Mantenibilidad.
- Descripción: el frontend modular debe centralizar su configuración compartida a través de `convention plugins` y reglas comunes.
- Métrica/SLO: 100% de módulos Flutter/Android creados bajo convención común; 0 duplicación manual crítica de build config.
- Método de validación: revisión de build logic y bootstrap de nuevos módulos.
- Norma origen: decisión arquitectónica del proyecto.
- Impacto arquitectónico: carpeta `build-logic`, plugins de convención y lints comunes centralizados.

## RNF-032 Cobertura automática y calidad verificable

- Categoría: Mantenibilidad.
- Descripción: el proyecto debe contar con pruebas automatizadas suficientes para resguardar núcleo de negocio y contratos externos.
- Métrica/SLO: cobertura objetivo >= 80% en dominio y aplicación; contract tests en APIs críticas; smoke tests E2E por flujo principal.
- Método de validación: reportes de cobertura y pipeline de CI.
- Norma origen: NIST SSDF, OWASP ASVS.
- Impacto arquitectónico: diseño testeable, puertos desacoplados y fixtures por módulo.

## 3.9 Accesibilidad y experiencia

## RNF-033 Accesibilidad

- Categoría: Accesibilidad.
- Descripción: el frontend debe seguir el esquema vigente `WCAG 2.2` nivel `AA` en los flujos críticos y en el design system base.
- Métrica/SLO: 100% de pantallas críticas validadas contra checklist AA.
- Método de validación: auditorías manuales, tooling automatizado y pruebas con teclado/lector.
- Norma origen: buenas prácticas de accesibilidad.
- Impacto arquitectónico: design system accesible, contraste, foco visible y semántica adecuada en Flutter.

## 3.10 Compliance-by-design

## RNF-034 Trazabilidad normativa viva

- Categoría: Compliance-by-design.
- Descripción: debe existir una matriz mantenida de `norma -> requisito -> implementación -> prueba`.
- Métrica/SLO: 100% de RF y RNF críticos con origen normativo o justificación explícita.
- Método de validación: revisión documental en cada release mayor.
- Norma origen: ISO 30301, ISO/IEC 27001.
- Impacto arquitectónico: gobierno de cambios, documentación viva y backlog trazable.

## RNF-035 Threat modeling por fase y release

- Categoría: Compliance-by-design.
- Descripción: cada fase relevante y cada release importante deben incluir análisis de amenazas y controles asociados.
- Métrica/SLO: 100% de releases mayores con threat model actualizado y decisiones registradas.
- Método de validación: artefactos de arquitectura y security review.
- Norma origen: ISO/IEC 27005, NIST SSDF, OWASP.
- Impacto arquitectónico: decisiones de seguridad explícitas desde diseño, no agregadas al final.

## RNF-036 Evidencia de cumplimiento para verticales regulados

- Categoría: Compliance-by-design.
- Descripción: la solución debe poder producir evidencia suficiente para auditorías internas, clientes regulados y verticales AML o jurídicos.
- Métrica/SLO: exportaciones de auditoría y evidencia disponibles para 100% de procesos críticos.
- Método de validación: simulacros de auditoría y casos E2E por vertical.
- Norma origen: Ley 25.246, UIF 43/2024, UIF 48/2024, ISO 30301.
- Impacto arquitectónico: reportes, evidence packages y bitácora consolidada.

## 3.11 Calidad e integridad de datos

## RNF-037 Validación multicapa de dominio

- Categoría: Calidad de datos.
- Descripción: toda operación de alta, modificación o transición de estado debe ser validada en al menos dos capas: borde de entrada y dominio; la validación del frontend nunca reemplaza la del backend.
- Métrica/SLO: 100% de comandos y endpoints críticos con validación declarada y pruebas automáticas asociadas.
- Método de validación: unit tests de casos de uso, contract tests y pruebas negativas de API.
- Norma origen: ISO 15489, ISO 16175, OWASP ASVS.
- Impacto arquitectónico: validators por caso de uso, domain invariants y manejo consistente de errores.

## RNF-038 Integridad referencial fuerte

- Categoría: Calidad de datos.
- Descripción: las relaciones críticas entre entidades deben protegerse con integridad referencial en PostgreSQL y con verificaciones explícitas en la capa de aplicación.
- Métrica/SLO: 0 registros huérfanos en entidades críticas; 100% de relaciones core protegidas por claves foráneas o política equivalente documentada.
- Método de validación: pruebas de base de datos, migration tests y auditorías periódicas de consistencia.
- Norma origen: CCyC arts. 328-330, ISO 23081.
- Impacto arquitectónico: foreign keys, índices compuestos, restricciones y servicios de validación referencial.

## RNF-039 Tipado estricto, formatos y evolución de esquemas

- Categoría: Calidad de datos.
- Descripción: el sistema debe usar contratos tipados explícitos para identificadores, fechas, timestamps, importes, estados, enums y estructuras JSON, con reglas de evolución compatibile hacia atrás cuando aplique.
- Métrica/SLO: 100% de contratos públicos versionados; 0 campos críticos persistidos con tipado ambiguo sin justificación.
- Método de validación: contract tests, revisión de esquemas, linting estático y pruebas de serialización.
- Norma origen: NIST SSDF, OWASP ASVS, ISO 23081.
- Impacto arquitectónico: DTOs tipados, value objects, versionado de esquemas y validación de payloads.

## 3.12 Plataforma y persistencia

## RNF-040 PostgreSQL como fuente de verdad relacional

- Categoría: Plataforma.
- Descripción: `PostgreSQL 18.x` debe ser la fuente de verdad para procesos transaccionales, integridad relacional, auditoría estructurada, retención y estados regulados del negocio.
- Métrica/SLO: 100% de entidades core reguladas persistidas en PostgreSQL; adopción de la última minor soportada dentro de los 30 días de validación interna.
- Método de validación: revisión arquitectónica, scripts de despliegue y auditoría de modelos persistidos.
- Norma origen: decisión arquitectónica del proyecto, PostgreSQL current documentation.
- Impacto arquitectónico: modelo relacional normalizado, migraciones controladas, constraints y estrategia de actualización menor recurrente.

## RNF-041 Gobernanza de Firebase Remote Config

- Categoría: Plataforma.
- Descripción: `Firebase Remote Config` solo debe usarse para configuración dinámica no sensible, feature flags y parámetros operativos reversibles.
- Métrica/SLO: 0 secretos o datos personales almacenados en Remote Config; 100% de cambios productivos con versionado y rollback disponible.
- Método de validación: revisión de parámetros publicados, pruebas de despliegue y auditoría de configuración.
- Norma origen: decisión arquitectónica del proyecto, Firebase Remote Config docs.
- Impacto arquitectónico: `ConfigPort`, plantillas versionadas, segmentación por entorno y pipeline de promoción de configuración.

## RNF-042 Gobernanza de Cloud Firestore

- Categoría: Plataforma.
- Descripción: `Cloud Firestore` debe utilizarse solo para datos no relacionales, proyecciones de lectura, preferencias, configuraciones extendidas y estados que no compitan con la verdad transaccional de PostgreSQL.
- Métrica/SLO: 100% de colecciones con ownership documentado, reglas de seguridad definidas y pruebas de acceso automáticas.
- Método de validación: tests de Security Rules, revisión de colecciones y pruebas de sincronización con el core relacional.
- Norma origen: decisión arquitectónica del proyecto, Firebase Firestore docs.
- Impacto arquitectónico: `NoSqlPort`, estrategia CQRS liviana para proyecciones y reglas por colección.

## 4. Criterios transversales de aceptación arquitectónica

- Todo módulo debe poder evolucionar sin romper contratos públicos innecesariamente.
- Los servicios externos deben quedar detrás de puertos.
- La seguridad no puede depender de lógica del frontend.
- La configuración por tenant, sector y jurisdicción debe ser declarativa y auditable.
- Los verticales sectoriales no deben duplicar el core documental; deben extenderlo.
- PostgreSQL debe conservar el ownership de las entidades críticas y Firebase no debe introducir doble fuente de verdad no controlada.
