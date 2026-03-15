BEGIN;

INSERT INTO permission_catalog (code, name, description, access_kind)
VALUES
    ('documents.read', 'Ver documentos', 'Permite consultar documentos del proyecto y descargar sus PDFs.', 'read'),
    ('documents.write', 'Gestionar documentos', 'Permite escanear, crear documentos y guardar nuevas capturas.', 'write')
ON CONFLICT (code) DO NOTHING;

INSERT INTO project_profile_permissions (project_id, profile_id, permission_code)
SELECT pp.project_id, pp.id, 'documents.read'
FROM project_profiles pp
WHERE pp.code IN ('admin', 'editor', 'viewer')
ON CONFLICT (project_id, profile_id, permission_code) DO NOTHING;

INSERT INTO project_profile_permissions (project_id, profile_id, permission_code)
SELECT pp.project_id, pp.id, 'documents.write'
FROM project_profiles pp
WHERE pp.code IN ('admin', 'editor')
ON CONFLICT (project_id, profile_id, permission_code) DO NOTHING;

INSERT INTO schema_migrations (version, name, checksum)
VALUES (
    'V202603152245',
    'add_document_permissions_v4',
    'sha256:pending'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
