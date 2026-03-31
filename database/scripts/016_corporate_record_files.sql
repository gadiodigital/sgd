CREATE TABLE IF NOT EXISTS documents.corporate_record_files (
    corporate_record_file_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    code varchar(40) NOT NULL CHECK (code ~ '^[A-Z0-9_-]+$'),
    title varchar(160) NOT NULL,
    category varchar(80) NOT NULL,
    owner_area varchar(80) NOT NULL,
    status varchar(24) NOT NULL CHECK (status IN ('ACTIVE', 'CLOSED')),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL,
    UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS ix_corporate_record_files_tenant_created_at
    ON documents.corporate_record_files (tenant_id, created_at_utc DESC);

COMMENT ON TABLE documents.corporate_record_files IS 'Legajos corporativos tenant-scoped para contratos, societario, RRHH o proveedores.';
COMMENT ON COLUMN documents.corporate_record_files.owner_area IS 'Área responsable o dueña del legajo corporativo.';
