CREATE TABLE IF NOT EXISTS documents.document_access_entries (
    document_access_entry_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    document_id uuid NOT NULL REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES identity.users (user_id) ON DELETE CASCADE,
    permission_code varchar(32) NOT NULL CHECK (permission_code IN ('READ', 'DOWNLOAD', 'EDITMETADATA', 'UPLOADVERSION')),
    granted_by_user_id uuid NULL REFERENCES identity.users (user_id),
    granted_at_utc timestamptz NOT NULL,
    UNIQUE (document_id, user_id, permission_code)
);

CREATE INDEX IF NOT EXISTS ix_document_access_entries_document
    ON documents.document_access_entries (document_id, user_id);

COMMENT ON TABLE documents.document_access_entries IS 'ACL explícita por documento y usuario para permisos finos complementarios al RBAC.';
