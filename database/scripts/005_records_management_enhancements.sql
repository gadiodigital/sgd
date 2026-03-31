ALTER TABLE records.legal_holds
    ADD COLUMN IF NOT EXISTS released_by_user_id uuid NULL REFERENCES identity.users (user_id);

ALTER TABLE records.legal_holds
    ADD COLUMN IF NOT EXISTS released_at_utc timestamptz NULL;

ALTER TABLE records.legal_holds
    ADD COLUMN IF NOT EXISTS release_reason varchar(240) NULL;

COMMENT ON TABLE records.legal_holds IS 'Bloqueos legales documentales para preservar evidencia y evitar disposición indebida.';
COMMENT ON COLUMN records.legal_holds.released_by_user_id IS 'Usuario que liberó el legal hold.';
COMMENT ON COLUMN records.legal_holds.released_at_utc IS 'Fecha de liberación del legal hold.';
COMMENT ON COLUMN records.legal_holds.release_reason IS 'Justificación de la liberación del legal hold.';

CREATE INDEX IF NOT EXISTS ix_legal_holds_document_active ON records.legal_holds (document_id, is_active);
