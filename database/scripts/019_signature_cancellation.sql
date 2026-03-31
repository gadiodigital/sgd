ALTER TABLE signature.signature_envelopes
    ADD COLUMN IF NOT EXISTS cancelled_by_user_id uuid NULL REFERENCES identity.users (user_id),
    ADD COLUMN IF NOT EXISTS cancelled_at_utc timestamptz NULL,
    ADD COLUMN IF NOT EXISTS cancellation_reason varchar(280) NULL;

ALTER TABLE signature.signature_envelopes
    DROP CONSTRAINT IF EXISTS signature_envelopes_completion_check;

ALTER TABLE signature.signature_envelopes
    DROP CONSTRAINT IF EXISTS signature_envelopes_status_check;

ALTER TABLE signature.signature_envelopes
    DROP CONSTRAINT IF EXISTS signature_signature_envelopes_status_check;

ALTER TABLE signature.signature_envelopes
    ADD CONSTRAINT signature_signature_envelopes_status_check
        CHECK (status IN ('PENDING', 'SIGNED', 'CANCELLED'));

ALTER TABLE signature.signature_envelopes
    ADD CONSTRAINT signature_envelopes_completion_check CHECK (
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
    );

COMMENT ON COLUMN signature.signature_envelopes.cancelled_by_user_id IS 'Usuario que cancelo la solicitud de firma.';
COMMENT ON COLUMN signature.signature_envelopes.cancelled_at_utc IS 'Fecha y hora UTC de cancelacion de la solicitud.';
COMMENT ON COLUMN signature.signature_envelopes.cancellation_reason IS 'Motivo operativo o legal de cancelacion de la solicitud.';
