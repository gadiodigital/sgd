# Marco Normativo y Técnico Relacionado

Fecha de corte: 2026-03-18

## 1. Propósito

Este documento resume el marco legal, normativo y técnico que debe usarse como contexto para diseñar un sistema de gestión documental empresarial y sectorial para la República Argentina, con foco en empresas, inmobiliarias, estudios jurídicos y organizaciones similares.

La idea central es separar tres capas:

1. Obligaciones legales o regulatorias efectivamente exigibles en Argentina.
2. Normas técnicas ISO/IRAM recomendables para asegurar calidad probatoria, gobernanza documental, seguridad y continuidad.
3. Marcos complementarios de ingeniería segura que no son ley, pero sí baseline de construcción moderna.

## 2. Cómo interpretar este documento

- `Obligatorio / relevante`: normas legales o regulatorias que pueden imponer obligaciones directas, condicionar la admisibilidad probatoria o fijar deberes de conservación, seguridad y trazabilidad.
- `Recomendado`: estándares técnicos que no son automáticamente obligatorios, pero elevan mucho la defensibilidad jurídica, la auditabilidad y la calidad operativa del sistema.
- `Aclaración importante`: una norma ISO o IRAM no reemplaza a la ley argentina. Se usa como marco de diseño, auditoría o certificación.
- `Limitación deliberada`: cuando una norma técnica es de acceso pago, este documento resume únicamente títulos, objetivos y efectos de diseño a partir de fuentes oficiales, abstracts o documentación pública del comité correspondiente.

## 3. Marco legal argentino obligatorio o altamente relevante

## 3.1 Protección de datos personales

### Constitución Nacional, artículo 43

- Base constitucional del habeas data.
- Impacto: el sistema debe permitir identificar, ubicar, rectificar, actualizar, bloquear, exportar o suprimir datos personales cuando corresponda.

### Ley 25.326 de Protección de los Datos Personales

Puntos de mayor impacto para el sistema:

- principios de finalidad, calidad, pertinencia y minimización de datos;
- consentimiento o base legitimante según el tratamiento;
- deber de seguridad sobre bases de datos;
- derechos del titular: acceso, rectificación, actualización y supresión;
- reglas para prestación de servicios de tratamiento por cuenta de terceros;
- control sobre cesiones y transferencias.

Consecuencias directas en el diseño:

- el sistema no puede ser solo un repositorio de archivos; debe ser también un sistema de tratamiento de datos personales con:
  - clasificación de datos personales y sensibles;
  - políticas de acceso por necesidad y función;
  - trazabilidad de quién accede, modifica, exporta o elimina;
  - soporte para atender derechos del titular;
  - trazabilidad contractual de encargados y subencargados;
  - retención y supresión gobernadas.

Implicancias concretas para requisitos:

- derivan `RF-032`, `RF-033`, `RNF-009`, `RNF-010`, `RNF-011`.

### Decreto 1558/2001

- Reglamenta aspectos operativos de la Ley 25.326.
- Impacto: obliga a modelar adecuadamente responsables, encargados, finalidades y medidas organizativas asociadas al tratamiento.

### Convenio 108+ y lineamientos de AAIP

- No reemplazan la ley local, pero consolidan una dirección regulatoria hacia accountability, transparencia, seguridad y gobernanza continua.
- Impacto: conviene diseñar el sistema con evidencia de cumplimiento y no solo con controles técnicos aislados.

## 3.2 Documento digital, firma y conservación

### Ley 25.506 de Firma Digital

Es la pieza central para un sistema documental argentino con pretensión probatoria fuerte.

Aspectos más relevantes:

- reconoce la eficacia jurídica de la firma electrónica y la firma digital;
- equipara la firma digital a la manuscrita cuando la ley exige firma;
- define documento digital y lo equipara al requisito de escritura;
- presume autoría e integridad cuando la firma digital verifica correctamente;
- admite conservación digital si el documento es accesible y permite determinar origen, destino, fecha y hora;
- regula certificados digitales, certificadores licenciados, auditoría y seguridad.

Consecuencias de diseño:

- diferenciar claramente `firma electrónica` y `firma digital`;
- preservar hashes, verificaciones, certificados, estado de revocación y evidencia de validación;
- registrar hora, origen, destino y evento de generación/envío/recepción;
- permitir exportar evidencia verificable y no solo el PDF final;
- contemplar certificados extranjeros reconocidos bajo la ley.

Implicancias concretas:

