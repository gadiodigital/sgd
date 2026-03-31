CREATE TABLE IF NOT EXISTS documents.case_file_documents (
    case_file_document_id uuid PRIMARY KEY,
    case_file_id uuid NOT NULL REFERENCES documents.case_files (case_file_id) ON DELETE CASCADE,
    document_id uuid NOT NULL REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    linked_by_user_id uuid NULL REFERENCES identity.users (user_id),
    linked_at_utc timestamptz NOT NULL,
    UNIQUE (case_file_id, document_id)
);

CREATE INDEX IF NOT EXISTS ix_case_file_documents_case_file
    ON documents.case_file_documents (case_file_id, linked_at_utc DESC);

CREATE INDEX IF NOT EXISTS ix_case_file_documents_document
    ON documents.case_file_documents (document_id);

COMMENT ON TABLE documents.case_file_documents IS 'Vínculos entre expedientes y documentos para organizar evidencia, contratos o actuaciones.';
COMMENT ON COLUMN documents.case_file_documents.linked_by_user_id IS 'Usuario que generó el vínculo expediente-documento.';
