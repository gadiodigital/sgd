BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS schema_migrations (
    version varchar(64) PRIMARY KEY,
    name varchar(200) NOT NULL,
    checksum varchar(128) NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug varchar(80) NOT NULL UNIQUE,
    name varchar(160) NOT NULL,
    description text NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hierarchy_node_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    code varchar(80) NOT NULL,
    name varchar(120) NOT NULL,
    description text NULL,
    allows_documents boolean NOT NULL DEFAULT true,
    is_root_allowed boolean NOT NULL DEFAULT false,
    sort_order integer NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_hierarchy_node_types_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT uq_hierarchy_node_types_project_code
        UNIQUE (project_id, code),
    CONSTRAINT uq_hierarchy_node_types_project_id
        UNIQUE (project_id, id)
);

CREATE TABLE IF NOT EXISTS hierarchy_type_rules (
    project_id uuid NOT NULL,
    parent_node_type_id uuid NOT NULL,
    child_node_type_id uuid NOT NULL,
    min_children integer NOT NULL DEFAULT 0,
    max_children integer NULL,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, parent_node_type_id, child_node_type_id),
    CONSTRAINT fk_hierarchy_type_rules_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_hierarchy_type_rules_parent_type
        FOREIGN KEY (project_id, parent_node_type_id)
        REFERENCES hierarchy_node_types(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_hierarchy_type_rules_child_type
        FOREIGN KEY (project_id, child_node_type_id)
        REFERENCES hierarchy_node_types(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT ck_hierarchy_type_rules_bounds
        CHECK (max_children IS NULL OR max_children >= min_children)
);

CREATE TABLE IF NOT EXISTS attribute_definitions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    scope varchar(30) NOT NULL,
    code varchar(80) NOT NULL,
    name varchar(120) NOT NULL,
    data_type varchar(30) NOT NULL,
    is_required boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    default_value text NULL,
    help_text text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_attribute_definitions_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT uq_attribute_definitions_project_scope_code
        UNIQUE (project_id, scope, code),
    CONSTRAINT uq_attribute_definitions_project_id
        UNIQUE (project_id, id),
    CONSTRAINT ck_attribute_definitions_scope
        CHECK (scope IN ('node', 'document')),
    CONSTRAINT ck_attribute_definitions_data_type
        CHECK (data_type IN ('text', 'number', 'date', 'boolean', 'json'))
);

