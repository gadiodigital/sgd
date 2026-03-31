ALTER TABLE documents.documents
    DROP CONSTRAINT IF EXISTS documents_status_check;

ALTER TABLE documents.documents
    ADD CONSTRAINT documents_status_check
    CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED', 'DISPOSED'));
