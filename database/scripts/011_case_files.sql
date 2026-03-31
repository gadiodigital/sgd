CREATE TABLE IF NOT EXISTS documents.case_files (
    case_file_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    code varchar(40) NOT NULL CHECK (code ~ '^[A-Z0-9_-]+$'),
    title varchar(160) NOT NULL,
    category varchar(80) NOT NULL,
    status varchar(24) NOT NULL CHECK (status IN ('OPEN', 'CLOSED')),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL,
    UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS ix_case_files_tenant_created_at
    ON documents.case_files (tenant_id, created_at_utc DESC);

COMMENT ON TABLE documents.case_files IS 'Expedientes o casos tenant-scoped para la organización documental.';
COMMENT ON COLUMN documents.case_files.code IS 'Código funcional del expediente.';
