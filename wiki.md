# Wiki del Proyecto GDMS

## 1. Propósito

Este archivo funciona como índice operativo del proyecto `GDMS` para desarrollo, onboarding y seguimiento de avance.

Sirve para:

- entender el objetivo del sistema;
- ubicar la documentación principal;
- ver el plan de desarrollo vigente;
- revisar el roadmap por fases;
- identificar qué archivos deben leerse primero para instalar, ejecutar y usar el sistema.

## 2. Qué es GDMS

`GDMS` es un sistema de gestión documental y `ECM` modular, multi-tenant, auditable y orientado a operación real para organizaciones como:

- empresas;
- inmobiliarias;
- estudios jurídicos;
- áreas de compliance, records y administración.

El alcance actual del repo cubre:

- backend `.NET`;
- frontend `Flutter`;
- base relacional `PostgreSQL`;
- host local de escaneo `windows-twain`;
- infraestructura local con Docker;
- documentación funcional, técnica y operativa.

## 3. Arquitectura resumida

### Backend

- Solución principal: [server\Gdms.sln](C:\IA\codex\server\Gdms.sln)
- Stack: `.NET 10`, `C#`, `Clean Architecture`, `modular monolith`
- API: [server\src\Gdms.Api](C:\IA\codex\server\src\Gdms.Api)
- Aplicación: [server\src\Gdms.Application](C:\IA\codex\server\src\Gdms.Application)
- Dominio: [server\src\Gdms.Domain](C:\IA\codex\server\src\Gdms.Domain)
- Infraestructura: [server\src\Gdms.Infrastructure](C:\IA\codex\server\src\Gdms.Infrastructure)

### Frontend

- App principal: [client\apps\gdms_app](C:\IA\codex\client\apps\gdms_app)
- Core compartido: [client\packages\core](C:\IA\codex\client\packages\core)
- Design system: [client\packages\design_system](C:\IA\codex\client\packages\design_system)
- Features modulares: [client\packages](C:\IA\codex\client\packages)

### Escaneo local

- Host local TWAIN: [windows-twain](C:\IA\codex\windows-twain)
- Proyecto: [windows-twain\windows-twain.csproj](C:\IA\codex\windows-twain\windows-twain.csproj)
- Documentación: [windows-twain\documentacion.md](C:\IA\codex\windows-twain\documentacion.md)

### Infraestructura

- Docker Compose: [docker-compose.yml](C:\IA\codex\docker-compose.yml)
- Scripts de setup Windows: [scripts\setup\windows](C:\IA\codex\scripts\setup\windows)
- Validación de workspace: [scripts\quality\validate_workspace.ps1](C:\IA\codex\scripts\quality\validate_workspace.ps1)

## 4. Documentos que deben leerse primero

### Para configurar el ambiente de desarrollo

Leer en este orden:

1. [scripts\setup\windows\README.md](C:\IA\codex\scripts\setup\windows\README.md)
2. [docs\migracion_nueva_pc_windows_docker.md](C:\IA\codex\docs\migracion_nueva_pc_windows_docker.md)
3. [docs\implementacion_backend_docker.md](C:\IA\codex\docs\implementacion_backend_docker.md)
4. [windows-twain\documentacion.md](C:\IA\codex\windows-twain\documentacion.md)

### Para entender el sistema desde negocio y uso

Leer:

1. [MANUAL_USUARIO.md](C:\IA\codex\MANUAL_USUARIO.md)
2. [rf.md](C:\IA\codex\rf.md)
3. [rnf.md](C:\IA\codex\rnf.md)
4. [normas_relacionadas.md](C:\IA\codex\normas_relacionadas.md)

### Para entender el estado actual del proyecto

Leer:

1. [contexto_handoff.md](C:\IA\codex\contexto_handoff.md)
2. [client\README.md](C:\IA\codex\client\README.md)
3. [database\scripts\README.md](C:\IA\codex\database\scripts\README.md)
4. [docs\plan_desarrollo_sesiones_grandes.md](C:\IA\codex\docs\plan_desarrollo_sesiones_grandes.md)

## 5. Estado actual resumido

Estado estimado actual del proyecto: `86%`.

### Bloques con mayor avance

- arquitectura base backend;
- frontend operativo transversal;
- módulo documental;
- escaneo documental con `windows-twain`;
- administración, auditoría, búsqueda, workflow, firma, records, reportes y notificaciones;
- verticales `Legal`, `Real Estate` y `Corporate`.

### Bloques con mayor trabajo pendiente

- integraciones productivas reales;
- endurecimiento de despliegue;
- observabilidad y seguridad operativa;
- validación end-to-end más amplia;
- cierre de dependencias externas como `Firestore`, `S3-compatible`, `OpenSearch` y proveedores de firma.

## 6. Plan de desarrollo vigente

## Fase 1. Base de plataforma

Objetivo:
dejar estable la plataforma común para desarrollo, pruebas y operación local.

Incluye:

- backend modular `.NET`;
- frontend Flutter modular;
- PostgreSQL;
- autenticación y autorización base;
- documentación técnica y scripts de setup;
- bootstrap local por Docker y modo sin Docker.

Estado: `muy avanzado`

## Fase 2. Núcleo documental

Objetivo:
completar el núcleo de gestión documental y su operación principal.

Incluye:

- alta documental;
- tipos documentales y metadatos dinámicos;
- detalle documental;
- descarga;
- versionado;
- exportación probatoria;
- permisos documentales;
- vínculos con expedientes y legajos.

