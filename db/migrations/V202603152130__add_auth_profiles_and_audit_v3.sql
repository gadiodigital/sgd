BEGIN;

CREATE TABLE IF NOT EXISTS auth_providers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code varchar(80) NOT NULL UNIQUE,
    name varchar(160) NOT NULL,
    provider_type varchar(20) NOT NULL,
    settings_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_enabled boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_auth_providers_type
        CHECK (provider_type IN ('local', 'ldap', 'oidc', 'saml'))
);

CREATE TABLE IF NOT EXISTS app_users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email varchar(160) NULL,
    display_name varchar(160) NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    is_platform_admin boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth_identities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    provider_id uuid NOT NULL,
    subject varchar(200) NOT NULL,
    login_name varchar(120) NULL,
    password_hash text NULL,
    metadata_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_active boolean NOT NULL DEFAULT true,
    last_login_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_auth_identities_user
        FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE,
    CONSTRAINT fk_auth_identities_provider
        FOREIGN KEY (provider_id) REFERENCES auth_providers(id) ON DELETE RESTRICT,
    CONSTRAINT uq_auth_identities_provider_subject
        UNIQUE (provider_id, subject)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_auth_identities_provider_login
    ON auth_identities (provider_id, lower(login_name))
    WHERE login_name IS NOT NULL;

CREATE TABLE IF NOT EXISTS permission_catalog (
    code varchar(80) PRIMARY KEY,
    name varchar(160) NOT NULL,
    description text NOT NULL,
    access_kind varchar(10) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_permission_catalog_access_kind
        CHECK (access_kind IN ('read', 'write'))
);

CREATE TABLE IF NOT EXISTS project_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    code varchar(80) NOT NULL,
    name varchar(160) NOT NULL,
    description text NULL,
    is_system boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_project_profiles_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT uq_project_profiles_project_code
        UNIQUE (project_id, code),
    CONSTRAINT uq_project_profiles_project_id
        UNIQUE (project_id, id)
);

