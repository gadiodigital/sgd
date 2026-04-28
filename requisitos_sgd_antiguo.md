# Requisitos Para Incorporar Flujo De Digitalizacion Del SGD Antiguo

Fecha de corte: 2026-04-28

Fuente de referencia: `especificacionesSgdViejo.md`.

## 1. Objetivo

Incorporar al GDMS un flujo operativo de digitalizacion masiva de documentacion fisica historica, inspirado en el sistema anterior usado por la UNLaM, manteniendo trazabilidad completa desde la solicitud de contenedores al deposito externo hasta la disponibilidad del documento digital en el visualizador, con OCR, firma y despacho fisico cuando corresponda.

El objetivo no es replicar literalmente la aplicacion antigua, sino absorber sus capacidades de negocio dentro del modelo modular actual del GDMS: gestion documental, estructura configurable, workflow, auditoria, busqueda, firma, OCR, notificaciones y escaneo local.

## 2. Alcance Funcional

Incluido:

- Gestion de proyectos de digitalizacion por organismo, organización o cliente.
- Carga del manifiesto/listado esperado de contenedores y documentos provisto por el organismo.
- Solicitud, recepcion, verificacion y despacho de lotes fisicos.
- Recepcion detallada por contenedor y documento.
- Gestion de faltantes, sobrantes y documentos sin contenedor presente.
- Etiquetado con codigos de barras para contenedores y documentos.
- Preparacion fisica de documentos antes del escaneo.
- Digitalizacion desde escaner o archivo, con edicion de imagenes por documento.
- Revision contra fisico, indexacion y validacion de metadatos.
- Procesamiento posterior: OCR, indexacion full text y firma digital/electronica.
- Visualizacion web con busqueda por atributos, estructura documental y texto OCR.
- Trazabilidad, auditoria, reportes operativos y tableros de supervision.

Fuera de alcance inicial:

- Automatizacion completa de la logistica del proveedor externo de deposito.
- Integracion productiva directa con Iron Mountain u otro proveedor especifico.
- Reconocimiento automatico infalible de separadores fisicos sin validacion humana.
- Sustitucion de controles fisicos, remitos firmados o procesos operativos exigidos por el cliente.

## 3. Principios De Diseno

- El sistema debe tratar los contenedores fisicos, documentos fisicos, imagenes escaneadas y documentos digitales como entidades relacionadas pero no identicas.
- El codigo de barras debe ser el mecanismo principal de identificacion en estaciones operativas para reducir tipeo manual.
- Todo cambio de estado debe ser validado por reglas de dominio y quedar auditado.
- Los flujos deben poder parametrizarse por proyecto: OCR requerido, firma requerida, eliminacion automatica de blancos, esquemas de metadatos, tipos documentales, cantidad esperada de documentos y reglas de excepcion.
- La digitalizacion debe integrarse con `windows-twain` o adaptador equivalente sin acoplar el dominio a un proveedor o driver especifico.
- El modulo debe reutilizar las capacidades existentes de `documents`, `workflow`, `search`, `signature`, `audit`, `notifications`, `records`, `admin`, `integrations` y la estructura documental configurable.

## 4. Actores

| Actor | Responsabilidad principal |
| --- | --- |
| Supervisor de digitalizacion | Coordina lotes, verifica remitos, resuelve excepciones, supervisa tableros y genera despachos. |
| Operador de recepcion detallada | Registra contenedores y documentos recibidos, verifica completitud y dispara etiquetado. |
| Preparador | Toma contenedores etiquetados, prepara fisicamente documentos y marca avance. |
| Digitalizador | Escanea documentos, edita imagenes, corrige faltantes y envia a revision. |
| Revisor / Indexador | Compara imagen contra fisico, valida completitud, carga metadatos y libera procesamiento. |
| Consultor externo | Busca, visualiza, descarga si esta autorizado y firma documentos desde el visualizador. |
| Administrador de proyecto | Configura manifiestos, reglas, metadatos, OCR, firma, roles y parametros operativos. |
| Auditor | Consulta trazabilidad, remitos, cadena de custodia y reportes de control. |
| Sistema externo de deposito | Origen o receptor de informacion logistica cuando exista integracion. |
| Motor OCR / firma / busqueda | Servicios tecnicos desacoplados que procesan documentos finalizados. |

## 5. Entidades Minimas Sugeridas

- `DigitizationProject`: proyecto de digitalizacion asociado a organización, organismo, reglas y configuracion.
- `ExternalAgency`: organismo o cliente dueño de la documentacion.
- `StorageProvider`: deposito externo o proveedor logistico.
- `ExpectedManifest`: listado esperado provisto por el organismo.
- `ExpectedContainer`: contenedor esperado dentro del manifiesto.
- `ExpectedDocument`: documento esperado dentro de un contenedor.
- `PhysicalBatch`: lote fisico solicitado, recibido o despachado.
- `DeliveryNote`: remito de ingreso, salida o devolucion.
- `PhysicalContainer`: caja, contenedor u otra unidad fisica.
- `PhysicalDocument`: unidad documental fisica, usualmente dentro de folio.
- `BarcodeLabel`: etiqueta asignada a contenedor o documento.
- `WorkstationAssignment`: toma de trabajo por usuario y estacion.
- `PreparationTask`: tarea de preparacion fisica.
- `ScanSession`: sesion de escaneo por contenedor o documento.
- `ScannedImage`: imagen individual de una pagina.
- `ReviewFinding`: observacion de revision, faltante, error o correccion requerida.
- `IndexingRecord`: metadatos capturados o validados durante revision.
- `ProcessingJob`: OCR, indexacion, firma, antivirus u otro proceso posterior.
- `DispatchPackage`: conjunto de contenedores fisicos listos para remito de salida.
- `ExceptionCase`: caso de faltante, sobrante, documento sin contenedor o discrepancia de remito.

## 6. Estados Canonicos

### 6.1 Estados De Contenedor Fisico

| Estado | Significado |
| --- | --- |
| `solicitado` | El contenedor fue pedido al deposito, pero aun no fue recibido. |
| `recibido` | El contenedor llego en un lote fisico y fue aceptado a nivel remito. |
| `en_recepcion_detallada` | Un operador esta registrando documentos del contenedor. |
| `con_faltantes` | La verificacion detecto documentos esperados no encontrados. |
| `con_sobrantes` | La verificacion detecto documentos no esperados en el contenedor. |
| `pendiente_etiquetado` | El contenido fue verificado y puede etiquetarse. |
| `etiquetado` | Las etiquetas fueron impresas y confirmadas como colocadas. |
| `pendiente_preparacion` | El contenedor esta listo para el sector preparacion. |
| `en_preparacion` | Un preparador tomo el contenedor. |
| `pendiente_digitalizacion` | Todos los documentos requeridos fueron preparados. |
| `en_digitalizacion` | Un digitalizador tomo el contenedor. |
| `pendiente_revision_indexacion` | El escaneo minimo esta completo y espera revision. |
| `corregir_escaneo` | Revision detecto faltantes o errores que requieren reescaneo. |
| `pendiente_procesamiento` | El contenedor/documentos esperan OCR, indexacion u otro job. |
| `pendiente_firma` | Los documentos requieren firma digital o electronica. |
| `pendiente_despacho` | El proceso digital finalizo y el contenedor fisico espera devolucion. |
| `despachado` | El contenedor fue incluido en remito de salida firmado. |
| `finalizado` | El ciclo fisico y digital quedo cerrado. |

