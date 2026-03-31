CREATE TABLE IF NOT EXISTS documents.document_metadata
(
    document_id uuid PRIMARY KEY REFERENCES documents.documents (document_id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
    updated_at_utc timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE documents.document_metadata IS 'Metadatos corrientes del documento validados contra el esquema del tipo documental.';
COMMENT ON COLUMN documents.document_metadata.metadata IS 'Objeto JSON tipado y validado con la taxonomía activa del documento.';
COMMENT ON COLUMN documents.document_metadata.updated_at_utc IS 'Marca temporal de la última actualización del objeto de metadatos.';

CREATE INDEX IF NOT EXISTS ix_document_metadata_tenant_document
    ON documents.document_metadata (tenant_id, document_id);

CREATE INDEX IF NOT EXISTS ix_document_metadata_payload_gin
    ON documents.document_metadata
    USING gin (metadata);
