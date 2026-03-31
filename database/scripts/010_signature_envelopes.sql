CREATE SCHEMA IF NOT EXISTS signature;

CREATE TABLE IF NOT EXISTS signature.signature_envelopes (
    signature_envelope_id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES platform.tenants (tenant_id),
    document_id uuid NOT NULL REFERENCES documents.documents (document_id),
    signer_display_name varchar(160) NOT NULL,
    signer_email citext NOT NULL,
    signature_level varchar(32) NOT NULL CHECK (signature_level IN ('ELECTRONIC', 'DIGITAL')),
    provider_code varchar(64) NOT NULL,
    external_reference varchar(160) NULL,
    status varchar(32) NOT NULL CHECK (status IN ('PENDING', 'SIGNED', 'CANCELLED')),
    requested_by_user_id uuid NULL REFERENCES identity.users (user_id),
    requested_at_utc timestamptz NOT NULL,
    due_at_utc timestamptz NULL,
    completed_by_user_id uuid NULL REFERENCES identity.users (user_id),
    completed_at_utc timestamptz NULL,
    cancelled_by_user_id uuid NULL REFERENCES identity.users (user_id),
    cancelled_at_utc timestamptz NULL,
    cancellation_reason varchar(280) NULL,
    CONSTRAINT signature_envelopes_completion_check CHECK (
        (status = 'PENDING'
            AND completed_at_utc IS NULL
            AND cancelled_at_utc IS NULL
            AND cancellation_reason IS NULL)
        OR (status = 'SIGNED'
            AND completed_at_utc IS NOT NULL
            AND cancelled_at_utc IS NULL
            AND cancellation_reason IS NULL)
        OR (status = 'CANCELLED'
            AND completed_at_utc IS NULL
            AND cancelled_at_utc IS NOT NULL
            AND cancellation_reason IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS ix_signature_envelopes_tenant_status_due
    ON signature.signature_envelopes (tenant_id, status, due_at_utc);

CREATE INDEX IF NOT EXISTS ix_signature_envelopes_document
    ON signature.signature_envelopes (document_id);

COMMENT ON SCHEMA signature IS 'Solicitudes y trazabilidad de firma documental.';
COMMENT ON TABLE signature.signature_envelopes IS 'Solicitudes de firma electronica o digital ligadas a documentos.';
COMMENT ON COLUMN signature.signature_envelopes.signature_level IS 'Nivel solicitado: ELECTRONIC o DIGITAL.';
COMMENT ON COLUMN signature.signature_envelopes.provider_code IS 'Proveedor de firma o INTERNAL para flujo local.';
COMMENT ON COLUMN signature.signature_envelopes.external_reference IS 'Referencia externa del proveedor o evidencia de firma.';
COMMENT ON COLUMN signature.signature_envelopes.cancelled_by_user_id IS 'Usuario que cancelo la solicitud de firma.';
COMMENT ON COLUMN signature.signature_envelopes.cancelled_at_utc IS 'Fecha y hora UTC de cancelacion de la solicitud.';
COMMENT ON COLUMN signature.signature_envelopes.cancellation_reason IS 'Motivo operativo o legal de cancelacion de la solicitud.';
