ALTER TABLE identity.users
    ADD COLUMN IF NOT EXISTS password_hash varchar(512) NULL;

ALTER TABLE identity.users
    ADD COLUMN IF NOT EXISTS must_change_password boolean NOT NULL DEFAULT true;

ALTER TABLE identity.users
    ADD COLUMN IF NOT EXISTS failed_login_count smallint NOT NULL DEFAULT 0;

ALTER TABLE identity.users
    ADD COLUMN IF NOT EXISTS locked_until_utc timestamptz NULL;

ALTER TABLE identity.users
    ADD COLUMN IF NOT EXISTS last_login_at_utc timestamptz NULL;

ALTER TABLE identity.users
    DROP CONSTRAINT IF EXISTS users_failed_login_count_check;

ALTER TABLE identity.users
    ADD CONSTRAINT users_failed_login_count_check
    CHECK (failed_login_count BETWEEN 0 AND 20);

COMMENT ON COLUMN identity.users.password_hash IS 'Hash local de contraseña cuando el tenant utiliza autenticación administrada por la plataforma.';
COMMENT ON COLUMN identity.users.must_change_password IS 'Obliga al usuario a rotar la contraseña luego del primer acceso o de un alta administrativa.';
COMMENT ON COLUMN identity.users.failed_login_count IS 'Contador defensivo de intentos fallidos para lockout progresivo.';
COMMENT ON COLUMN identity.users.locked_until_utc IS 'Fecha hasta la cual el usuario queda bloqueado por intentos fallidos.';
COMMENT ON COLUMN identity.users.last_login_at_utc IS 'Marca temporal del último acceso exitoso.';