### 6.2 Estados De Documento

| Estado | Significado |
| --- | --- |
| `esperado` | Documento informado por el manifiesto del organismo. |
| `recibido` | Documento fisico identificado en recepcion detallada. |
| `sobrante` | Documento fisico no esperado en el contenedor actual. |
| `sin_contenedor_presente` | Documento sobrante cuyo contenedor correcto no esta en el lote. |
| `etiquetado` | Documento con etiqueta fisica y codigo de barras asignado. |
| `preparado` | Documento limpio y listo para escaneo. |
| `en_escaneo` | Documento siendo digitalizado. |
| `escaneado` | Documento tiene al menos una imagen asociada. |
| `observado` | Revision detecto problema o requiere decision. |
| `indexado` | Metadatos obligatorios completos y validados. |
| `pendiente_ocr` | Documento espera OCR por configuracion del proyecto. |
| `pendiente_firma` | Documento espera firma por configuracion del proyecto. |
| `publicado` | Documento disponible para visualizacion segun permisos. |
| `finalizado` | Documento completo, trazado y cerrado. |

### 6.3 Reglas Generales De Transicion

- Ningun contenedor debe pasar a `pendiente_etiquetado` si conserva faltantes no resueltos o sobrantes sin clasificar.
- Ningun contenedor debe pasar a `pendiente_digitalizacion` si tiene documentos obligatorios sin preparar.
- Ningun contenedor debe pasar a `pendiente_revision_indexacion` si algun documento recibido y obligatorio no tiene al menos una imagen.
- Un documento `observado` por revision debe bloquear su publicacion hasta resolucion.
- Un contenedor `corregir_escaneo` solo debe volver a revision luego de completar las paginas o documentos observados.
- Un documento debe publicarse en el visualizador solo cuando cumple reglas de OCR, firma, metadatos y permisos del proyecto.
- El despacho fisico no debe eliminar ni ocultar la evidencia digital ni la trazabilidad.

## 7. Requisitos Funcionales

## RF-SGD-001 Alta De Proyecto De Digitalizacion

- Descripcion: el sistema debe permitir crear proyectos de digitalizacion asociados a un organismo, organización, reglas operativas y estructura documental.
- Actor: administrador de proyecto.
- Precondiciones: organización creada; usuario con permiso de administracion.
- Reglas de negocio: cada proyecto debe definir si requiere OCR, firma, eliminacion automatica de blancos, metadatos obligatorios, roles habilitados y formato de etiquetas.
- Criterios de aceptacion:
  - se crea un proyecto con organismo responsable y configuracion inicial;
  - se pueden editar parametros antes de iniciar lotes;
  - los cambios de configuracion quedan versionados y auditados.
- Prioridad: Critica.
- Modulos: `admin`, `documents`, `workflow`, `config`, `audit`.

## RF-SGD-002 Carga Del Manifiesto Esperado

- Descripcion: el sistema debe importar o registrar el listado esperado de contenedores y documentos provisto por el organismo.
- Actor: administrador de proyecto, supervisor.
- Precondiciones: proyecto activo.
- Reglas de negocio: el manifiesto debe tener version, origen, fecha, responsable y validaciones de unicidad logica por contenedor/documento.
- Criterios de aceptacion:
  - se importa un manifiesto desde archivo estructurado;
  - el sistema reporta duplicados, campos obligatorios faltantes y referencias inconsistentes;
  - una nueva version no borra la trazabilidad de versiones anteriores.
- Prioridad: Critica.
- Modulos: `documents`, `admin`, `audit`, `integrations`.

## RF-SGD-003 Solicitud De Contenedores Al Deposito

- Descripcion: el sistema debe registrar solicitudes de contenedores al deposito externo o sector custodio.
- Actor: supervisor.
- Precondiciones: manifiesto cargado y contenedores seleccionados.
- Reglas de negocio: una solicitud debe asociarse a proyecto, proveedor, fecha, lista de contenedores y estado.
- Criterios de aceptacion:
  - se crea solicitud con contenedores esperados;
  - se identifica si un contenedor ya esta solicitado, recibido o finalizado;
  - la solicitud puede exportarse para gestion externa.
- Prioridad: Alta.
- Modulos: `workflow`, `documents`, `integrations`, `audit`.

## RF-SGD-004 Recepcion De Lote Con Remito De Ingreso

- Descripcion: el sistema debe registrar la recepcion fisica de un lote con remito de ingreso y detalle de contenedores recibidos.
- Actor: supervisor.
- Precondiciones: solicitud de contenedores existente o recepcion extraordinaria autorizada.
- Reglas de negocio: el remito debe conservar identificador, proveedor, fecha, transportista, usuario receptor, evidencia de firma o adjunto escaneado.
- Criterios de aceptacion:
  - se registra el remito y sus contenedores;
  - se detectan contenedores no solicitados o solicitados no recibidos;
  - el supervisor puede aceptar con observaciones o rechazar el lote.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `audit`, `records`.

## RF-SGD-005 Verificacion Inicial De Contenedores Contra Remito

- Descripcion: el sistema debe permitir verificar el lote recibido a nivel contenedor contra la solicitud o manifiesto esperado.
- Actor: supervisor.
- Precondiciones: remito de ingreso cargado.
- Reglas de negocio: toda discrepancia debe generar evento auditable y, si corresponde, caso de excepcion.
- Criterios de aceptacion:
  - el sistema muestra contenedores coincidentes, faltantes y sobrantes;
  - no permite iniciar recepcion detallada de un contenedor rechazado;
  - se registra la decision del supervisor.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `notifications`, `audit`.

## RF-SGD-006 Recepcion Detallada Por Codigo De Contenedor

- Descripcion: el operador debe poder tomar un contenedor mediante lectura de codigo de barras o ingreso controlado de identificador.
- Actor: operador de recepcion detallada.
- Precondiciones: contenedor en estado `recibido`.
- Reglas de negocio: un contenedor solo puede estar asignado a un operador activo por vez, salvo permiso de reasignacion.
- Criterios de aceptacion:
  - la lectura del codigo abre el detalle del contenedor correcto;
  - el sistema bloquea toma duplicada concurrente;
  - queda auditado usuario, estacion y hora de toma.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `audit`.

## RF-SGD-007 Registro De Documentos Fisicos Recibidos

