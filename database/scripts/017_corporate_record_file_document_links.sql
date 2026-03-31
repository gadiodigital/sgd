CREATE TABLE IF NOT EXISTS documents.corporate_record_file_documents (
    corporate_record_file_document_id uuid PRIMARY KEY,
    corporate_record_file_id uuid NOT NULL REFERENCES documents.corporate_record_files (corporate_record_file_id) ON DELETE CASCADE,
    document_id uuid NOT NULL REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    linked_by_user_id uuid NULL REFERENCES identity.users (user_id),
    linked_at_utc timestamptz NOT NULL,
    UNIQUE (corporate_record_file_id, document_id)
);

CREATE INDEX IF NOT EXISTS ix_corporate_record_file_documents_record_file
    ON documents.corporate_record_file_documents (corporate_record_file_id, linked_at_utc DESC);

CREATE INDEX IF NOT EXISTS ix_corporate_record_file_documents_document
    ON documents.corporate_record_file_documents (document_id);

COMMENT ON TABLE documents.corporate_record_file_documents IS 'Vínculos entre legajos corporativos y documentos para gestión contractual y de gobierno interno.';
COMMENT ON COLUMN documents.corporate_record_file_documents.linked_by_user_id IS 'Usuario que generó el vínculo legajo corporativo-documento.';
