CREATE TABLE IF NOT EXISTS platform.tenants
(
    tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code varchar(32) NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9_-]+$'),
    name varchar(160) NOT NULL,
    sector varchar(80) NOT NULL,
    primary_country_code char(2) NOT NULL CHECK (primary_country_code ~ '^[A-Z]{2}$'),
    is_active boolean NOT NULL DEFAULT true,
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE platform.tenants IS 'Tenant o espacio lógico aislado dentro de la plataforma.';

CREATE TABLE IF NOT EXISTS identity.users
(
    user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    email citext NOT NULL,
    full_name varchar(160) NOT NULL,
    status varchar(24) NOT NULL CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'DISABLED')),
    password_hash varchar(512) NULL,
    must_change_password boolean NOT NULL DEFAULT true,
    failed_login_count smallint NOT NULL DEFAULT 0 CHECK (failed_login_count BETWEEN 0 AND 20),
    locked_until_utc timestamptz NULL,
    last_login_at_utc timestamptz NULL,
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (tenant_id, email)
);

COMMENT ON TABLE identity.users IS 'Usuarios internos o externos pertenecientes a un tenant.';
COMMENT ON COLUMN identity.users.password_hash IS 'Hash local de contraseña cuando el tenant utiliza autenticación administrada por la plataforma.';
COMMENT ON COLUMN identity.users.must_change_password IS 'Obliga al usuario a rotar la contraseña luego del primer acceso o de un alta administrativa.';
COMMENT ON COLUMN identity.users.failed_login_count IS 'Contador defensivo de intentos fallidos para lockout progresivo.';
COMMENT ON COLUMN identity.users.locked_until_utc IS 'Fecha hasta la cual el usuario queda bloqueado por intentos fallidos.';
COMMENT ON COLUMN identity.users.last_login_at_utc IS 'Marca temporal del último acceso exitoso.';

CREATE TABLE IF NOT EXISTS identity.roles
(
    role_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code varchar(32) NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9_]+$'),
    name varchar(100) NOT NULL,
    description varchar(240) NOT NULL
);

CREATE TABLE IF NOT EXISTS identity.user_roles
(
    user_role_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES identity.users (user_id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES identity.roles (role_id),
    assigned_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS configuration.document_types
(
    document_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NULL REFERENCES platform.tenants (tenant_id),
    code varchar(64) NOT NULL CHECK (code ~ '^[A-Z0-9_]+$'),
    name varchar(120) NOT NULL,
    sector varchar(80) NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    metadata_schema jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata_schema) = 'object'),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (tenant_id, code)
);

COMMENT ON TABLE configuration.document_types IS 'Tipos documentales relacionales con esquema JSON validable.';

CREATE TABLE IF NOT EXISTS records.retention_policies
(
    retention_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NULL REFERENCES platform.tenants (tenant_id),
    code varchar(48) NOT NULL CHECK (code ~ '^[A-Z0-9_]+$'),
    name varchar(120) NOT NULL,
    retention_days integer NOT NULL CHECK (retention_days > 0),
    disposition_action varchar(24) NOT NULL CHECK (disposition_action IN ('REVIEW', 'DELETE', 'ARCHIVE')),
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

CREATE TABLE IF NOT EXISTS documents.documents
(
    document_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    document_type_id uuid NOT NULL REFERENCES configuration.document_types (document_type_id),
    retention_policy_id uuid NULL REFERENCES records.retention_policies (retention_policy_id),
    title varchar(200) NOT NULL,
    status varchar(24) NOT NULL CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED', 'DISPOSED')),
    confidentiality_level smallint NOT NULL DEFAULT 1 CHECK (confidentiality_level BETWEEN 1 AND 5),
    current_version_number integer NOT NULL DEFAULT 0 CHECK (current_version_number >= 0),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE documents.documents IS 'Agregado documental principal.';

CREATE TABLE IF NOT EXISTS documents.document_versions
(
    document_version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid NOT NULL REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    version_number integer NOT NULL CHECK (version_number > 0),
    storage_object_key varchar(260) NOT NULL,
    mime_type varchar(120) NOT NULL,
    file_hash_sha256 char(64) NOT NULL CHECK (file_hash_sha256 ~ '^[0-9a-f]{64}$'),
    file_size_bytes bigint NOT NULL CHECK (file_size_bytes > 0),
    uploaded_by_user_id uuid NULL REFERENCES identity.users (user_id),
    uploaded_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (document_id, version_number)
);

COMMENT ON TABLE documents.document_versions IS 'Versiones inmutables del documento.';

CREATE TABLE IF NOT EXISTS records.legal_holds
(
    legal_hold_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    document_id uuid NULL REFERENCES documents.documents (document_id),
    reason varchar(240) NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now()),
    released_by_user_id uuid NULL REFERENCES identity.users (user_id),
    released_at_utc timestamptz NULL,
    release_reason varchar(240) NULL
);

COMMENT ON TABLE records.legal_holds IS 'Bloqueos legales documentales para preservar evidencia y evitar disposición indebida.';
COMMENT ON COLUMN records.legal_holds.released_by_user_id IS 'Usuario que liberó el legal hold.';
COMMENT ON COLUMN records.legal_holds.released_at_utc IS 'Fecha de liberación del legal hold.';
COMMENT ON COLUMN records.legal_holds.release_reason IS 'Justificación de la liberación del legal hold.';

CREATE TABLE IF NOT EXISTS audit.audit_events
(
    audit_event_id bigserial PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    actor_user_id uuid NULL REFERENCES identity.users (user_id),
    document_id uuid NULL REFERENCES documents.documents (document_id),
    event_type varchar(80) NOT NULL,
    severity varchar(16) NOT NULL DEFAULT 'INFO' CHECK (severity IN ('INFO', 'WARNING', 'ERROR', 'CRITICAL')),
    payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(payload) = 'object'),
    occurred_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE audit.audit_events IS 'Bitácora auditable de acciones operativas y de cumplimiento.';

CREATE INDEX IF NOT EXISTS ix_users_tenant_status ON identity.users (tenant_id, status);
CREATE INDEX IF NOT EXISTS ix_documents_tenant_status ON documents.documents (tenant_id, status);
CREATE INDEX IF NOT EXISTS ix_document_versions_document_id ON documents.document_versions (document_id);
CREATE INDEX IF NOT EXISTS ix_legal_holds_document_active ON records.legal_holds (document_id, is_active);
CREATE INDEX IF NOT EXISTS ix_audit_events_tenant_occurred_at ON audit.audit_events (tenant_id, occurred_at_utc DESC);