- Descripcion: el sistema debe permitir registrar documentos encontrados dentro del contenedor mediante codigo, identificador manual validado o lectura masiva.
- Actor: operador de recepcion detallada.
- Precondiciones: contenedor en recepcion detallada.
- Reglas de negocio: cada documento registrado debe quedar asociado a contenedor fisico, proyecto, usuario y origen de captura.
- Criterios de aceptacion:
  - se ingresan documentos uno por uno con lector;
  - se previenen duplicados dentro del contenedor y del proyecto;
  - el operador puede corregir errores antes de verificar, dejando trazabilidad.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `audit`.

## RF-SGD-008 Verificacion De Completitud De Contenedor

- Descripcion: el sistema debe comparar los documentos registrados contra el manifiesto esperado del organismo.
- Actor: operador de recepcion detallada.
- Precondiciones: documentos del contenedor cargados.
- Reglas de negocio: la verificacion debe clasificar documentos coincidentes, faltantes, sobrantes y duplicados.
- Criterios de aceptacion:
  - el boton `Verificar` muestra resultado detallado;
  - si todo coincide, el contenedor pasa a `pendiente_etiquetado`;
  - si hay discrepancias, el sistema bloquea el avance normal y genera acciones correctivas.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `notifications`, `audit`.

## RF-SGD-009 Gestion De Documentos Faltantes

- Descripcion: el sistema debe gestionar faltantes detectados en la recepcion detallada.
- Actor: operador de recepcion detallada, supervisor.
- Precondiciones: verificacion con faltantes.
- Reglas de negocio: un faltante debe generar caso de excepcion con estado, responsable, motivo, comunicacion y resolucion.
- Criterios de aceptacion:
  - el contenedor queda en estado `con_faltantes`;
  - el supervisor recibe notificacion;
  - se puede cerrar la excepcion por recepcion posterior, error de manifiesto, dispensa autorizada o rechazo.
- Prioridad: Critica.
- Modulos: `workflow`, `notifications`, `documents`, `audit`.

## RF-SGD-010 Gestion De Documentos Sobrantes

- Descripcion: el sistema debe gestionar documentos encontrados que no pertenecen al contenedor segun manifiesto.
- Actor: operador de recepcion detallada, supervisor.
- Precondiciones: verificacion con sobrantes.
- Reglas de negocio: el sistema debe intentar identificar si el sobrante pertenece a otro contenedor del mismo lote o proyecto.
- Criterios de aceptacion:
  - si el contenedor correcto esta presente, se registra movimiento fisico al contenedor correcto;
  - si no esta presente, el documento queda como `sin_contenedor_presente`;
  - el sistema sugiere priorizar la solicitud del contenedor correcto en el proximo lote.
- Prioridad: Alta.
- Modulos: `documents`, `workflow`, `notifications`, `audit`.

## RF-SGD-011 Zona Controlada De Documentos Sin Contenedor

- Descripcion: el sistema debe registrar documentos sobrantes reservados fisicamente en una zona controlada hasta que llegue su contenedor correcto.
- Actor: supervisor, operador de recepcion detallada.
- Precondiciones: documento sobrante sin contenedor presente.
- Reglas de negocio: cada documento reservado debe tener ubicacion fisica, responsable, fecha, motivo y relacion probable con contenedor esperado.
- Criterios de aceptacion:
  - se consulta listado de documentos reservados;
  - se vincula un documento reservado cuando llega su contenedor correcto;
  - se auditan movimientos de entrada y salida de la zona controlada.
- Prioridad: Alta.
- Modulos: `documents`, `workflow`, `audit`.

## RF-SGD-012 Impresion De Etiquetas Con Codigo De Barras

- Descripcion: el sistema debe generar e imprimir etiquetas para contenedores y documentos.
- Actor: operador de recepcion detallada.
- Precondiciones: contenedor en `pendiente_etiquetado`.
- Reglas de negocio: cada etiqueta debe contener identificador legible, codigo de barras, proyecto y tipo de entidad; no debe reutilizarse entre entidades distintas.
- Criterios de aceptacion:
  - se imprimen etiquetas de contenedor y documentos;
  - el sistema registra lote de impresion, usuario e impresora;
  - se puede reimprimir con motivo auditado.
- Prioridad: Critica.
- Modulos: `documents`, `integrations`, `audit`.

## RF-SGD-013 Confirmacion De Etiquetado Fisico

- Descripcion: el operador debe confirmar que las etiquetas fueron colocadas fisicamente en contenedor y folios documentales.
- Actor: operador de recepcion detallada.
- Precondiciones: etiquetas generadas.
- Reglas de negocio: no alcanza con imprimir; el sistema debe registrar confirmacion operativa para avanzar a preparacion.
- Criterios de aceptacion:
  - el operador confirma etiquetado por lectura de codigos o accion de lote;
  - el contenedor pasa a `pendiente_preparacion`;
  - las etiquetas omitidas quedan visibles como pendientes.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-014 Toma De Contenedor En Preparacion

- Descripcion: el preparador debe tomar un contenedor mediante lectura de etiqueta y dejarlo en estado `en_preparacion`.
- Actor: preparador.
- Precondiciones: contenedor en `pendiente_preparacion`.
- Reglas de negocio: la toma debe asignar responsable y evitar procesamiento simultaneo no autorizado.
- Criterios de aceptacion:
  - la lectura del codigo abre la tarea de preparacion;
  - se registra usuario, estacion y hora;
  - el sistema impide tomar contenedores en estados incompatibles.
- Prioridad: Alta.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-015 Preparacion Fisica De Documentos

- Descripcion: el sistema debe permitir marcar documentos como preparados luego de limpieza fisica, retiro de clips, broches u otros elementos.
- Actor: preparador.
- Precondiciones: contenedor en preparacion.
- Reglas de negocio: la preparacion debe registrarse por documento y permitir observaciones de deterioro, ilegibilidad o riesgo fisico.
- Criterios de aceptacion:
  - se marca cada documento como preparado;
  - se registran observaciones opcionales;
  - el contenedor pasa a `pendiente_digitalizacion` cuando todos los documentos obligatorios estan preparados.
- Prioridad: Alta.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-016 Toma De Contenedor En Digitalizacion

- Descripcion: el digitalizador debe tomar un contenedor preparado mediante lectura de codigo de barras.
- Actor: digitalizador.
- Precondiciones: contenedor en `pendiente_digitalizacion`.
- Reglas de negocio: la asignacion debe impedir que dos digitalizadores modifiquen simultaneamente el mismo documento salvo flujo de colaboracion explicitamente configurado.
- Criterios de aceptacion:
  - el sistema asigna el contenedor al digitalizador;
  - se muestra lista de documentos preparados;
  - la toma queda auditada.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-017 Digitalizacion Desde Escaner

- Descripcion: el sistema debe permitir escanear documentos desde una estacion Windows usando `windows-twain` o adaptador equivalente.
- Actor: digitalizador.
- Precondiciones: contenedor asignado; escaner disponible.
- Reglas de negocio: las imagenes capturadas deben vincularse al documento activo, conservar orden de pagina, hash, resolucion y datos tecnicos relevantes.
- Criterios de aceptacion:
  - el digitalizador inicia captura desde la pantalla de documento;
  - cada pagina queda asociada al documento correcto;
  - fallos de escaner no generan paginas fantasma ni perdida silenciosa.