- derivan `RF-030`, `RF-031`, `RF-034`, `RF-035`, `RNF-013`, `RNF-014`.

### Decreto 182/2019 y actualizaciones posteriores

- Reglamenta la infraestructura de firma digital y el funcionamiento operativo del ecosistema.
- Refuerza la necesidad de diseño compatible con:
  - políticas de certificación;
  - servicios de auditoría;
  - controles de seguridad y contingencia;
  - escenarios de firma remota o custodiada según la normativa vigente.

Consecuencia práctica:

- la arquitectura debe prever un `SignatureProviderPort` y un `EvidencePackage` que permitan cambiar proveedor o modalidad sin rediseñar el dominio documental.

### Ley 27.446 de Simplificación y Desburocratización

- Relevante para interoperar con organismos públicos, admitir circuitos documentales digitales y favorecer la despapelización.
- No convierte por sí sola a cualquier copia digital privada en prueba plena, pero sí empuja el ecosistema argentino hacia flujos digitales trazables.

## 3.3 Conservación, registraciones y valor probatorio

### Código Civil y Comercial de la Nación, artículos 328 a 330

Puntos críticos:

- conservación de libros, registros e instrumentos respaldatorios por diez años, salvo plazos especiales mayores;
- posibilidad de usar medios electrónicos o magnéticos si garantizan individualización, verificación, inviolabilidad, verosimilitud y completitud;
- reconocimiento de eficacia probatoria de la contabilidad regular.

Consecuencias de diseño:

- el sistema debe soportar conservación a largo plazo;
- debe poder demostrar integridad y completitud;
- debe permitir exportar historia documental y metadatos de auditoría;
- debe bloquear destrucciones indebidas durante plazos de retención o litigio.

Implicancias:

- derivan `RF-026`, `RF-027`, `RF-028`, `RF-029`, `RF-031`, `RNF-015`.

## 3.4 Prevención de lavado de activos y financiación del terrorismo

### Ley 25.246 y modificaciones, incluyendo Ley 27.739

- Crea y fortalece el régimen argentino de prevención de LA/FT y el rol de la UIF.
- No todas las organizaciones usuarias del sistema serán `sujetos obligados`, pero el producto debe contemplar esa posibilidad en verticales sectoriales.

Impacto general:

- parametrización por sector;
- legajo de cliente;
- beneficiario final;
- enfoque basado en riesgo;
- trazabilidad de análisis y monitoreo;
- conservación de evidencia de due diligence y reportabilidad.

### Resolución UIF 43/2024 para agentes y corredores inmobiliarios

- Actualiza obligaciones del sector inmobiliario bajo enfoque basado en riesgo.
- Implica que el vertical inmobiliario debe prever:
  - identificación del cliente;
  - perfil transaccional;
  - monitoreo de operaciones relevantes;
  - capacitación y evidencia de cumplimiento;
  - trazabilidad y soporte a reportes operativos.

Implicancias:

- derivan `RF-038`, `RF-039`, `RNF-036`.

### Resolución UIF 48/2024 para abogados y abogadas

- Relevante para estudios jurídicos y servicios legales alcanzados.
- Debe leerse con cuidado porque no todo servicio jurídico genera condición de cliente o de sujeto obligado en los mismos términos.
- Es especialmente importante la exclusión vinculada a servicios de defensa o asesoramiento estrictamente defensivo, que no deben ser tratados igual que una operación alcanzada por cumplimiento LA/FT.

Consecuencias de diseño:

- el sistema jurídico debe poder distinguir:
  - asunto sujeto a secreto profesional reforzado;
  - defensa o litigio no alcanzado como cliente en términos UIF;
  - operación o servicio alcanzado por compliance.

Implicancias:

- derivan `RF-040`, `RF-041`, `RF-042`, `RNF-010`, `RNF-036`.

## 3.5 Delitos informáticos, seguridad y evidencia

### Ley 26.388 de Delitos Informáticos

- Actualiza el Código Penal para tipificar conductas vinculadas con acceso ilegítimo, violación de secretos, daño informático y otros hechos sobre sistemas y datos.

Consecuencia práctica:

- el sistema debe reducir superficie de abuso interno y externo;
- toda manipulación sensible debe quedar registrada;
- la preservación de evidencia debe ser confiable para investigaciones internas y externas.

### Ley 27.411 y Convenio de Budapest

- Refuerza el marco argentino de cooperación y tratamiento de cibercriminalidad.
- No agrega una funcionalidad de negocio aislada, pero sí vuelve recomendable que el sistema preserve evidencia digital con criterios forenses razonables.

