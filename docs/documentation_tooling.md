# Evaluación de herramienta de documentación

## Objetivo

Definir la mejor estrategia para documentar el backend y, más adelante, el frontend, reutilizando comentarios en el código.

## Candidatos evaluados

### Doxygen

Ventajas:

- Muy conocido.
- Funciona con múltiples lenguajes.

Desventajas para este proyecto:

- No es la opción más natural para el ecosistema moderno `.NET`.
- Integra peor con comentarios XML de C# y con OpenAPI/Swagger.
- Requiere más adaptación para obtener una documentación web agradable y útil para APIs.

### DocFX

Ventajas:

- Se integra de forma nativa con comentarios XML de `.NET`.
- Genera documentación estática navegable y profesional.
- Permite mezclar referencia de API, Markdown, arquitectura, ADRs y guías operativas.
- Encaja bien con Swagger/OpenAPI como complemento.

Desventajas:

- Requiere pipeline de generación y publicación.
- No documenta Dart/Flutter tan naturalmente como C#.

### Swagger / OpenAPI

Ventajas:

- Excelente para documentar y probar servicios HTTP.
- Se alimenta muy bien de comentarios XML y atributos de ASP.NET.
- Es imprescindible para consumidores de API.

Desventajas:

- No reemplaza una documentación de arquitectura o de dominio.
- No es suficiente por sí sola para decisiones técnicas o runbooks.

## Recomendación

La mejor combinación para este proyecto es:

1. `Swagger/OpenAPI` para contratos HTTP y prueba interactiva.
2. `DocFX` como reemplazo recomendado de Doxygen para el backend `.NET`.
3. `dart doc` en el futuro frontend Flutter.

## Estrategia concreta

- Documentar controladores, DTOs, servicios y entidades públicas con comentarios XML `///`.
- Configurar Swagger para consumir los archivos XML generados por la compilación.
- Generar un sitio con DocFX para:
  - referencia de API;
  - arquitectura;
  - decisiones técnicas;
  - instalación;
  - operación;
  - seguridad.

## Resultado esperado

- Un solo origen de verdad en comentarios de código.
- Swagger útil para integradores.
- DocFX útil para equipo interno, onboarding, auditorías y operación.