- Prioridad: Critica.
- Modulos: `documents`, `integrations`, `audit`.

## RF-SGD-018 Digitalizacion Desde Archivo

- Descripcion: el digitalizador debe poder agregar imagenes o PDFs desde archivo cuando el proceso lo autorice.
- Actor: digitalizador.
- Precondiciones: documento activo y permiso de carga desde archivo.
- Reglas de negocio: los archivos agregados deben pasar por validacion de tipo, tamano, antivirus y trazabilidad de origen.
- Criterios de aceptacion:
  - se agregan paginas desde archivo al documento activo;
  - se rechazan formatos no permitidos;
  - la accion queda diferenciada de una captura directa por escaner.
- Prioridad: Alta.
- Modulos: `documents`, `integrations`, `audit`.

## RF-SGD-019 Eliminacion Automatica Y Manual De Paginas En Blanco

- Descripcion: el sistema debe soportar eliminacion automatica de paginas en blanco segun configuracion del proyecto y eliminacion manual supervisada.
- Actor: digitalizador, administrador de proyecto.
- Precondiciones: imagenes capturadas.
- Reglas de negocio: la eliminacion automatica debe ser configurable por umbral y reversible antes de cerrar el documento o debe conservar evidencia tecnica suficiente.
- Criterios de aceptacion:
  - un proyecto puede activar o desactivar eliminacion automatica;
  - el digitalizador ve paginas detectadas como blancas;
  - la eliminacion manual requiere accion explicita y queda auditada.
- Prioridad: Alta.
- Modulos: `documents`, `config`, `audit`.

## RF-SGD-020 Edicion Basica De Imagenes Escaneadas

- Descripcion: la pantalla de digitalizacion debe permitir rotar, reordenar, insertar, eliminar y navegar paginas.
- Actor: digitalizador.
- Precondiciones: documento con imagenes capturadas.
- Reglas de negocio: cada edicion debe preservar historial suficiente para auditoria y reconstruccion del orden final.
- Criterios de aceptacion:
  - se rota imagen a izquierda o derecha;
  - se mueve una pagina antes o despues de otra;
  - se inserta pagina en posicion actual o al final;
  - se elimina una pagina con motivo cuando el proyecto lo exige.
- Prioridad: Critica.
- Modulos: `documents`, `audit`.

## RF-SGD-021 Vista De Miniaturas Y Navegacion Por Paginas

- Descripcion: el digitalizador debe contar con miniaturas, pagina actual, salto a pagina especifica y navegacion por documento.
- Actor: digitalizador.
- Precondiciones: documento con imagenes o captura activa.
- Reglas de negocio: la UI debe evitar confundir documento activo, pagina activa y contenedor activo.
- Criterios de aceptacion:
  - se visualizan miniaturas ordenadas;
  - se navega por pagina anterior/siguiente;
  - se puede ir a un numero de pagina especifico;
  - el documento activo permanece claramente identificado.
- Prioridad: Alta.
- Modulos: `documents`, `client`.

## RF-SGD-022 Validacion Minima Antes De Enviar A Revision

- Descripcion: al finalizar la digitalizacion, el sistema debe verificar que todos los documentos obligatorios tengan al menos una imagen.
- Actor: digitalizador, sistema.
- Precondiciones: contenedor en digitalizacion.
- Reglas de negocio: la validacion debe ejecutarse en backend y no depender solo de UI.
- Criterios de aceptacion:
  - si faltan imagenes, el sistema muestra listado de documentos pendientes;
  - no se permite enviar a revision un contenedor incompleto;
  - si todo cumple, el contenedor pasa a `pendiente_revision_indexacion`.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `audit`.

## RF-SGD-023 Toma De Contenedor En Revision E Indexacion

- Descripcion: el revisor debe poder tomar contenedores pendientes de revision mediante bandeja o codigo de barras.
- Actor: revisor / indexador.
- Precondiciones: contenedor en `pendiente_revision_indexacion`.
- Reglas de negocio: la asignacion debe registrar responsable y permitir reasignacion controlada por supervisor.
- Criterios de aceptacion:
  - el revisor toma un contenedor disponible;
  - el sistema muestra documentos e imagenes asociadas;
  - la toma queda auditada.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-024 Revision Contra Documento Fisico

- Descripcion: el revisor debe validar que el escaneo coincida con el documento fisico.
- Actor: revisor / indexador.
- Precondiciones: contenedor tomado para revision.
- Reglas de negocio: la revision debe permitir marcar documento correcto, observado o con faltantes de escaneo.
- Criterios de aceptacion:
  - el revisor registra resultado por documento;
  - se pueden cargar observaciones;
  - los documentos observados bloquean cierre del contenedor.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `audit`.

## RF-SGD-025 Indexacion De Metadatos Por Proyecto

- Descripcion: el revisor debe completar metadatos definidos para contenedor y documento segun el esquema configurable del proyecto.
- Actor: revisor / indexador.
- Precondiciones: esquema de metadatos vigente.
- Reglas de negocio: los campos obligatorios, tipos, rangos, catalogos y validaciones deben respetar la version vigente al momento de indexar.
- Criterios de aceptacion:
  - se muestran formularios dinamicos por tipo documental;
  - no se permite finalizar con metadatos obligatorios faltantes;
  - cada cambio queda auditado con usuario y fecha.
- Prioridad: Critica.
- Modulos: `documents`, `admin`, `audit`.

## RF-SGD-026 Correccion De Escaneo Desde Revision

- Descripcion: cuando revision detecte faltantes o errores, el sistema debe devolver el contenedor o documento a correccion de escaneo.
- Actor: revisor / indexador, digitalizador.
- Precondiciones: documento observado por revision.
- Reglas de negocio: la devolucion debe indicar paginas, documentos, motivo y severidad.
- Criterios de aceptacion:
  - el contenedor pasa a `corregir_escaneo`;
  - el digitalizador ve solo o prioritariamente los puntos observados;
  - al corregir, el flujo vuelve a revision manteniendo historial.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `notifications`, `audit`.

## RF-SGD-027 Finalizacion Documental Posterior A Revision

- Descripcion: el sistema debe finalizar documentos revisados correctamente y decidir el siguiente estado segun configuracion del proyecto.
- Actor: revisor / indexador, sistema.
- Precondiciones: documento revisado e indexado.
- Reglas de negocio: si el proyecto requiere OCR, el documento debe pasar a `pendiente_ocr`; si requiere firma, a `pendiente_firma`; si no requiere procesos adicionales, puede publicarse.
- Criterios de aceptacion:
  - el documento correcto cambia de estado segun reglas configuradas;
  - el contenedor pasa a `pendiente_despacho` cuando todos sus documentos estan completos;
  - el sistema conserva trazabilidad de la decision.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `search`, `signature`, `audit`.

