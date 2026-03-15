BEGIN;

ALTER TABLE hierarchy_node_types
    ADD COLUMN IF NOT EXISTS icon_key varchar(80) NOT NULL DEFAULT 'folder';

CREATE INDEX IF NOT EXISTS idx_hierarchy_node_types_project_order
    ON hierarchy_node_types (project_id, sort_order, name);

INSERT INTO schema_migrations (version, name, checksum)
VALUES (
    'V202603151900',
    'add_node_type_icon_key',
    'sha256:pending'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