Implicancias:

- derivan `RF-030`, `RF-031`, `RNF-013`, `RNF-027`.

## 3.6 Deberes sectoriales complementarios

### Estudios jurídicos

- La confidencialidad y el secreto profesional imponen:
  - compartimentación estricta por asunto;
  - controles tipo `need to know`;
  - trazabilidad reforzada;
  - mecanismos tipo `ethical wall` o `Chinese wall`.

### Inmobiliarias

- Los legajos deben reunir documentación de personas, inmuebles, operaciones y beneficiarios finales cuando corresponda.
- Deben coexistir conservación contractual y exigencias de compliance antilavado.

### Empresas en general

- Deben convivir documentos corporativos, contables, contractuales, RR.HH., proveedores y expedientes internos con distintos plazos de retención y distintos niveles de confidencialidad.

## 4. Normas ISO / IRAM recomendadas

## 4.1 Gestión documental, records management y preservación

### ISO 15489 - Records management

- Norma base para gestionar documentos como evidencia de actividad.
- Conceptos claves:
  - autenticidad;
  - fiabilidad;
  - integridad;
  - usabilidad;
  - clasificación;
  - disposición;
  - captura contextual.

Impacto:

- define la filosofía del repositorio y de los metadatos;
- impulsa `RF-015`, `RF-016`, `RF-026`, `RF-028`, `RF-030`.

### ISO 30301 - Management systems for records

- Lleva la gestión documental al plano de sistema de gestión.
- Relevante para organizaciones que quieran demostrar gobernanza y mejora continua, no solo operación.

Impacto:

- exige políticas, roles, métricas, auditorías, revisión y mejora;
- impulsa `RF-008`, `RF-037`, `RNF-034`.

### ISO 23081 - Metadata for records

- Marco clave para definir metadatos de contexto, estructura, trazabilidad y gestión.

Impacto:

- obliga a modelar metadatos como dominio de negocio y no como campos sueltos;
- impulsa `RF-015`, `RF-016`, `RF-031`.

### ISO 16175 - Principles and functional requirements for software for managing records

- Muy útil para traducir records management a requisitos funcionales concretos de software.

Impacto:

- justifica funcionalidades de captura, clasificación, retención, auditoría, exportación y preservación;
- impulsa buena parte del núcleo ECM y records.

### ISO 19005 - PDF/A

- Estándar de preservación a largo plazo para documentos electrónicos basados en PDF.

Impacto:

- recomendable para documentos de archivo, exportaciones probatorias y preservación de legibilidad a largo plazo;
- impulsa `RF-031`, `RNF-016`, `RNF-024`.

## 4.2 Seguridad de la información y privacidad

### ISO/IEC 27001

- Norma central para sistema de gestión de seguridad de la información.

Impacto:

- define enfoque basado en riesgos, políticas, controles, revisión y mejora continua;
- impulsa `RNF-001` a `RNF-008`, `RNF-034`, `RNF-035`.

### ISO/IEC 27002

- Catálogo de controles de seguridad.

Impacto:

- baja a nivel práctico controles de acceso, logging, cifrado, continuidad, proveedores, desarrollo seguro y gestión de incidentes.

### ISO/IEC 27005

- Gestión del riesgo de seguridad de la información.

Impacto:

- orienta la priorización de amenazas por activo, tenant, vertical y flujo crítico.

### ISO/IEC 27017

- Controles específicos para servicios cloud.

Impacto:

- muy relevante por el despliegue híbrido;
- afecta separación de responsabilidades proveedor-cliente y seguridad de la operación SaaS.

### ISO/IEC 27018

- Protección de PII en nubes públicas que actúan como procesadores.

Impacto:

- especialmente útil para el modelo SaaS multi-tenant;
- impulsa requisitos sobre privacidad contractual, transferencias y subprocesadores.

### ISO/IEC 27701

- Amplía ISO 27001/27002 para gestión de privacidad.

Impacto:

- ayuda a traducir la Ley 25.326 a un sistema operable con roles, inventarios, bases legitimantes y atención de derechos.

## 4.3 Continuidad, evidencia y análisis forense

### ISO 22301

- Sistema de gestión de continuidad del negocio.

Impacto:

- fija expectativas sobre RTO, RPO, pruebas de contingencia, restauración y crisis.

### ISO/IEC 27037

- Guía para identificación, recolección, adquisición y preservación de evidencia digital.