## RF-SGD-028 Procesamiento OCR Posterior A Revision

- Descripcion: el sistema debe ejecutar OCR sobre documentos finalizados cuando el proyecto lo requiera.
- Actor: sistema.
- Precondiciones: documento revisado, indexado y apto para OCR.
- Reglas de negocio: el OCR debe ejecutarse como job trazable, reintentable e idempotente.
- Criterios de aceptacion:
  - se crea job de OCR por documento o lote;
  - el texto OCR queda asociado al documento y versionado;
  - fallos quedan visibles en tablero operativo con posibilidad de reintento.
- Prioridad: Alta.
- Modulos: `documents`, `search`, `integrations`, `audit`.

## RF-SGD-029 Publicacion En Visualizador Web

- Descripcion: los documentos finalizados deben quedar disponibles en el visualizador web segun permisos, estado y politicas del proyecto.
- Actor: consultor externo, usuario autorizado.
- Precondiciones: documento publicado o finalizado.
- Reglas de negocio: el visualizador no debe exponer documentos observados, incompletos, retenidos o sin permisos.
- Criterios de aceptacion:
  - un usuario autorizado encuentra documentos por atributos;
  - un usuario no autorizado no ve resultados ni metadatos sensibles;
  - la apertura de documentos queda auditada.
- Prioridad: Critica.
- Modulos: `documents`, `search`, `auth`, `audit`, `client`.

## RF-SGD-030 Busqueda Por Atributos De Contenedor Y Documento

- Descripcion: el visualizador debe permitir buscar por metadatos de contenedor, documento, proyecto, organismo, remito, lote y estado.
- Actor: consultor externo, supervisor, auditor.
- Precondiciones: indice o consulta disponible.
- Reglas de negocio: los filtros deben respetar permisos y esquema dinamico del proyecto.
- Criterios de aceptacion:
  - se filtra por identificador de caja, documento, lote o remito;
  - se filtra por metadatos indexados;
  - los resultados se paginan y ordenan.
- Prioridad: Critica.
- Modulos: `search`, `documents`, `auth`.

## RF-SGD-031 Busqueda Por Texto OCR

- Descripcion: el visualizador debe permitir busqueda por texto libre extraido por OCR.
- Actor: consultor externo, usuario autorizado.
- Precondiciones: OCR ejecutado e indice actualizado.
- Reglas de negocio: la busqueda full text debe aplicar filtros de seguridad antes de exponer resultados.
- Criterios de aceptacion:
  - se encuentra un documento por palabras del contenido;
  - los fragmentos visibles no revelan documentos sin permiso;
  - se informa si un documento aun no tiene OCR disponible.
- Prioridad: Alta.
- Modulos: `search`, `documents`, `auth`.

## RF-SGD-032 Previsualizacion Segura De Imagenes

- Descripcion: el visualizador debe previsualizar paginas digitalizadas sin requerir descarga.
- Actor: consultor externo, usuario autorizado.
- Precondiciones: documento publicado y renderizable.
- Reglas de negocio: la previsualizacion debe aplicar controles de acceso, marca de agua si corresponde y auditoria de visualizacion.
- Criterios de aceptacion:
  - se navegan paginas del documento;
  - se puede ampliar, reducir y rotar visualmente sin alterar el original;
  - la descarga puede habilitarse o bloquearse por politica.
- Prioridad: Alta.
- Modulos: `documents`, `client`, `auth`, `audit`.

## RF-SGD-033 Firma Digital O Electronica Desde Visualizador

- Descripcion: el visualizador debe permitir iniciar o completar firma digital/electronica cuando el proyecto o documento lo requiera.
- Actor: consultor externo, usuario firmante.
- Precondiciones: proveedor de firma configurado; documento apto para firma.
- Reglas de negocio: el sistema debe distinguir firma electronica y firma digital, conservar evidencia y vincular documento firmado con su original.
- Criterios de aceptacion:
  - se inicia proceso de firma desde el documento;
  - se registra estado de firma;
  - el documento firmado y evidencias quedan asociados al expediente/documento original.
- Prioridad: Alta.
- Modulos: `signature`, `documents`, `integrations`, `audit`.

## RF-SGD-034 Generacion De Remito De Despacho

- Descripcion: el supervisor debe generar remitos de entrega/devolucion con contenedores finalizados.
- Actor: supervisor.
- Precondiciones: contenedores en `pendiente_despacho`.
- Reglas de negocio: un contenedor no puede incluirse en mas de un remito de salida activo.
- Criterios de aceptacion:
  - se seleccionan contenedores listos para despacho;
  - se genera remito con numeracion, fecha, transportista y detalle;
  - el remito puede imprimirse o exportarse.
- Prioridad: Critica.
- Modulos: `documents`, `workflow`, `records`, `audit`.

## RF-SGD-035 Registro De Firma De Transporte En Despacho

- Descripcion: el sistema debe registrar evidencia de recepcion por transporte o deposito al despachar contenedores.
- Actor: supervisor.
- Precondiciones: remito de despacho generado.
- Reglas de negocio: debe conservarse copia firmada o evidencia equivalente vinculada al remito.
- Criterios de aceptacion:
  - se adjunta remito firmado o evidencia digital;
  - los contenedores pasan a `despachado`;
  - queda registrado quien entrego y quien recibio.
- Prioridad: Critica.
- Modulos: `records`, `documents`, `audit`.

## RF-SGD-036 Cierre De Ciclo Fisico Y Digital

- Descripcion: el sistema debe cerrar el ciclo del contenedor cuando el despacho fisico y la disponibilidad digital esten completos.
- Actor: sistema, supervisor.
- Precondiciones: contenedor despachado; documentos publicados o cerrados segun politica.
- Reglas de negocio: el cierre debe validar que no existan excepciones abiertas, jobs criticos fallidos ni firmas pendientes obligatorias.
- Criterios de aceptacion:
  - el contenedor pasa a `finalizado`;
  - el sistema bloquea cierre si hay pendientes criticos;
  - el cierre queda auditado.
- Prioridad: Critica.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-037 Dashboard Operativo De Digitalizacion

- Descripcion: el sistema debe proveer tablero para supervisar lotes, contenedores, documentos, excepciones, productividad y cuellos de botella.
- Actor: supervisor, administrador de proyecto.
- Precondiciones: eventos operativos disponibles.
- Reglas de negocio: los indicadores deben poder filtrarse por proyecto, lote, estado, usuario, rango de fechas y sector.
- Criterios de aceptacion:
  - se visualiza cantidad por estado;
  - se destacan faltantes, sobrantes, correcciones y jobs fallidos;
  - se exportan reportes operativos.
- Prioridad: Alta.
- Modulos: `admin`, `workflow`, `documents`, `audit`, `client`.

## RF-SGD-038 Alertas Y Notificaciones Operativas