CREATE TABLE IF NOT EXISTS node_type_attributes (
    project_id uuid NOT NULL,
    node_type_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    display_order integer NOT NULL DEFAULT 0,
    PRIMARY KEY (project_id, node_type_id, attribute_definition_id),
    CONSTRAINT fk_node_type_attributes_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_node_type_attributes_node_type
        FOREIGN KEY (project_id, node_type_id)
        REFERENCES hierarchy_node_types(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_node_type_attributes_attribute
        FOREIGN KEY (project_id, attribute_definition_id)
        REFERENCES attribute_definitions(project_id, id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS document_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    code varchar(80) NOT NULL,
    name varchar(120) NOT NULL,
    description text NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_document_types_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT uq_document_types_project_code
        UNIQUE (project_id, code),
    CONSTRAINT uq_document_types_project_id
        UNIQUE (project_id, id)
);

CREATE TABLE IF NOT EXISTS document_type_attributes (
    project_id uuid NOT NULL,
    document_type_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    display_order integer NOT NULL DEFAULT 0,
    PRIMARY KEY (project_id, document_type_id, attribute_definition_id),
    CONSTRAINT fk_document_type_attributes_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_document_type_attributes_document_type
        FOREIGN KEY (project_id, document_type_id)
        REFERENCES document_types(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_document_type_attributes_attribute
        FOREIGN KEY (project_id, attribute_definition_id)
        REFERENCES attribute_definitions(project_id, id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS hierarchy_nodes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    node_type_id uuid NOT NULL,
    parent_id uuid NULL,
    code varchar(80) NULL,
    name varchar(160) NOT NULL,
    description text NULL,
    sort_order integer NOT NULL DEFAULT 0,
    depth integer NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_hierarchy_nodes_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_hierarchy_nodes_node_type
        FOREIGN KEY (project_id, node_type_id)
        REFERENCES hierarchy_node_types(project_id, id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_hierarchy_nodes_parent
        FOREIGN KEY (project_id, parent_id)
        REFERENCES hierarchy_nodes(project_id, id)
        ON DELETE RESTRICT,
    CONSTRAINT uq_hierarchy_nodes_project_id
        UNIQUE (project_id, id),
    CONSTRAINT uq_hierarchy_nodes_sibling_name
        UNIQUE NULLS NOT DISTINCT (project_id, parent_id, name),
    CONSTRAINT uq_hierarchy_nodes_sibling_code
        UNIQUE NULLS NOT DISTINCT (project_id, parent_id, code)
);

CREATE TABLE IF NOT EXISTS node_attribute_values (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    node_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    value_text text NULL,
    value_number numeric(18, 4) NULL,
    value_date date NULL,
    value_boolean boolean NULL,
    value_json jsonb NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_node_attribute_values_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_node_attribute_values_node
        FOREIGN KEY (project_id, node_id)
        REFERENCES hierarchy_nodes(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_node_attribute_values_attribute
        FOREIGN KEY (project_id, attribute_definition_id)
        REFERENCES attribute_definitions(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT uq_node_attribute_values
        UNIQUE (project_id, node_id, attribute_definition_id)
);

CREATE TABLE IF NOT EXISTS documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    node_id uuid NULL,
    document_type_id uuid NULL,
    title varchar(240) NOT NULL,
    description text NULL,
    status varchar(30) NOT NULL DEFAULT 'draft',
    current_version_number integer NOT NULL DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_documents_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_documents_node
        FOREIGN KEY (project_id, node_id)
        REFERENCES hierarchy_nodes(project_id, id)
        ON DELETE SET NULL,
    CONSTRAINT fk_documents_document_type
        FOREIGN KEY (project_id, document_type_id)
        REFERENCES document_types(project_id, id)
        ON DELETE SET NULL,
    CONSTRAINT uq_documents_project_id
        UNIQUE (project_id, id),
    CONSTRAINT ck_documents_status
        CHECK (status IN ('draft', 'active', 'archived'))
);

CREATE TABLE IF NOT EXISTS document_attribute_values (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    document_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    value_text text NULL,
    value_number numeric(18, 4) NULL,
    value_date date NULL,
    value_boolean boolean NULL,
    value_json jsonb NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_document_attribute_values_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_document_attribute_values_document
        FOREIGN KEY (project_id, document_id)
        REFERENCES documents(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_document_attribute_values_attribute
        FOREIGN KEY (project_id, attribute_definition_id)
        REFERENCES attribute_definitions(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT uq_document_attribute_values
        UNIQUE (project_id, document_id, attribute_definition_id)
);

CREATE TABLE IF NOT EXISTS document_versions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    document_id uuid NOT NULL,
    version_number integer NOT NULL,
    source_type varchar(30) NOT NULL,
    notes text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_document_versions_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_document_versions_document
        FOREIGN KEY (project_id, document_id)
        REFERENCES documents(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT uq_document_versions_project_id
        UNIQUE (project_id, id),
    CONSTRAINT uq_document_versions_project_version
        UNIQUE (project_id, document_id, version_number),
    CONSTRAINT ck_document_versions_source_type
        CHECK (source_type IN ('upload', 'scan', 'generated'))
);

CREATE TABLE IF NOT EXISTS document_files (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    document_version_id uuid NOT NULL,
    file_role varchar(30) NOT NULL,
    storage_path text NOT NULL,
    original_name varchar(255) NOT NULL,
    extension varchar(20) NULL,
    mime_type varchar(120) NULL,
    size_bytes bigint NULL,
    checksum_sha256 varchar(64) NULL,
    page_count integer NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_document_files_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_document_files_document_version
        FOREIGN KEY (project_id, document_version_id)
        REFERENCES document_versions(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT ck_document_files_role
        CHECK (file_role IN ('original', 'preview', 'pdf'))
);

CREATE INDEX IF NOT EXISTS idx_hierarchy_type_rules_parent
    ON hierarchy_type_rules (project_id, parent_node_type_id, sort_order, child_node_type_id);

CREATE INDEX IF NOT EXISTS idx_hierarchy_nodes_project_parent
    ON hierarchy_nodes (project_id, parent_id, sort_order, name);

CREATE INDEX IF NOT EXISTS idx_hierarchy_nodes_project_type
    ON hierarchy_nodes (project_id, node_type_id);

CREATE INDEX IF NOT EXISTS idx_documents_project_node
    ON documents (project_id, node_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_document_versions_project_document
    ON document_versions (project_id, document_id, version_number DESC);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION hierarchy_nodes_before_write()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    parent_project_id uuid;
    parent_type_id uuid;
    parent_depth integer;
    node_type_root_allowed boolean;
    parent_allows_children boolean;
BEGIN
    SELECT is_root_allowed
    INTO node_type_root_allowed
    FROM hierarchy_node_types
    WHERE project_id = NEW.project_id
      AND id = NEW.node_type_id;

    IF NEW.parent_id IS NULL THEN
        IF COALESCE(node_type_root_allowed, false) = false THEN
            RAISE EXCEPTION 'El tipo de nodo % no permite nodos raiz en este proyecto.', NEW.node_type_id;
        END IF;

        NEW.depth := 0;
        RETURN NEW;
    END IF;

    SELECT project_id, node_type_id, depth
    INTO parent_project_id, parent_type_id, parent_depth
    FROM hierarchy_nodes
    WHERE id = NEW.parent_id;

    IF parent_project_id IS NULL THEN
        RAISE EXCEPTION 'El nodo padre % no existe.', NEW.parent_id;
    END IF;

    IF parent_project_id <> NEW.project_id THEN
        RAISE EXCEPTION 'No se puede vincular un nodo con un padre de otro proyecto.';
    END IF;

    SELECT allows_documents
    INTO parent_allows_children
    FROM hierarchy_node_types
    WHERE project_id = NEW.project_id
      AND id = parent_type_id;

    IF NOT EXISTS (
        SELECT 1
        FROM hierarchy_type_rules
        WHERE project_id = NEW.project_id
          AND parent_node_type_id = parent_type_id
          AND child_node_type_id = NEW.node_type_id
    ) THEN
        RAISE EXCEPTION 'La relacion padre-hijo entre los tipos % -> % no esta permitida en este proyecto.', parent_type_id, NEW.node_type_id;
    END IF;

    NEW.depth := parent_depth + 1;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_projects_updated_at ON projects;
CREATE TRIGGER trg_projects_updated_at
BEFORE UPDATE ON projects
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_hierarchy_node_types_updated_at ON hierarchy_node_types;
CREATE TRIGGER trg_hierarchy_node_types_updated_at
BEFORE UPDATE ON hierarchy_node_types
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_attribute_definitions_updated_at ON attribute_definitions;
CREATE TRIGGER trg_attribute_definitions_updated_at
BEFORE UPDATE ON attribute_definitions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_document_types_updated_at ON document_types;
CREATE TRIGGER trg_document_types_updated_at
BEFORE UPDATE ON document_types
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_hierarchy_nodes_updated_at ON hierarchy_nodes;
CREATE TRIGGER trg_hierarchy_nodes_updated_at
BEFORE UPDATE ON hierarchy_nodes
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_hierarchy_nodes_before_write ON hierarchy_nodes;
CREATE TRIGGER trg_hierarchy_nodes_before_write
BEFORE INSERT OR UPDATE OF project_id, node_type_id, parent_id ON hierarchy_nodes
FOR EACH ROW
EXECUTE FUNCTION hierarchy_nodes_before_write();

DROP TRIGGER IF EXISTS trg_node_attribute_values_updated_at ON node_attribute_values;
CREATE TRIGGER trg_node_attribute_values_updated_at
BEFORE UPDATE ON node_attribute_values
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_documents_updated_at ON documents;
CREATE TRIGGER trg_documents_updated_at
BEFORE UPDATE ON documents
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_document_attribute_values_updated_at ON document_attribute_values;
CREATE TRIGGER trg_document_attribute_values_updated_at
BEFORE UPDATE ON document_attribute_values
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

INSERT INTO schema_migrations (version, name, checksum)
VALUES (
    'V202603151410',
    'init_projects_hierarchy_v1',
    'sha256:pending'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