Estado: `muy avanzado`

## Fase 3. Operación documental ampliada

Objetivo:
cerrar la operación transversal asociada al documento.

Incluye:

- búsqueda documental;
- workflow;
- firma;
- records management;
- auditoría;
- notificaciones;
- reportes;
- paneles administrativos.

Estado: `avanzado`

## Fase 4. Escaneo local y captura

Objetivo:
integrar captura física de documentos en la operación diaria del sistema.

Incluye:

- host local `windows-twain`;
- escaneo ADF y flatbed;
- sesiones persistidas;
- mantenimiento de sesiones;
- preview;
- inserción, merge y descarte;
- reanudación de sesiones;
- integración `scan -> upload`.

Estado: `muy avanzado`

## Fase 5. Integraciones y cierre productivo

Objetivo:
llevar el sistema desde beta interna a readiness productivo.

Incluye:

- storage binario productivo;
- búsqueda productiva;
- proyecciones/no relacional;
- integraciones externas;
- endurecimiento de seguridad;
- observabilidad;
- despliegue repetible;
- validación end-to-end;
- runbooks operativos.

Estado: `pendiente parcial`

Plan operativo complementario para sesiones grandes:

- [docs\plan_desarrollo_sesiones_grandes.md](C:\IA\codex\docs\plan_desarrollo_sesiones_grandes.md)

## 7. Roadmap

## Roadmap inmediato

### 1. Cierre técnico del módulo documental

- consolidar más pruebas de integración entre upload, versionado y metadatos;
- cerrar wiring final de permisos y evidencias en backend y frontend;
- validar flujos de error y recuperación.

### 2. Cierre operativo del escaneo

- terminar la cobertura de integración alrededor del flujo completo de escaneo;
- estabilizar el uso en escenarios de host caído, recovery y mantenimiento;
- endurecer la experiencia de operador para ambientes Windows reales.

### 3. Endurecimiento del backend real

- completar persistencias reales faltantes;
- cerrar integraciones con storage y búsqueda;
- ampliar trazabilidad, auditoría técnica y manejo de errores.

## Roadmap de beta interna

Objetivo:
tener una versión usable de punta a punta por equipo interno o piloto controlado.

Entregables:

- backend y frontend integrados sobre flujo documental principal;
- escaneo local operativo;
- login, administración base y auditoría;
- records, firma, workflow y búsqueda en primera versión;
- documentación de setup y uso;
- validación funcional por módulo.

## Roadmap de preproducción

Objetivo:
pasar de una beta funcional a una plataforma instalable con menor riesgo operativo.

Entregables:

- despliegue repetible;
- observabilidad mínima;
- estrategia de backups y recuperación;
- secretos y configuración endurecida;
- storage productivo;
- búsqueda productiva;
- smoke tests y validación end-to-end.

## Roadmap de producción

Objetivo:
habilitar operación sostenida en entornos reales.

Entregables:

- integraciones externas consolidadas;
- monitoreo y alertas;
- seguridad operativa cerrada;
- procedimientos de soporte;
- validación normativa y documental;
- manuales de operación, usuario y despliegue completos.

## 8. Cómo arrancar a trabajar rápido

### Setup del entorno

Usar:

- [scripts\setup\windows\README.md](C:\IA\codex\scripts\setup\windows\README.md)

### Abrir el repo en Visual Studio Code

```powershell
code C:\IA\codex
```

### Levantar subproyectos principales

#### Backend por Docker

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\setup\windows\16-run-gdms-docker.ps1
```

#### API local `.NET`

```powershell
cd C:\IA\codex\server
dotnet run --project .\src\Gdms.Api\Gdms.Api.csproj
```

#### Host local `windows-twain`

```powershell
cd C:\IA\codex\windows-twain
dotnet run --project .\windows-twain.csproj
```

#### App Flutter

```powershell
cd C:\IA\codex\client\apps\gdms_app
flutter run --dart-define=GDMS_API_BASE_URL=http://localhost:5012
```

### Validación final

```powershell
cd C:\IA\codex
powershell -ExecutionPolicy Bypass -File .\scripts\quality\validate_workspace.ps1
```

## 9. Referencia rápida de archivos clave

- Setup Windows: [scripts\setup\windows\README.md](C:\IA\codex\scripts\setup\windows\README.md)
- Manual de usuario: [MANUAL_USUARIO.md](C:\IA\codex\MANUAL_USUARIO.md)
- Contexto técnico general: [contexto_handoff.md](C:\IA\codex\contexto_handoff.md)
- Requisitos funcionales: [rf.md](C:\IA\codex\rf.md)
- Requisitos no funcionales: [rnf.md](C:\IA\codex\rnf.md)
- Backend Docker: [docs\implementacion_backend_docker.md](C:\IA\codex\docs\implementacion_backend_docker.md)
- Migración a nueva PC: [docs\migracion_nueva_pc_windows_docker.md](C:\IA\codex\docs\migracion_nueva_pc_windows_docker.md)
- Windows TWAIN: [windows-twain\documentacion.md](C:\IA\codex\windows-twain\documentacion.md)

## 10. Criterio de uso de esta wiki

Esta wiki debe mantenerse como resumen ejecutivo y mapa de navegación del repo.

No debería reemplazar:

- la documentación contractual;
- la guía de setup;
- el manual de usuario;
- la documentación técnica específica de cada subproyecto.

Su función es indicar:

- qué leer;
- en qué estado está el proyecto;
- cuál es el plan;
- hacia dónde sigue el roadmap.