- Descripcion: el sistema debe notificar eventos relevantes del flujo de digitalizacion.
- Actor: sistema, supervisor, usuarios operativos.
- Precondiciones: reglas de notificacion configuradas.
- Reglas de negocio: deben notificarse al menos faltantes, sobrantes, contenedores bloqueados, correcciones de escaneo, jobs OCR fallidos y despachos pendientes.
- Criterios de aceptacion:
  - el supervisor recibe alerta por faltante;
  - el digitalizador recibe tarea de correccion;
  - se evita duplicacion excesiva mediante estado de notificacion.
- Prioridad: Alta.
- Modulos: `notifications`, `workflow`, `audit`.

## RF-SGD-039 Bandejas De Trabajo Por Rol

- Descripcion: cada rol operativo debe tener una bandeja con tareas disponibles, asignadas, observadas y vencidas.
- Actor: operador, preparador, digitalizador, revisor, supervisor.
- Precondiciones: workflow activo.
- Reglas de negocio: la bandeja debe filtrar por permisos, sector, proyecto y estado.
- Criterios de aceptacion:
  - cada usuario ve tareas compatibles con su rol;
  - se puede tomar, liberar o reasignar una tarea segun permisos;
  - las tareas vencidas se destacan.
- Prioridad: Alta.
- Modulos: `workflow`, `auth`, `client`.

## RF-SGD-040 Auditoria De Cadena De Custodia

- Descripcion: el sistema debe reconstruir la cadena de custodia fisica y digital de contenedores y documentos.
- Actor: auditor, supervisor.
- Precondiciones: eventos registrados.
- Reglas de negocio: toda toma, movimiento, cambio de estado, escaneo, edicion, revision, firma, publicacion y despacho debe generar evento auditable.
- Criterios de aceptacion:
  - se consulta linea de tiempo de un contenedor;
  - se consulta linea de tiempo de un documento;
  - la exportacion incluye eventos, usuarios, timestamps y evidencias asociadas.
- Prioridad: Critica.
- Modulos: `audit`, `documents`, `workflow`, `records`.

## RF-SGD-041 Reporte De Discrepancias De Manifiesto

- Descripcion: el sistema debe generar reportes de faltantes, sobrantes, duplicados, reubicaciones y documentos reservados.
- Actor: supervisor, auditor, organismo autorizado.
- Precondiciones: recepciones detalladas ejecutadas.
- Reglas de negocio: el reporte debe identificar estado de resolucion y responsable.
- Criterios de aceptacion:
  - se exporta reporte por lote o proyecto;
  - se distingue faltante abierto de faltante resuelto;
  - se incluyen observaciones y evidencias.
- Prioridad: Alta.
- Modulos: `documents`, `workflow`, `audit`.

## RF-SGD-042 Reimpresion Controlada De Etiquetas

- Descripcion: el sistema debe permitir reimprimir etiquetas solo con motivo y permiso adecuados.
- Actor: supervisor, operador autorizado.
- Precondiciones: etiqueta existente.
- Reglas de negocio: la reimpresion debe invalidar o relacionar la etiqueta anterior segun politica del proyecto.
- Criterios de aceptacion:
  - se solicita motivo de reimpresion;
  - se registra usuario e impresora;
  - el historial muestra etiquetas emitidas para la entidad.
- Prioridad: Alta.
- Modulos: `documents`, `audit`.

## RF-SGD-043 Soporte Para Estaciones Con Lector De Codigo De Barras

- Descripcion: las pantallas operativas deben optimizarse para lectura por codigo de barras como entrada primaria.
- Actor: todos los roles operativos.
- Precondiciones: estacion configurada.
- Reglas de negocio: el sistema debe aceptar lectores que funcionen como teclado y, si se implementa integracion avanzada, mantener abstraccion de dispositivo.
- Criterios de aceptacion:
  - un escaneo de codigo ejecuta busqueda o toma de tarea sin pasos innecesarios;
  - se validan codigos desconocidos o de entidad incorrecta;
  - los errores son visibles y audibles/claros para operacion rapida.
- Prioridad: Critica.
- Modulos: `client`, `documents`, `workflow`.

## RF-SGD-044 Parametrizacion De Reglas Por Proyecto

- Descripcion: el administrador debe configurar reglas operativas diferenciadas por proyecto de digitalizacion.
- Actor: administrador de proyecto.
- Precondiciones: proyecto creado.
- Reglas de negocio: las reglas deben ser versionadas y no deben alterar retroactivamente decisiones ya tomadas sin migracion controlada.
- Criterios de aceptacion:
  - se configura OCR requerido, firma requerida y eliminacion de blancos;
  - se configuran metadatos obligatorios y tipos documentales;
  - el sistema registra vigencia y autor de cada cambio.
- Prioridad: Critica.
- Modulos: `admin`, `config`, `documents`, `audit`.

## RF-SGD-045 Integracion Con Estructura Documental Configurable

- Descripcion: los contenedores y documentos digitalizados deben poder vincularse a proyectos, tipos de contenedor y nodos de la estructura documental configurable existente.
- Actor: administrador de proyecto, revisor / indexador.
- Precondiciones: estructura documental configurada.
- Reglas de negocio: el vinculo debe respetar organización, proyecto, tipo de contenedor y reglas padre-hijo.
- Criterios de aceptacion:
  - un contenedor fisico se asocia a un nodo configurado;
  - un documento digitalizado se vincula al nodo que acepta documentos;
  - se rechazan asociaciones fuera dla organización o estructura permitida.
- Prioridad: Alta.
- Modulos: `documents`, `admin`, `audit`.

## RF-SGD-046 Control De Calidad Por Muestreo

- Descripcion: el sistema debe permitir configurar controles de calidad adicionales por muestreo sobre documentos ya revisados.
- Actor: supervisor, auditor de calidad.
- Precondiciones: documentos revisados.
- Reglas de negocio: el porcentaje, criterios de seleccion y resultado del muestreo deben ser parametrizables por proyecto.
- Criterios de aceptacion:
  - se genera muestra de documentos a auditar;
  - se registra resultado de control de calidad;
  - un rechazo puede reabrir correccion o revision segun severidad.
- Prioridad: Media.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-047 Manejo De Documentos Deteriorados O No Escaneables

- Descripcion: el sistema debe permitir registrar documentos que no pueden prepararse o escanearse normalmente por deterioro, formato o riesgo fisico.
- Actor: preparador, digitalizador, supervisor.
- Precondiciones: documento fisico identificado.
- Reglas de negocio: estos casos deben requerir observacion, evidencia y decision autorizada.
- Criterios de aceptacion:
  - se marca documento como deteriorado/no escaneable;
  - se adjunta observacion o imagen de evidencia si corresponde;
  - el supervisor decide continuar, exceptuar o derivar tratamiento especial.
- Prioridad: Alta.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-048 Exportacion De Paquete De Evidencia De Digitalizacion

