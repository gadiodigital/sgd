CREATE TABLE IF NOT EXISTS documents.property_file_documents (
    property_file_document_id uuid PRIMARY KEY,
    property_file_id uuid NOT NULL REFERENCES documents.property_files (property_file_id) ON DELETE CASCADE,
    document_id uuid NOT NULL REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    linked_by_user_id uuid NULL REFERENCES identity.users (user_id),
    linked_at_utc timestamptz NOT NULL,
    UNIQUE (property_file_id, document_id)
);

CREATE INDEX IF NOT EXISTS ix_property_file_documents_property_file
    ON documents.property_file_documents (property_file_id, linked_at_utc DESC);

CREATE INDEX IF NOT EXISTS ix_property_file_documents_document
    ON documents.property_file_documents (document_id);

COMMENT ON TABLE documents.property_file_documents IS 'Vínculos entre legajos inmobiliarios y documentos para contratos, títulos, tasaciones o AML/KYC.';
COMMENT ON COLUMN documents.property_file_documents.linked_by_user_id IS 'Usuario que generó el vínculo legajo-documento.';
