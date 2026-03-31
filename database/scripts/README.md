# Scripts de Base de Datos

Orden sugerido de ejecución:

1. `001_extensions_and_schemas.sql`
2. `002_core_tables.sql`
3. `003_seed_reference_data.sql`
4. `004_identity_auth_enhancements.sql`
5. `005_records_management_enhancements.sql`
6. `006_document_disposition_status.sql`
7. `007_document_type_metadata_seed_defaults.sql`
8. `008_document_metadata_storage.sql`
9. `009_workflow_tasks.sql`
10. `010_signature_envelopes.sql`
11. `011_case_files.sql`
12. `012_case_file_document_links.sql`
13. `013_document_access_entries.sql`
14. `014_property_files.sql`
15. `015_property_file_document_links.sql`
16. `016_corporate_record_files.sql`
17. `017_corporate_record_file_document_links.sql`
18. `018_workflow_task_assignments.sql`
19. `019_signature_cancellation.sql`

Cuando se usa `docker-compose.yml`, PostgreSQL ejecuta automáticamente estos scripts al inicializar un volumen nuevo.

## Objetivo

- Crear el baseline relacional del sistema.
- Reflejar integridad referencial, checks de dominio y comentarios de esquema.
- Dejar seeds mínimos para roles, tipos documentales y políticas de retención.