- Descripcion: el sistema debe exportar un paquete verificable con documento digital, metadatos, OCR, firmas, remitos, hashes y cadena de custodia.
- Actor: auditor, supervisor, organismo autorizado.
- Precondiciones: documento o contenedor con eventos disponibles.
- Reglas de negocio: la exportacion debe respetar permisos y registrar motivo.
- Criterios de aceptacion:
  - se exporta paquete por documento, contenedor o lote;
  - el paquete incluye hashes y eventos relevantes;
  - la exportacion queda auditada.
- Prioridad: Alta.
- Modulos: `records`, `audit`, `documents`.

## RF-SGD-049 Busqueda Y Seguimiento De Ubicacion Fisica

- Descripcion: el sistema debe informar la ubicacion fisica operativa de contenedores y documentos durante el proceso.
- Actor: supervisor, operador autorizado.
- Precondiciones: ubicaciones configuradas.
- Reglas de negocio: las ubicaciones deben representar zonas reales como recepcion, preparacion, digitalizacion, revision, documentos sin contenedor y despacho.
- Criterios de aceptacion:
  - se consulta ubicacion actual de un contenedor;
  - los movimientos entre zonas quedan auditados;
  - el sistema identifica contenedores estancados por tiempo.
- Prioridad: Alta.
- Modulos: `workflow`, `documents`, `audit`.

## RF-SGD-050 Gestion De Permisos Por Sector Operativo

- Descripcion: el sistema debe restringir acciones segun rol, sector, proyecto y estado del objeto.
- Actor: administrador, sistema.
- Precondiciones: roles y permisos configurados.
- Reglas de negocio: un usuario de preparacion no debe poder aprobar revision; un digitalizador no debe poder cerrar despacho salvo permiso especial.
- Criterios de aceptacion:
  - cada accion valida permisos en backend;
  - los botones no autorizados no aparecen o quedan deshabilitados;
  - los intentos denegados quedan auditados cuando sean relevantes.
- Prioridad: Critica.
- Modulos: `auth`, `workflow`, `documents`, `audit`.

## 8. Requisitos No Funcionales Especificos

## RNF-SGD-001 Trazabilidad Fisico-Digital Extremo A Extremo

- Categoria: Trazabilidad.
- Descripcion: el sistema debe mantener continuidad verificable entre manifiesto, remito, contenedor fisico, documento fisico, imagen escaneada, documento digital, OCR, firma y despacho.
- Metrica/SLO: 100% de documentos publicados con referencia a origen fisico y eventos minimos de cadena de custodia.
- Metodo de validacion: pruebas end-to-end por lote y auditoria de muestras.
- Impacto arquitectonico: eventos de dominio, auditoria append-only, identificadores estables y hashes.

## RNF-SGD-002 Operacion Eficiente Con Lector De Barras

- Categoria: Usabilidad operativa.
- Descripcion: las pantallas de recepcion, preparacion, digitalizacion, revision y despacho deben soportar operacion fluida por lector de codigo de barras.
- Metrica/SLO: las acciones frecuentes deben requerir la menor cantidad de clicks posible luego de la lectura; objetivo P95 de apertura de entidad menor o igual a 1 segundo en entorno nominal.
- Metodo de validacion: pruebas con lector tipo teclado y sesiones de usuario operativo.
- Impacto arquitectonico: foco automatico, rutas directas, validaciones rapidas y manejo claro de errores.

## RNF-SGD-003 Integridad De Imagenes Escaneadas

- Categoria: Calidad de datos.
- Descripcion: cada imagen capturada debe conservar hash, orden, documento asociado, usuario, estacion, fecha y origen de captura.
- Metrica/SLO: 100% de imagenes persistidas con metadatos tecnicos minimos.
- Metodo de validacion: pruebas de captura, edicion y auditoria.
- Impacto arquitectonico: modelo de paginas/versiones, storage con metadatos y auditoria de ediciones.

## RNF-SGD-004 Resiliencia Ante Fallos De Escaner O Red

- Categoria: Resiliencia.
- Descripcion: el flujo de escaneo debe tolerar fallos parciales sin corromper documentos ni perder paginas ya confirmadas.
- Metrica/SLO: 0 perdida silenciosa de paginas confirmadas; recuperacion de sesion o estado consistente luego de error.
- Metodo de validacion: pruebas interrumpiendo escaner, host local y API durante captura.
- Impacto arquitectonico: guardado transaccional por pagina/lote, estados intermedios y reintentos idempotentes.

## RNF-SGD-005 Rendimiento En Lotes Masivos

- Categoria: Rendimiento.
- Descripcion: la recepcion, verificacion, busqueda y tableros deben funcionar con lotes grandes de contenedores y documentos.
- Metrica/SLO: busquedas operativas P95 menor o igual a 2 segundos; verificacion de contenedor tipico P95 menor o igual a 3 segundos bajo carga nominal.
- Metodo de validacion: pruebas con datasets realistas de lotes historicos.
- Impacto arquitectonico: indices por proyecto, contenedor, documento, estado y uso adecuado de OpenSearch/proyecciones.

## RNF-SGD-006 Auditoria Tamper-Evident De Acciones Criticas

- Categoria: Seguridad y auditoria.
- Descripcion: las acciones criticas del proceso de digitalizacion deben registrarse en auditoria resistente a manipulacion.
- Metrica/SLO: 100% de cambios de estado, excepciones, ediciones de imagen, reimpresiones, firmas y despachos auditados.
- Metodo de validacion: revision de eventos y pruebas de integridad.
- Impacto arquitectonico: uso del modulo `audit`, correlacion por lote/contenedor/documento y hash chaining o tecnica equivalente.

## RNF-SGD-007 Separacion De Responsabilidades

- Categoria: Seguridad operativa.
- Descripcion: el sistema debe permitir separar funciones de recepcion, preparacion, digitalizacion, revision, supervision y auditoria.
- Metrica/SLO: 100% de acciones protegidas por permisos en backend.
- Metodo de validacion: pruebas RBAC/ABAC y escenarios de intento no autorizado.
- Impacto arquitectonico: politicas por rol, estado, proyecto y sector.

## RNF-SGD-008 Accesibilidad Y Legibilidad En Estaciones Operativas

- Categoria: Experiencia.
- Descripcion: las pantallas operativas deben ser legibles en ambientes de trabajo intensivo y compatibles con teclado.
- Metrica/SLO: flujos criticos compatibles con WCAG 2.2 AA cuando aplique y navegacion por teclado en acciones frecuentes.
- Metodo de validacion: checklist de accesibilidad y pruebas manuales.
- Impacto arquitectonico: componentes accesibles, foco visible, contrastes adecuados y atajos.

## RNF-SGD-009 Parametrizacion Sin Recompilacion

- Categoria: Mantenibilidad.
- Descripcion: reglas de OCR, firma, blancos, metadatos, etiquetas, ubicaciones y estados visibles deben poder configurarse por proyecto sin recompilar.
- Metrica/SLO: 100% de parametros operativos del proyecto administrables desde configuracion o catalogos.
- Metodo de validacion: pruebas de cambio de configuracion en proyecto piloto.
- Impacto arquitectonico: `ConfigPort`, configuracion versionada y catalogos por organización/proyecto.