Impacto:

- crítica para auditoría, incidentes y exportación probatoria.

### ISO/IEC 27042

- Guía para análisis e interpretación de evidencia digital.

Impacto:

- útil para investigaciones, pericias internas y validación de cadena de custodia.

### IRAM 36100

- Referencia nacional relevante sobre cadena de custodia en informática forense.

Impacto:

- agrega contexto argentino a la preservación de evidencia;
- conviene usarla para diseñar `EvidencePackage`, auditoría y exportaciones.

## 4.4 Qué aporta IRAM en Argentina

### Centro de documentación y disponibilidad local

- IRAM es la puerta natural para adquisición local de normas y adopciones IRAM-ISO/IEC.

### Certificación

- IRAM publica servicios de certificación para, entre otras, ISO/IEC 27001 e ISO 22301.

### Plan de estudio IRAM

- El plan de estudio público de IRAM muestra trabajo y seguimiento sobre normas relevantes para este proyecto, incluyendo:
  - 27018;
  - 27005;
  - 27037;
  - 27042;
  - IRAM 36100.

Conclusión práctica:

- aunque no todas estas normas sean obligatorias, sí tienen sentido como baseline si el producto quiere venderse a clientes regulados o con exigencia de auditoría.

## 5. Marcos complementarios de ingeniería segura

## 5.1 NIST SP 800-218 - Secure Software Development Framework

- No es ley argentina, pero sí una referencia madura para construir seguridad desde el inicio.
- Impacto:
  - threat modeling por iteración;
  - control de dependencias;
  - gestión segura de build y release;
  - trazabilidad de riesgos y remediaciones.

## 5.2 OWASP ASVS

- Excelente baseline de verificación de seguridad de aplicaciones.
- Impacto:
  - autenticación;
  - autorización;
  - manejo de sesión;
  - logging;
  - validación de entradas;
  - criptografía;
  - APIs.

## 5.3 OWASP API Security Top 10 y OWASP Top 10

- Relevantes porque el backend será .NET con APIs y porque el producto operará sobre documentos sensibles.
- Riesgos a cubrir desde diseño:
  - broken object level authorization;
  - broken function level authorization;
  - exposición masiva de datos;
  - SSRF;
  - fallas de autenticación;
  - logging insuficiente;
  - configuración insegura;
  - componentes vulnerables.

## 5.4 Accesibilidad vigente

### W3C WCAG 2.2

- El esquema de accesibilidad vigente de referencia para software generalista continúa siendo `WCAG 2.2` del W3C.
- Para este proyecto corresponde adoptar nivel `AA` como baseline mínimo.

Impacto:

- obliga a considerar accesibilidad en el design system y no solo en pantallas aisladas;
- impacta navegación por teclado, foco visible, contraste, semántica, labels, mensajes de error, orden de lectura y componentes reutilizables;
- impulsa `RNF-033`.

## 5.5 Baselines tecnológicos del proyecto

### PostgreSQL 18

- A la fecha de corte `2026-03-18`, la rama mayor vigente es `PostgreSQL 18` y la versión menor actual disponible es `18.3`.
- Para este sistema debe tratarse como fuente de verdad para:
  - metadatos documentales;
  - relaciones transaccionales;
  - retención;
  - legal hold;
  - auditoría estructurada;
  - estados regulatorios.

Impacto:

- exige integridad referencial fuerte, migraciones controladas y tipado consistente;
- impulsa `RF-047`, `RF-048`, `RNF-038`, `RNF-039`, `RNF-040`.

### Firebase Remote Config

- Adecuado para configuración dinámica, feature flags y parámetros no sensibles.
- No debe utilizarse para secretos, credenciales ni datos personales sensibles.

Impacto:

- permite activar módulos, umbrales y comportamiento por tenant sin redeploy;
- impulsa `RF-049`, `RNF-041`.

### Cloud Firestore

- Adecuado para datos no relacionales, configuraciones extendidas, preferencias y proyecciones de lectura.
- No debe transformarse en fuente de verdad paralela para records regulados o integridad documental crítica.

Impacto:

- habilita proyecciones, experiencias de lectura y configuraciones flexibles;
- exige reglas de seguridad, ownership de datos y sincronización controlada;
- impulsa `RF-050`, `RNF-042`.

## 6. Implicancias de diseño por subsistema

