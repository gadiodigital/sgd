CREATE TABLE IF NOT EXISTS documents.property_files (
    property_file_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    code varchar(40) NOT NULL CHECK (code ~ '^[A-Z0-9_-]+$'),
    title varchar(160) NOT NULL,
    address varchar(200) NOT NULL,
    operation_type varchar(40) NOT NULL CHECK (operation_type IN ('SALE', 'RENT', 'LEASE', 'MIXED')),
    status varchar(24) NOT NULL CHECK (status IN ('ACTIVE', 'CLOSED')),
    created_by_user_id uuid NULL REFERENCES identity.users (user_id),
    created_at_utc timestamptz NOT NULL,
    UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS ix_property_files_tenant_created_at
    ON documents.property_files (tenant_id, created_at_utc DESC);

COMMENT ON TABLE documents.property_files IS 'Legajos inmobiliarios tenant-scoped para inmuebles, operaciones y documentación asociada.';
COMMENT ON COLUMN documents.property_files.address IS 'Dirección principal o referencia operativa del inmueble.';
COMMENT ON COLUMN documents.property_files.operation_type IS 'Tipo de operación inmobiliaria principal del legajo.';