## RNF-SGD-010 Preservacion De Documentos A Largo Plazo

- Categoria: Records management.
- Descripcion: los documentos digitalizados deben poder preservarse en formatos adecuados, con metadatos, hash y evidencias exportables.
- Metrica/SLO: 100% de documentos finalizados exportables con paquete de evidencia.
- Metodo de validacion: pruebas de exportacion, lectura independiente y verificacion de hashes.
- Impacto arquitectonico: integracion con `records`, formatos abiertos y almacenamiento S3-compatible.

## RNF-SGD-011 Observabilidad Del Pipeline De Procesamiento

- Categoria: Observabilidad.
- Descripcion: OCR, indexacion, firma, generacion de previsualizaciones y jobs asociados deben tener estado observable.
- Metrica/SLO: 100% de jobs con estado, timestamps, reintentos y error visible.
- Metodo de validacion: pruebas de jobs fallidos y tableros operativos.
- Impacto arquitectonico: outbox, workers idempotentes, correlacion por documento y alertas.

## RNF-SGD-012 Compatibilidad Con Despliegue Hibrido

- Categoria: Portabilidad.
- Descripcion: el flujo debe funcionar en SaaS, instancia única y on-premise, contemplando estaciones Windows locales para escaneo.
- Metrica/SLO: mismo dominio y API para los modelos de despliegue soportados.
- Metodo de validacion: prueba local con `windows-twain` y API; prueba de despliegue remoto con adaptador simulado.
- Impacto arquitectonico: adaptadores desacoplados, configuracion externa y puertos para dispositivos.

## 9. Pantallas Minimas Requeridas

### 9.1 Administracion De Proyecto De Digitalizacion

- Configuracion del organismo, manifiesto, reglas de OCR/firma, eliminacion de blancos, metadatos y formatos de etiqueta.
- Versionado de configuracion.
- Validacion previa al inicio de lotes.

### 9.2 Recepcion De Lotes

- Alta o seleccion de solicitud.
- Carga de remito de ingreso.
- Comparacion contra contenedores esperados.
- Registro de aceptacion, rechazo u observaciones.

### 9.3 Recepcion Detallada De Contenedor

- Lectura de codigo de contenedor.
- Registro de documentos.
- Boton `Verificar`.
- Vista de faltantes, sobrantes, duplicados y acciones sugeridas.
- Impresion y confirmacion de etiquetas.

### 9.4 Preparacion

- Lectura de contenedor.
- Lista de documentos a preparar.
- Marcado por documento.
- Registro de observaciones fisicas.

### 9.5 Digitalizacion

- Lectura/toma de contenedor.
- Lista de documentos del contenedor.
- Escaneo desde dispositivo.
- Agregado desde archivo.
- Miniaturas, pagina actual, rotacion, reordenamiento, insercion, eliminacion y salto de pagina.
- Validacion antes de enviar a revision.

### 9.6 Revision E Indexacion

- Bandeja de contenedores pendientes.
- Comparacion contra fisico.
- Formulario dinamico de metadatos.
- Marcado correcto, observado o corregir escaneo.
- Cierre de documento y contenedor.

### 9.7 Dashboard De Supervision

- Conteo por estado, lote, proyecto y sector.
- Alertas por faltantes, sobrantes, correcciones, jobs fallidos y despachos pendientes.
- Productividad por usuario/sector.
- Exportacion de reportes.

### 9.8 Despacho

- Bandeja de contenedores pendientes de despacho.
- Generacion de remito.
- Registro de firma de transporte.
- Cierre de ciclo fisico.

### 9.9 Visualizador Web

- Busqueda por atributos y OCR.
- Filtros por proyecto, contenedor, documento, lote, remito y metadatos.
- Previsualizacion segura.
- Firma digital/electronica cuando corresponda.
- Descarga/exportacion segun permisos.

## 10. Integraciones Y Puertos Sugeridos

- `ScannerPort`: capturar paginas desde escaner local.
- `BarcodePort`: normalizar lectura de codigos cuando no alcance el modo teclado.
- `LabelPrinterPort`: imprimir y reimprimir etiquetas.
- `ManifestImportPort`: importar manifiestos desde CSV, Excel, JSON o API.
- `StorageProviderPort`: integrar deposito externo si se automatiza solicitud/remito.
- `OCRPort`: ejecutar OCR.
- `SignatureProviderPort`: firma digital/electronica.
- `SearchPort`: indexar metadatos y texto OCR.
- `AuditExportPort`: exportar evidencias.
- `NotificationPort`: alertas operativas.

## 11. Backlog De Implementacion Sugerido

| Fase | Objetivo | Entregables |
| --- | --- | --- |
| 1 | Fundacion del dominio de digitalizacion | Entidades, estados, permisos, auditoria y configuracion de proyecto. |
| 2 | Recepcion y excepciones | Manifiesto, solicitud, remito, recepcion detallada, faltantes/sobrantes y etiquetas. |
| 3 | Preparacion y digitalizacion | Bandejas, preparacion, integracion scanner, edicion de paginas y validacion minima. |
| 4 | Revision e indexacion | Formularios dinamicos, observaciones, correccion de escaneo y cierre documental. |
| 5 | Procesamiento y visualizador | OCR, indexacion, busqueda, previsualizacion, firma y publicacion. |
| 6 | Despacho y auditoria avanzada | Remitos de salida, cierre fisico, paquetes de evidencia, dashboards y reportes. |

## 12. Riesgos Y Decisiones Pendientes

- Definir si el modulo se implementara como `digitization` independiente o como extension de `documents` y `workflow`.
Se debe implementar como modulo independiente.

- Definir formato oficial de manifiestos provistos por organismos.
Esto se definira posteriormente

- Definir estandar de codigo de barras y contenido minimo de etiquetas.
Por el momento sera para contenedores numero de contenedor autoincremental, y para documentos numero de documento autoincremental 

- Definir si las imagenes escaneadas se preservan como imagenes individuales, PDF/A generado o ambos.
Las imagenes escaneadas deben permanecer como individuales hasta la finalizacion donde se procesan a pdf/a, en caso tener configurado el OCR se este pasaje a PDF/A con OCR

- Definir reglas exactas de eliminacion de blancos y evidencia de paginas descartadas.
Se configura en los escaners que posean esta feature, tambien se puede configurar a nivel modulo escaneo que verique contenido mininmo.

- Definir proveedor o modalidad de firma digital/electronica.
A definir posteriormente

- Definir politica de retencion de remitos fisicos digitalizados y evidencias de transporte.
Deben escanearse los remitos firmados y agregarse al sistema para tener evidencia.

- Definir si el visualizador externo sera el mismo cliente GDMS con permisos externos o una experiencia web separada.
Sera el mismo cliente con permisos externos

- Definir nivel de integracion requerido con depositos externos como Iron Mountain.
No se integraran en esta version.



