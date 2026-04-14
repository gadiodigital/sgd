CREATE TABLE IF NOT EXISTS documents.projects
(
    project_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    code varchar(48) NOT NULL CHECK (code ~ '^[A-Z0-9_-]+$'),
    name varchar(160) NOT NULL,
    description varchar(500) NULL,
    status varchar(24) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ARCHIVED')),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (tenant_id, code),
    UNIQUE (tenant_id, project_id)
);

COMMENT ON TABLE documents.projects IS 'Subámbitos documentales configurables dentro de un tenant.';
COMMENT ON COLUMN documents.projects.code IS 'Código funcional del proyecto documental dentro del tenant.';

CREATE TABLE IF NOT EXISTS configuration.container_types
(
    container_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    project_id uuid NOT NULL,
    code varchar(64) NOT NULL CHECK (code ~ '^[A-Z0-9_-]+$'),
    name varchar(120) NOT NULL,
    icon_key varchar(80) NOT NULL DEFAULT 'folder',
    is_root_allowed boolean NOT NULL DEFAULT false,
    accepts_documents boolean NOT NULL DEFAULT false,
    metadata_schema jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata_schema) = 'object'),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (project_id, code),
    UNIQUE (project_id, container_type_id),
    FOREIGN KEY (tenant_id, project_id)
        REFERENCES documents.projects (tenant_id, project_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE configuration.container_types IS 'Tipos de contenedor configurables por proyecto documental.';
COMMENT ON COLUMN configuration.container_types.metadata_schema IS 'Esquema JSON de atributos dinámicos para nodos de este tipo.';

CREATE TABLE IF NOT EXISTS configuration.container_type_rules
(
    container_type_rule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    project_id uuid NOT NULL,
    parent_container_type_id uuid NOT NULL,
    child_container_type_id uuid NOT NULL,
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    CHECK (parent_container_type_id <> child_container_type_id),
    UNIQUE (project_id, parent_container_type_id, child_container_type_id),
    FOREIGN KEY (tenant_id, project_id)
        REFERENCES documents.projects (tenant_id, project_id)
        ON DELETE CASCADE,
    FOREIGN KEY (project_id, parent_container_type_id)
        REFERENCES configuration.container_types (project_id, container_type_id)
        ON DELETE CASCADE,
    FOREIGN KEY (project_id, child_container_type_id)
        REFERENCES configuration.container_types (project_id, container_type_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE configuration.container_type_rules IS 'Reglas padre-hijo permitidas entre tipos de contenedor.';

CREATE TABLE IF NOT EXISTS documents.containers
(
    container_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    project_id uuid NOT NULL,
    container_type_id uuid NOT NULL,
    parent_container_id uuid NULL,
    code varchar(80) NOT NULL CHECK (code ~ '^[A-Z0-9_-]+$'),
    name varchar(180) NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (project_id, code),
    UNIQUE (project_id, container_id),
    FOREIGN KEY (tenant_id, project_id)
        REFERENCES documents.projects (tenant_id, project_id)
        ON DELETE CASCADE,
    FOREIGN KEY (project_id, container_type_id)
        REFERENCES configuration.container_types (project_id, container_type_id),
    FOREIGN KEY (project_id, parent_container_id)
        REFERENCES documents.containers (project_id, container_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE documents.containers IS 'Nodos reales del árbol documental configurable por proyecto.';
COMMENT ON COLUMN documents.containers.metadata IS 'Valores dinámicos del nodo validados por el backend contra el tipo de contenedor.';

CREATE TABLE IF NOT EXISTS documents.container_documents
(
    container_document_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    project_id uuid NOT NULL,
    container_id uuid NOT NULL,
    document_id uuid NOT NULL REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    linked_by_user_id uuid NULL REFERENCES identity.users (user_id),
    linked_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (container_id, document_id),
    FOREIGN KEY (tenant_id, project_id)
        REFERENCES documents.projects (tenant_id, project_id)
        ON DELETE CASCADE,
    FOREIGN KEY (project_id, container_id)
        REFERENCES documents.containers (project_id, container_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE documents.container_documents IS 'Vínculos entre nodos jerárquicos configurables y documentos.';

CREATE INDEX IF NOT EXISTS ix_projects_tenant_status
    ON documents.projects (tenant_id, status, created_at_utc DESC);

CREATE INDEX IF NOT EXISTS ix_container_types_project
    ON configuration.container_types (project_id, code);

CREATE INDEX IF NOT EXISTS ix_container_type_rules_project_parent
    ON configuration.container_type_rules (project_id, parent_container_type_id);

CREATE INDEX IF NOT EXISTS ix_containers_project_parent
    ON documents.containers (project_id, parent_container_id, code);

CREATE INDEX IF NOT EXISTS ix_container_documents_container
    ON documents.container_documents (container_id, linked_at_utc DESC);

CREATE INDEX IF NOT EXISTS ix_container_documents_document
    ON documents.container_documents (document_id);

CREATE OR REPLACE FUNCTION documents.validate_container_hierarchy()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    type_allows_root boolean;
    parent_type_id uuid;
BEGIN
    SELECT ct.is_root_allowed
    INTO type_allows_root
    FROM configuration.container_types ct
    WHERE ct.project_id = NEW.project_id
      AND ct.container_type_id = NEW.container_type_id;

    IF type_allows_root IS NULL THEN
        RAISE EXCEPTION 'El tipo de contenedor no pertenece al proyecto informado.';
    END IF;

    IF NEW.parent_container_id IS NULL THEN
        IF type_allows_root IS NOT TRUE THEN
            RAISE EXCEPTION 'El tipo de contenedor no puede crearse como raíz.';
        END IF;
        RETURN NEW;
    END IF;

    SELECT parent.container_type_id
    INTO parent_type_id
    FROM documents.containers parent
    WHERE parent.project_id = NEW.project_id
      AND parent.container_id = NEW.parent_container_id;

    IF parent_type_id IS NULL THEN
        RAISE EXCEPTION 'El contenedor padre no pertenece al proyecto informado.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM configuration.container_type_rules rule
        WHERE rule.project_id = NEW.project_id
          AND rule.parent_container_type_id = parent_type_id
          AND rule.child_container_type_id = NEW.container_type_id
    ) THEN
        RAISE EXCEPTION 'La relación padre-hijo no está permitida por las reglas del proyecto.';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_container_hierarchy ON documents.containers;
CREATE TRIGGER trg_validate_container_hierarchy
BEFORE INSERT OR UPDATE OF project_id, container_type_id, parent_container_id
ON documents.containers
FOR EACH ROW
EXECUTE FUNCTION documents.validate_container_hierarchy();

CREATE OR REPLACE FUNCTION documents.validate_container_document_link()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    accepts_docs boolean;
    document_tenant_id uuid;
BEGIN
    SELECT ct.accepts_documents
    INTO accepts_docs
    FROM documents.containers c
    INNER JOIN configuration.container_types ct
        ON ct.project_id = c.project_id
       AND ct.container_type_id = c.container_type_id
    WHERE c.project_id = NEW.project_id
      AND c.container_id = NEW.container_id;

    IF accepts_docs IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'El contenedor no acepta documentos.';
    END IF;

    SELECT d.tenant_id
    INTO document_tenant_id
    FROM documents.documents d
    WHERE d.document_id = NEW.document_id;

    IF document_tenant_id IS NULL OR document_tenant_id <> NEW.tenant_id THEN
        RAISE EXCEPTION 'El documento no pertenece al tenant informado.';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_container_document_link ON documents.container_documents;
CREATE TRIGGER trg_validate_container_document_link
BEFORE INSERT OR UPDATE OF tenant_id, project_id, container_id, document_id
ON documents.container_documents
FOR EACH ROW
EXECUTE FUNCTION documents.validate_container_document_link();