| Subsistema | Implicancias principales |
| --- | --- |
| Identidad y acceso | MFA, RBAC/ABAC, SSO, segregación por tenant, ethical walls, delegación auditada |
| Repositorio documental | versionado, hash, clasificación, metadatos, cuarentena, preservación de originales |
| Records management | calendarios de retención, legal hold, declaración de record, disposición certificada |
| Evidencia y auditoría | auditoría inmutable, exportación probatoria, hashes, firmas, sellado temporal |
| Privacidad | inventario de bases, minimización, atención de derechos, encargados y transferencias |
| Configuración y NoSQL | Remote Config para flags y parámetros no sensibles; Firestore para proyecciones y datos no relacionales sin romper ownership del core |
| SaaS / híbrido | aislamiento entre tenants, claves por tenant, responsabilidad compartida, portabilidad |
| Vertical inmobiliario | legajo, KYC, beneficiario final, monitoreo y reportabilidad |
| Vertical jurídico | privilegio profesional, confidencialidad reforzada, asunto/caso, defensa no equiparada a cliente UIF |
| Vertical corporativo | contratos, societario, contable, proveedores, RR.HH., plazos diferenciados |

## 7. Matriz de trazabilidad resumida

| Norma o fuente | Impacto principal | Requisito derivado | Prioridad | Módulo afectado |
| --- | --- | --- | --- | --- |
| Constitución Nacional art. 43 | Habeas data y control del titular | RF-032, RNF-010 | Crítica | `admin`, `documents`, `audit` |
| Ley 25.326 | protección de datos, seguridad, derechos del titular | RF-032, RF-033, RNF-009, RNF-010, RNF-011, RNF-012 | Crítica | `auth`, `documents`, `admin` |
| Decreto 1558/2001 | operacionalización de tratamiento y encargados | RF-033, RNF-011 | Alta | `admin`, `integrations` |
| Ley 25.506 arts. 1 a 12 | eficacia jurídica, firma, integridad, conservación | RF-030, RF-031, RF-034, RF-035, RNF-013, RNF-014 | Crítica | `audit`, `records`, `signature` |
| Decreto 182/2019 | reglamentación de infraestructura de firma digital | RF-034, RF-035, RNF-025 | Alta | `signature`, `integrations` |
| Ley 27.446 | interoperabilidad y despapelización | RF-036, RNF-024 | Media | `integrations`, `documents` |
| CCyC arts. 328-330 | retención por 10 años, equivalencia de medios electrónicos, prueba | RF-026, RF-027, RF-028, RF-029, RNF-015 | Crítica | `records`, `audit` |
| Ley 25.246 | AML/CFT y sujetos obligados | RF-039, RF-042, RNF-036 | Alta | `sector_real_estate`, `sector_legal` |
| Ley 27.739 | fortalecimiento del régimen UIF y sanciones | RF-039, RF-042, RNF-036 | Alta | `sector_real_estate`, `sector_legal` |
| UIF Res. 43/2024 | inmobiliarias bajo enfoque basado en riesgo | RF-038, RF-039 | Alta | `sector_real_estate` |
| UIF Res. 48/2024 | abogados alcanzados y exclusiones defensivas | RF-040, RF-041, RF-042 | Alta | `sector_legal` |
| Ley 26.388 | prevención y persecución de conductas informáticas | RF-012, RF-030, RNF-001 a RNF-008 | Crítica | `auth`, `audit`, `backend` |
| Ley 27.411 | cibercriminalidad y cooperación | RF-031, RNF-013 | Media | `audit`, `records` |
| ISO 15489 | autenticidad, fiabilidad, integridad, usabilidad | RF-015, RF-026, RF-028 | Crítica | `documents`, `records` |
| ISO 30301 | gobernanza y mejora continua | RF-008, RF-037, RNF-034 | Alta | `admin`, `audit` |
| ISO 23081 | metadatos documentales | RF-015, RF-016 | Crítica | `documents`, `search` |
| ISO 16175 | requisitos funcionales de software de records | RF-020 a RF-031 | Alta | `records`, `workflow`, `audit` |
| ISO 19005 PDF/A | preservación a largo plazo | RF-031, RNF-016, RNF-024 | Media | `records`, `documents` |
| ISO/IEC 27001 y 27002 | SGSI y controles de seguridad | RNF-001 a RNF-008, RNF-034, RNF-035 | Crítica | transversal |
| ISO/IEC 27005 | gestión de riesgos | RNF-007, RNF-035 | Alta | transversal |
| ISO/IEC 27017 y 27018 | cloud security y privacidad SaaS | RNF-003, RNF-011, RNF-012, RNF-026 | Alta | `platform`, `admin` |
| ISO/IEC 27701 | gestión de privacidad | RF-032, RF-033, RNF-009 a RNF-012 | Alta | `admin`, `documents` |
| ISO 22301 | continuidad del negocio | RNF-017, RNF-018, RNF-019 | Alta | `platform` |
| ISO/IEC 27037 y 27042 | preservación y análisis de evidencia digital | RF-031, RNF-013, RNF-027 | Alta | `audit`, `records` |
| IRAM 36100 | cadena de custodia local | RF-031, RNF-013 | Alta | `audit`, `records` |
| W3C WCAG 2.2 | accesibilidad vigente para UX y componentes | RNF-033 | Alta | `design_system`, `app_shell`, `frontend` |
| PostgreSQL 18.x | persistencia relacional, integridad referencial y consistencia fuerte | RF-047, RF-048, RNF-038, RNF-039, RNF-040 | Crítica | `documents`, `records`, `admin`, `backend` |
| Firebase Remote Config | configuración dinámica no sensible y feature flags | RF-049, RNF-041 | Alta | `config`, `admin` |
| Cloud Firestore | proyecciones y datos no relacionales con reglas de seguridad | RF-050, RNF-042 | Alta | `config`, `integrations`, `frontend` |
| NIST SSDF | seguridad en el SDLC | RNF-006, RNF-025, RNF-029, RNF-032, RNF-035 | Alta | `backend`, `frontend`, `devsecops` |
| OWASP ASVS / API Top 10 | seguridad verificable en app y APIs | RNF-001 a RNF-008, RNF-024 | Crítica | `backend`, `auth`, `api` |