CREATE TABLE IF NOT EXISTS project_profile_permissions (
    project_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    permission_code varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, profile_id, permission_code),
    CONSTRAINT fk_project_profile_permissions_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_profile_permissions_profile
        FOREIGN KEY (project_id, profile_id)
        REFERENCES project_profiles(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_project_profile_permissions_permission
        FOREIGN KEY (permission_code) REFERENCES permission_catalog(code) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS project_memberships (
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, user_id),
    CONSTRAINT fk_project_memberships_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_memberships_user
        FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_memberships_profile
        FOREIGN KEY (project_id, profile_id)
        REFERENCES project_profiles(project_id, id)
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS auth_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    identity_id uuid NOT NULL,
    provider_id uuid NOT NULL,
    session_token varchar(128) NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz NULL,
    last_seen_at timestamptz NULL,
    ip_address inet NULL,
    user_agent text NULL,
    CONSTRAINT fk_auth_sessions_user
        FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE,
    CONSTRAINT fk_auth_sessions_identity
        FOREIGN KEY (identity_id) REFERENCES auth_identities(id) ON DELETE CASCADE,
    CONSTRAINT fk_auth_sessions_provider
        FOREIGN KEY (provider_id) REFERENCES auth_providers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS audit_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NULL,
    session_id uuid NULL,
    project_id uuid NULL,
    action_code varchar(120) NOT NULL,
    access_kind varchar(10) NOT NULL,
    resource_type varchar(80) NOT NULL,
    resource_id varchar(200) NULL,
    outcome varchar(20) NOT NULL,
    message text NULL,
    details_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    ip_address inet NULL,
    user_agent text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_audit_events_user
        FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_events_session
        FOREIGN KEY (session_id) REFERENCES auth_sessions(id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_events_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
    CONSTRAINT ck_audit_events_access_kind
        CHECK (access_kind IN ('read', 'write')),
    CONSTRAINT ck_audit_events_outcome
        CHECK (outcome IN ('success', 'denied', 'error'))
);

CREATE INDEX IF NOT EXISTS idx_project_memberships_user
    ON project_memberships (user_id, is_active, project_id);

CREATE INDEX IF NOT EXISTS idx_project_memberships_project
    ON project_memberships (project_id, is_active, user_id);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_user
    ON auth_sessions (user_id, revoked_at, expires_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_events_project_created_at
    ON audit_events (project_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_events_user_created_at
    ON audit_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_events_action_created_at
    ON audit_events (action_code, created_at DESC);

DROP TRIGGER IF EXISTS trg_auth_providers_updated_at ON auth_providers;
CREATE TRIGGER trg_auth_providers_updated_at
BEFORE UPDATE ON auth_providers
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_app_users_updated_at ON app_users;
CREATE TRIGGER trg_app_users_updated_at
BEFORE UPDATE ON app_users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_auth_identities_updated_at ON auth_identities;
CREATE TRIGGER trg_auth_identities_updated_at
BEFORE UPDATE ON auth_identities
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_project_profiles_updated_at ON project_profiles;
CREATE TRIGGER trg_project_profiles_updated_at
BEFORE UPDATE ON project_profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_project_memberships_updated_at ON project_memberships;
CREATE TRIGGER trg_project_memberships_updated_at
BEFORE UPDATE ON project_memberships
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

INSERT INTO auth_providers (code, name, provider_type)
VALUES ('local', 'Credenciales locales', 'local')
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    provider_type = EXCLUDED.provider_type,
    is_enabled = true;

INSERT INTO permission_catalog (code, name, description, access_kind)
VALUES
    ('project.read', 'Leer proyecto', 'Permite ver proyectos y seleccionar el contexto actual.', 'read'),
    ('project.write', 'Modificar proyecto', 'Permite crear, editar y eliminar la configuración base del proyecto.', 'write'),
    ('types.read', 'Leer tipos', 'Permite ver tipos de contenedor, atributos y reglas del proyecto.', 'read'),
    ('types.write', 'Modificar tipos', 'Permite crear, editar y eliminar tipos, atributos y reglas del proyecto.', 'write'),
    ('hierarchy.read', 'Leer jerarquía', 'Permite consultar la jerarquía real del proyecto.', 'read'),
    ('hierarchy.write', 'Modificar jerarquía', 'Permite crear, editar y eliminar nodos reales en la jerarquía.', 'write'),
    ('security.read', 'Leer seguridad', 'Permite consultar perfiles, permisos y membresías del proyecto.', 'read'),
    ('security.write', 'Modificar seguridad', 'Permite crear perfiles y administrar accesos del proyecto.', 'write')
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    access_kind = EXCLUDED.access_kind;

WITH local_provider AS (
    SELECT id
    FROM auth_providers
    WHERE code = 'local'
),
existing_admin AS (
    SELECT ai.user_id
    FROM auth_identities ai
    JOIN local_provider lp
      ON lp.id = ai.provider_id
    WHERE ai.subject = 'admin'
),
created_admin AS (
    INSERT INTO app_users (display_name, email, is_platform_admin)
    SELECT 'Administrador local', 'admin@local.test', true
    WHERE NOT EXISTS (SELECT 1 FROM existing_admin)
    RETURNING id
),
target_admin AS (
    SELECT id AS user_id
    FROM created_admin
    UNION ALL
    SELECT user_id
    FROM existing_admin
)
UPDATE app_users
SET
    display_name = 'Administrador local',
    is_platform_admin = true,
    is_active = true
WHERE id IN (SELECT user_id FROM target_admin);

WITH local_provider AS (
    SELECT id
    FROM auth_providers
    WHERE code = 'local'
),
existing_admin AS (
    SELECT ai.id, ai.user_id
    FROM auth_identities ai
    JOIN local_provider lp
      ON lp.id = ai.provider_id
    WHERE ai.subject = 'admin'
),
created_admin AS (
    SELECT id AS user_id
    FROM app_users
    WHERE is_platform_admin = true
      AND display_name = 'Administrador local'
    ORDER BY created_at
    LIMIT 1
)
INSERT INTO auth_identities (
    user_id,
    provider_id,
    subject,
    login_name,
    password_hash,
    metadata_json,
    is_active
)
SELECT
    created_admin.user_id,
    local_provider.id,
    'admin',
    'admin',
    crypt('admin', gen_salt('bf', 12)),
    '{"seeded": true}'::jsonb,
    true
FROM local_provider, created_admin
WHERE NOT EXISTS (SELECT 1 FROM existing_admin);

WITH local_provider AS (
    SELECT id
    FROM auth_providers
    WHERE code = 'local'
)
UPDATE auth_identities ai
SET
    login_name = 'admin',
    password_hash = crypt('admin', gen_salt('bf', 12)),
    is_active = true
FROM local_provider lp
WHERE ai.provider_id = lp.id
  AND ai.subject = 'admin';

CREATE OR REPLACE FUNCTION ensure_default_project_security(
    p_project_id uuid,
    p_admin_user_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    admin_profile_id uuid;
    editor_profile_id uuid;
    viewer_profile_id uuid;
BEGIN
    INSERT INTO project_profiles (project_id, code, name, description, is_system, is_active)
    VALUES (
        p_project_id,
        'admin',
        'Administrador del proyecto',
        'Acceso completo a configuración, jerarquía y seguridad del proyecto.',
        true,
        true
    )
    ON CONFLICT (project_id, code) DO UPDATE
    SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        is_system = true,
        is_active = true
    RETURNING id INTO admin_profile_id;

    INSERT INTO project_profiles (project_id, code, name, description, is_system, is_active)
    VALUES (
        p_project_id,
        'editor',
        'Editor del proyecto',
        'Puede modificar tipos y jerarquía del proyecto, pero no administrar seguridad.',
        true,
        true
    )
    ON CONFLICT (project_id, code) DO UPDATE
    SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        is_system = true,
        is_active = true
    RETURNING id INTO editor_profile_id;

    INSERT INTO project_profiles (project_id, code, name, description, is_system, is_active)
    VALUES (
        p_project_id,
        'viewer',
        'Consulta del proyecto',
        'Puede ver configuración y jerarquía sin realizar cambios.',
        true,
        true
    )
    ON CONFLICT (project_id, code) DO UPDATE
    SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        is_system = true,
        is_active = true
    RETURNING id INTO viewer_profile_id;

    INSERT INTO project_profile_permissions (project_id, profile_id, permission_code)
    VALUES
        (p_project_id, admin_profile_id, 'project.read'),
        (p_project_id, admin_profile_id, 'project.write'),
        (p_project_id, admin_profile_id, 'types.read'),
        (p_project_id, admin_profile_id, 'types.write'),
        (p_project_id, admin_profile_id, 'hierarchy.read'),
        (p_project_id, admin_profile_id, 'hierarchy.write'),
        (p_project_id, admin_profile_id, 'security.read'),
        (p_project_id, admin_profile_id, 'security.write'),
        (p_project_id, editor_profile_id, 'project.read'),
        (p_project_id, editor_profile_id, 'types.read'),
        (p_project_id, editor_profile_id, 'types.write'),
        (p_project_id, editor_profile_id, 'hierarchy.read'),
        (p_project_id, editor_profile_id, 'hierarchy.write'),
        (p_project_id, viewer_profile_id, 'project.read'),
        (p_project_id, viewer_profile_id, 'types.read'),
        (p_project_id, viewer_profile_id, 'hierarchy.read')
    ON CONFLICT (project_id, profile_id, permission_code) DO NOTHING;

    IF p_admin_user_id IS NOT NULL THEN
        INSERT INTO project_memberships (project_id, user_id, profile_id, is_active)
        VALUES (p_project_id, p_admin_user_id, admin_profile_id, true)
        ON CONFLICT (project_id, user_id) DO UPDATE
        SET
            profile_id = EXCLUDED.profile_id,
            is_active = true;
    END IF;
END;
$$;

WITH admin_user AS (
    SELECT ai.user_id
    FROM auth_identities ai
    JOIN auth_providers ap
      ON ap.id = ai.provider_id
    WHERE ap.code = 'local'
      AND ai.subject = 'admin'
)
SELECT ensure_default_project_security(p.id, admin_user.user_id)
FROM projects p
CROSS JOIN admin_user;

INSERT INTO schema_migrations (version, name, checksum)
VALUES (
    'V202603152130',
    'add_auth_profiles_and_audit_v3',
    'sha256:pending'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