## 8. Recomendación de uso práctico

Para este proyecto, la combinación mínima razonable es:

1. Ley 25.326 + Ley 25.506 + CCyC + Ley 25.246 cuando aplique.
2. ISO 15489 + ISO 23081 + ISO 16175 para la semántica documental.
3. ISO/IEC 27001 + 27002 + 27701 + 22301 para seguridad, privacidad y continuidad.
4. ISO/IEC 27037 + IRAM 36100 para exportación probatoria y cadena de custodia.
5. NIST SSDF + OWASP ASVS como baseline de construcción segura.

## 9. Fuentes oficiales y primarias utilizadas

- [Ley 25.326 - Texto actualizado](https://www.argentina.gob.ar/normativa/nacional/64790/actualizacion)
- [Ley 25.506 - Texto original](https://www.argentina.gob.ar/normativa/nacional/70749/texto)
- [Decreto 182/2019 - Texto original](https://www.argentina.gob.ar/normativa/nacional/decreto-182-2019-320735/texto)
- [Ley 26.994 - Código Civil y Comercial](https://www.argentina.gob.ar/normativa/nacional/ley-26994-235975/texto)
- [Actualización de resoluciones UIF para contadores e inmobiliarias](https://www.argentina.gob.ar/noticias/acualizacion-de-resoluciones-uif-para-contadores-y-agentes-o-corredores-inmobiliarios)
- [Informe UIF 2024 con referencia a Resolución 48/2024](https://www.argentina.gob.ar/sites/default/files/uif-informe-gestion-2024.pdf)
- [Centro de documentación de IRAM](https://www.iram.org.ar/en/documentation-center/)
- [Plan de estudio IRAM 2025](https://www.iram.org.ar/site/UserFiles/pdf/Plan_de_Estudio_2025.pdf)
- [Brochure ISO 30300 series](https://committee.iso.org/files/live/sites/tc46sc11/files/documents/ISO30300Brochure2021.pdf)
- [White paper ISO Records Management by Design](https://committee.iso.org/files/live/sites/tc46sc11/files/documents/White%20paper%20records%20management%20by%20design%20-%20final%20version.pdf)
- [W3C WCAG 2.2 Recommendation](https://www.w3.org/TR/WCAG22/)
- [PostgreSQL current documentation](https://www.postgresql.org/docs/current/)
- [PostgreSQL 18.3 documentation PDF](https://www.postgresql.org/files/documentation/pdf/18/postgresql-18-A4.pdf)
- [Firebase Remote Config documentation](https://firebase.google.com/docs/remote-config)
- [Cloud Firestore documentation](https://firebase.google.com/docs/firestore)
- [NIST SP 800-218 Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final)
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP API Security Project](https://owasp.org/www-project-api-security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
