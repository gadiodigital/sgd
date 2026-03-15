--
-- PostgreSQL database dump
--

\restrict SftWkUb67xIrigOyJcimirhkZfklCHSzfoaEIOvMxaUZjhHYHCGbWlQUF5vLAvA

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: ensure_default_project_security(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_default_project_security(p_project_id uuid, p_admin_user_id uuid DEFAULT NULL::uuid) RETURNS void
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


--
-- Name: hierarchy_nodes_before_write(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hierarchy_nodes_before_write() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent_project_id uuid;
    parent_type_id uuid;
    parent_depth integer;
    node_type_root_allowed boolean;
    parent_allows_children boolean;
BEGIN
    SELECT is_root_allowed
    INTO node_type_root_allowed
    FROM hierarchy_node_types
    WHERE project_id = NEW.project_id
      AND id = NEW.node_type_id;

    IF NEW.parent_id IS NULL THEN
        IF COALESCE(node_type_root_allowed, false) = false THEN
            RAISE EXCEPTION 'El tipo de nodo % no permite nodos raiz en este proyecto.', NEW.node_type_id;
        END IF;

        NEW.depth := 0;
        RETURN NEW;
    END IF;

    SELECT project_id, node_type_id, depth
    INTO parent_project_id, parent_type_id, parent_depth
    FROM hierarchy_nodes
    WHERE id = NEW.parent_id;

    IF parent_project_id IS NULL THEN
        RAISE EXCEPTION 'El nodo padre % no existe.', NEW.parent_id;
    END IF;

    IF parent_project_id <> NEW.project_id THEN
        RAISE EXCEPTION 'No se puede vincular un nodo con un padre de otro proyecto.';
    END IF;

    SELECT allows_documents
    INTO parent_allows_children
    FROM hierarchy_node_types
    WHERE project_id = NEW.project_id
      AND id = parent_type_id;

    IF NOT EXISTS (
        SELECT 1
        FROM hierarchy_type_rules
        WHERE project_id = NEW.project_id
          AND parent_node_type_id = parent_type_id
          AND child_node_type_id = NEW.node_type_id
    ) THEN
        RAISE EXCEPTION 'La relacion padre-hijo entre los tipos % -> % no esta permitida en este proyecto.', parent_type_id, NEW.node_type_id;
    END IF;

    NEW.depth := parent_depth + 1;
    RETURN NEW;
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


--
-- Name: validate_attribute_definition(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_attribute_definition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.type_extension IS NOT NULL AND NEW.type_extension <= 0 THEN
        RAISE EXCEPTION 'type_extension debe ser mayor a cero.';
    END IF;

    IF NEW.validation_regex IS NOT NULL THEN
        BEGIN
            PERFORM '' ~ NEW.validation_regex;
        EXCEPTION
            WHEN invalid_regular_expression THEN
                RAISE EXCEPTION 'La expresion regular configurada para el atributo % no es valida.', NEW.code;
        END;
    END IF;

    IF NEW.data_type = 'list'
       AND NEW.validation_regex IS NOT NULL THEN
        RAISE EXCEPTION 'Los atributos de tipo list no deben usar validation_regex.';
    END IF;

    IF NEW.data_type <> 'string'
       AND NEW.type_extension IS NOT NULL
       AND COALESCE(NEW.settings_json ->> 'extension_semantics', '') = '' THEN
        NEW.settings_json := jsonb_set(
            NEW.settings_json,
            '{extension_semantics}',
            to_jsonb('custom'),
            true
        );
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: validate_attribute_option(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_attribute_option() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_data_type varchar(30);
BEGIN
    SELECT data_type
    INTO current_data_type
    FROM attribute_definitions
    WHERE project_id = NEW.project_id
      AND id = NEW.attribute_definition_id;

    IF current_data_type IS DISTINCT FROM 'list' THEN
        RAISE EXCEPTION 'Solo los atributos de tipo list pueden tener opciones.';
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: validate_document_attribute_value(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_document_attribute_value() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_scope varchar(30);
    current_data_type varchar(30);
    current_type_extension integer;
    current_validation_regex text;
    current_document_type_id uuid;
BEGIN
    SELECT scope, data_type, type_extension, validation_regex
    INTO current_scope, current_data_type, current_type_extension, current_validation_regex
    FROM attribute_definitions
    WHERE project_id = NEW.project_id
      AND id = NEW.attribute_definition_id;

    IF current_scope IS DISTINCT FROM 'document' THEN
        RAISE EXCEPTION 'El atributo % no pertenece al scope document.', NEW.attribute_definition_id;
    END IF;

    SELECT document_type_id
    INTO current_document_type_id
    FROM documents
    WHERE project_id = NEW.project_id
      AND id = NEW.document_id;

    IF current_document_type_id IS NULL THEN
        RAISE EXCEPTION 'El documento % debe tener document_type_id antes de cargar atributos.', NEW.document_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM document_type_attributes
        WHERE project_id = NEW.project_id
          AND document_type_id = current_document_type_id
          AND attribute_definition_id = NEW.attribute_definition_id
    ) THEN
        RAISE EXCEPTION 'El atributo % no esta asignado al tipo del documento %.', NEW.attribute_definition_id, current_document_type_id;
    END IF;

    PERFORM validate_dynamic_attribute_value(
        NEW.project_id,
        NEW.attribute_definition_id,
        current_data_type,
        current_type_extension,
        current_validation_regex,
        NEW.value_text,
        NEW.value_number,
        NEW.value_date,
        NEW.value_boolean,
        NEW.value_json
    );

    RETURN NEW;
END;
$$;


--
-- Name: validate_document_type_attribute(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_document_type_attribute() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_scope varchar(30);
BEGIN
    SELECT scope
    INTO current_scope
    FROM attribute_definitions
    WHERE project_id = NEW.project_id
      AND id = NEW.attribute_definition_id;

    IF current_scope IS DISTINCT FROM 'document' THEN
        RAISE EXCEPTION 'El atributo % no pertenece al scope document.', NEW.attribute_definition_id;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: validate_dynamic_attribute_value(uuid, uuid, character varying, integer, text, text, numeric, date, boolean, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_dynamic_attribute_value(p_project_id uuid, p_attribute_definition_id uuid, p_data_type character varying, p_type_extension integer, p_validation_regex text, p_value_text text, p_value_number numeric, p_value_date date, p_value_boolean boolean, p_value_json jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    filled_values integer;
BEGIN
    filled_values := num_nonnulls(
        p_value_text,
        p_value_number,
        p_value_date,
        p_value_boolean,
        p_value_json
    );

    IF filled_values = 0 THEN
        RAISE EXCEPTION 'El valor dinamico no puede quedar completamente vacio.';
    END IF;

    CASE p_data_type
        WHEN 'string' THEN
            IF filled_values <> 1 OR p_value_text IS NULL THEN
                RAISE EXCEPTION 'Los atributos string deben usar solamente value_text.';
            END IF;

            IF p_type_extension IS NOT NULL
               AND char_length(p_value_text) > p_type_extension THEN
                RAISE EXCEPTION 'El valor supera la longitud maxima configurada (%).', p_type_extension;
            END IF;

            IF p_validation_regex IS NOT NULL
               AND p_value_text !~ p_validation_regex THEN
                RAISE EXCEPTION 'El valor no cumple la validacion regex del atributo.';
            END IF;

        WHEN 'integer' THEN
            IF filled_values <> 1 OR p_value_number IS NULL THEN
                RAISE EXCEPTION 'Los atributos integer deben usar solamente value_number.';
            END IF;

            IF trunc(p_value_number) <> p_value_number THEN
                RAISE EXCEPTION 'El valor % no es un entero valido.', p_value_number;
            END IF;

        WHEN 'decimal' THEN
            IF filled_values <> 1 OR p_value_number IS NULL THEN
                RAISE EXCEPTION 'Los atributos decimal deben usar solamente value_number.';
            END IF;

        WHEN 'date' THEN
            IF filled_values <> 1 OR p_value_date IS NULL THEN
                RAISE EXCEPTION 'Los atributos date deben usar solamente value_date.';
            END IF;

        WHEN 'boolean' THEN
            IF filled_values <> 1 OR p_value_boolean IS NULL THEN
                RAISE EXCEPTION 'Los atributos boolean deben usar solamente value_boolean.';
            END IF;

        WHEN 'json' THEN
            IF filled_values <> 1 OR p_value_json IS NULL THEN
                RAISE EXCEPTION 'Los atributos json deben usar solamente value_json.';
            END IF;

        WHEN 'list' THEN
            IF filled_values <> 1 OR p_value_text IS NULL THEN
                RAISE EXCEPTION 'Los atributos list deben usar solamente value_text con el codigo de la opcion.';
            END IF;

            IF NOT EXISTS (
                SELECT 1
                FROM attribute_options
                WHERE project_id = p_project_id
                  AND attribute_definition_id = p_attribute_definition_id
                  AND code = p_value_text
                  AND is_active = true
            ) THEN
                RAISE EXCEPTION 'La opcion % no existe para el atributo %.', p_value_text, p_attribute_definition_id;
            END IF;

        ELSE
            RAISE EXCEPTION 'Tipo de dato dinamico no soportado: %.', p_data_type;
    END CASE;
END;
$$;


--
-- Name: validate_node_attribute_value(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_node_attribute_value() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_scope varchar(30);
    current_data_type varchar(30);
    current_type_extension integer;
    current_validation_regex text;
    current_node_type_id uuid;
BEGIN
    SELECT scope, data_type, type_extension, validation_regex
    INTO current_scope, current_data_type, current_type_extension, current_validation_regex
    FROM attribute_definitions
    WHERE project_id = NEW.project_id
      AND id = NEW.attribute_definition_id;

    IF current_scope IS DISTINCT FROM 'node' THEN
        RAISE EXCEPTION 'El atributo % no pertenece al scope node.', NEW.attribute_definition_id;
    END IF;

    SELECT node_type_id
    INTO current_node_type_id
    FROM hierarchy_nodes
    WHERE project_id = NEW.project_id
      AND id = NEW.node_id;

    IF current_node_type_id IS NULL THEN
        RAISE EXCEPTION 'El nodo % no existe o no pertenece al proyecto.', NEW.node_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM node_type_attributes
        WHERE project_id = NEW.project_id
          AND node_type_id = current_node_type_id
          AND attribute_definition_id = NEW.attribute_definition_id
    ) THEN
        RAISE EXCEPTION 'El atributo % no esta asignado al tipo del nodo %.', NEW.attribute_definition_id, current_node_type_id;
    END IF;

    PERFORM validate_dynamic_attribute_value(
        NEW.project_id,
        NEW.attribute_definition_id,
        current_data_type,
        current_type_extension,
        current_validation_regex,
        NEW.value_text,
        NEW.value_number,
        NEW.value_date,
        NEW.value_boolean,
        NEW.value_json
    );

    RETURN NEW;
END;
$$;


--
-- Name: validate_node_type_attribute(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_node_type_attribute() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_scope varchar(30);
BEGIN
    SELECT scope
    INTO current_scope
    FROM attribute_definitions
    WHERE project_id = NEW.project_id
      AND id = NEW.attribute_definition_id;

    IF current_scope IS DISTINCT FROM 'node' THEN
        RAISE EXCEPTION 'El atributo % no pertenece al scope node.', NEW.attribute_definition_id;
    END IF;

    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(160),
    display_name character varying(160) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_platform_admin boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: attribute_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attribute_definitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    scope character varying(30) NOT NULL,
    code character varying(80) NOT NULL,
    name character varying(120) NOT NULL,
    data_type character varying(30) NOT NULL,
    is_required boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    default_value text,
    help_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    type_extension integer,
    validation_regex text,
    validation_message text,
    settings_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT ck_attribute_definitions_data_type CHECK (((data_type)::text = ANY ((ARRAY['string'::character varying, 'integer'::character varying, 'decimal'::character varying, 'date'::character varying, 'boolean'::character varying, 'list'::character varying, 'json'::character varying])::text[]))),
    CONSTRAINT ck_attribute_definitions_scope CHECK (((scope)::text = ANY ((ARRAY['node'::character varying, 'document'::character varying])::text[])))
);


--
-- Name: attribute_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attribute_options (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    code character varying(80) NOT NULL,
    label character varying(160) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    session_id uuid,
    project_id uuid,
    action_code character varying(120) NOT NULL,
    access_kind character varying(10) NOT NULL,
    resource_type character varying(80) NOT NULL,
    resource_id character varying(200),
    outcome character varying(20) NOT NULL,
    message text,
    details_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_audit_events_access_kind CHECK (((access_kind)::text = ANY ((ARRAY['read'::character varying, 'write'::character varying])::text[]))),
    CONSTRAINT ck_audit_events_outcome CHECK (((outcome)::text = ANY ((ARRAY['success'::character varying, 'denied'::character varying, 'error'::character varying])::text[])))
);


--
-- Name: auth_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_identities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider_id uuid NOT NULL,
    subject character varying(200) NOT NULL,
    login_name character varying(120),
    password_hash text,
    metadata_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: auth_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(80) NOT NULL,
    name character varying(160) NOT NULL,
    provider_type character varying(20) NOT NULL,
    settings_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_auth_providers_type CHECK (((provider_type)::text = ANY ((ARRAY['local'::character varying, 'ldap'::character varying, 'oidc'::character varying, 'saml'::character varying])::text[])))
);


--
-- Name: auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    identity_id uuid NOT NULL,
    provider_id uuid NOT NULL,
    session_token character varying(128) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    ip_address inet,
    user_agent text
);


--
-- Name: document_attribute_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_attribute_values (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    document_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    value_text text,
    value_number numeric(18,4),
    value_date date,
    value_boolean boolean,
    value_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: document_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_files (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    document_version_id uuid NOT NULL,
    file_role character varying(30) NOT NULL,
    storage_path text NOT NULL,
    original_name character varying(255) NOT NULL,
    extension character varying(20),
    mime_type character varying(120),
    size_bytes bigint,
    checksum_sha256 character varying(64),
    page_count integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_document_files_role CHECK (((file_role)::text = ANY ((ARRAY['original'::character varying, 'preview'::character varying, 'pdf'::character varying])::text[])))
);


--
-- Name: document_type_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_type_attributes (
    project_id uuid NOT NULL,
    document_type_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    display_order integer DEFAULT 0 NOT NULL
);


--
-- Name: document_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    code character varying(80) NOT NULL,
    name character varying(120) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: document_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    document_id uuid NOT NULL,
    version_number integer NOT NULL,
    source_type character varying(30) NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_document_versions_source_type CHECK (((source_type)::text = ANY ((ARRAY['upload'::character varying, 'scan'::character varying, 'generated'::character varying])::text[])))
);


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    node_id uuid,
    document_type_id uuid,
    title character varying(240) NOT NULL,
    description text,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL,
    current_version_number integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_documents_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'active'::character varying, 'archived'::character varying])::text[])))
);


--
-- Name: hierarchy_node_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hierarchy_node_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    code character varying(80) NOT NULL,
    name character varying(120) NOT NULL,
    description text,
    allows_documents boolean DEFAULT true NOT NULL,
    is_root_allowed boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    icon_key character varying(80) DEFAULT 'folder'::character varying NOT NULL
);


--
-- Name: hierarchy_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hierarchy_nodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    node_type_id uuid NOT NULL,
    parent_id uuid,
    code character varying(80),
    name character varying(160) NOT NULL,
    description text,
    sort_order integer DEFAULT 0 NOT NULL,
    depth integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hierarchy_type_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hierarchy_type_rules (
    project_id uuid NOT NULL,
    parent_node_type_id uuid NOT NULL,
    child_node_type_id uuid NOT NULL,
    min_children integer DEFAULT 0 NOT NULL,
    max_children integer,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_hierarchy_type_rules_bounds CHECK (((max_children IS NULL) OR (max_children >= min_children)))
);


--
-- Name: node_attribute_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.node_attribute_values (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    node_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    value_text text,
    value_number numeric(18,4),
    value_date date,
    value_boolean boolean,
    value_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: node_type_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.node_type_attributes (
    project_id uuid NOT NULL,
    node_type_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    display_order integer DEFAULT 0 NOT NULL
);


--
-- Name: permission_catalog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permission_catalog (
    code character varying(80) NOT NULL,
    name character varying(160) NOT NULL,
    description text NOT NULL,
    access_kind character varying(10) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_permission_catalog_access_kind CHECK (((access_kind)::text = ANY ((ARRAY['read'::character varying, 'write'::character varying])::text[])))
);


--
-- Name: project_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_memberships (
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: project_profile_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_profile_permissions (
    project_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    permission_code character varying(80) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: project_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    code character varying(80) NOT NULL,
    name character varying(160) NOT NULL,
    description text,
    is_system boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug character varying(80) NOT NULL,
    name character varying(160) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(64) NOT NULL,
    name character varying(200) NOT NULL,
    checksum character varying(128) NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Data for Name: app_users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.app_users VALUES ('053084b9-442c-4d22-a3e6-699d0b919077', 'admin@local.test', 'Administrador local', true, true, '2026-03-15 18:00:06.522718-03', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.app_users VALUES ('9485448d-831d-49d7-a5c7-fd18552cb238', 'aaa@gmail.cm', 'gasuarez', true, false, '2026-03-15 18:14:54.715037-03', '2026-03-15 18:14:54.715037-03');


--
-- Data for Name: attribute_definitions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.attribute_definitions VALUES ('574473f3-86df-4fea-9e54-ab4513108aea', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'node', '1', 'Nombre', 'string', false, true, NULL, NULL, '2026-03-15 17:20:01.156402-03', '2026-03-15 17:20:01.156402-03', 50, '[a-zA-ZñÑ0-9]+', NULL, '{}');
INSERT INTO public.attribute_definitions VALUES ('2bf84321-08d0-4d61-b0b6-8d5b88b9119d', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'node', '2', 'numer', 'integer', false, true, NULL, NULL, '2026-03-15 17:20:41.06725-03', '2026-03-15 17:20:41.06725-03', NULL, NULL, NULL, '{}');
INSERT INTO public.attribute_definitions VALUES ('520f35a3-cc9b-4414-a8e7-179627efe96f', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'node', '3', 'Tipoo documento', 'list', false, true, NULL, NULL, '2026-03-15 17:21:24.595235-03', '2026-03-15 17:21:24.595235-03', NULL, NULL, NULL, '{}');


--
-- Data for Name: attribute_options; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.attribute_options VALUES ('172105c7-4bf5-4e97-aa7a-b823e2d06562', 'd1ef6180-a49e-4cf9-986c-920377200d48', '520f35a3-cc9b-4414-a8e7-179627efe96f', '1', 'DNI', 0, true, '2026-03-15 17:21:24.595235-03', '2026-03-15 17:21:24.595235-03');
INSERT INTO public.attribute_options VALUES ('7f2aed0f-0eec-4314-b266-566cfd40bc11', 'd1ef6180-a49e-4cf9-986c-920377200d48', '520f35a3-cc9b-4414-a8e7-179627efe96f', '2', 'DU', 10, true, '2026-03-15 17:21:24.595235-03', '2026-03-15 17:21:24.595235-03');


--
-- Data for Name: audit_events; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.audit_events VALUES ('24d21f11-4cfe-4c6c-9769-81266a69c0c8', '053084b9-442c-4d22-a3e6-699d0b919077', '7dabe901-f425-44d7-a44b-70db136feebf', NULL, 'auth.login', 'write', 'auth_session', '7dabe901-f425-44d7-a44b-70db136feebf', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:06:53.012254-03');
INSERT INTO public.audit_events VALUES ('45be173c-5bf3-46ae-9d39-377dc9fe4e6a', '053084b9-442c-4d22-a3e6-699d0b919077', '21240d0f-8b8b-4026-906c-5d380fdb5eb0', NULL, 'auth.login', 'write', 'auth_session', '21240d0f-8b8b-4026-906c-5d380fdb5eb0', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:06:53.014583-03');
INSERT INTO public.audit_events VALUES ('0ddc29e7-6f89-4384-aede-294f07693a1c', '053084b9-442c-4d22-a3e6-699d0b919077', 'af858da6-1c00-43f2-8cc2-745fa99ff897', NULL, 'auth.login', 'write', 'auth_session', 'af858da6-1c00-43f2-8cc2-745fa99ff897', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:06:53.023323-03');
INSERT INTO public.audit_events VALUES ('142c7d86-46de-4ec1-97fb-399cf012ccb0', '053084b9-442c-4d22-a3e6-699d0b919077', 'af858da6-1c00-43f2-8cc2-745fa99ff897', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:06:53.051348-03');
INSERT INTO public.audit_events VALUES ('710934d7-7aa2-4f4a-bde1-db08bce4fcbc', '053084b9-442c-4d22-a3e6-699d0b919077', '7dabe901-f425-44d7-a44b-70db136feebf', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:06:53.051855-03');
INSERT INTO public.audit_events VALUES ('5811a651-03df-4c29-b7ec-c3e3a96af095', '053084b9-442c-4d22-a3e6-699d0b919077', 'af858da6-1c00-43f2-8cc2-745fa99ff897', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.read', 'read', 'project_security', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:06:53.070366-03');
INSERT INTO public.audit_events VALUES ('c1015cb2-106a-4186-8546-70cb25890f7a', '053084b9-442c-4d22-a3e6-699d0b919077', 'd2375323-4139-47c1-be42-220fbb3e4ce5', NULL, 'auth.login', 'write', 'auth_session', 'd2375323-4139-47c1-be42-220fbb3e4ce5', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:08:58.357845-03');
INSERT INTO public.audit_events VALUES ('6f4f90e0-3202-456d-bc89-2b820c023abc', '053084b9-442c-4d22-a3e6-699d0b919077', 'd2375323-4139-47c1-be42-220fbb3e4ce5', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:08:58.381352-03');
INSERT INTO public.audit_events VALUES ('6344c971-3037-4a69-9bfc-5f3a4b696f8a', '053084b9-442c-4d22-a3e6-699d0b919077', 'd2375323-4139-47c1-be42-220fbb3e4ce5', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.profile.create', 'write', 'project_profile', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:08:58.402553-03');
INSERT INTO public.audit_events VALUES ('50a1b052-8c2c-41a4-b9b9-b43ff489d822', '053084b9-442c-4d22-a3e6-699d0b919077', 'd2375323-4139-47c1-be42-220fbb3e4ce5', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.profile.delete', 'write', 'project_profile', '4f366d94-51f6-40d2-80f9-ace18b44317f', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:08:58.411284-03');
INSERT INTO public.audit_events VALUES ('bc500d5d-1595-4d16-a506-ae27c1e3b7a5', '053084b9-442c-4d22-a3e6-699d0b919077', 'a1222f16-c193-43ac-9db6-46b99ac75e1c', NULL, 'auth.login', 'write', 'auth_session', 'a1222f16-c193-43ac-9db6-46b99ac75e1c', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:09:53.159565-03');
INSERT INTO public.audit_events VALUES ('e7c52160-6951-46ca-95a5-a36c7bc5e5a7', '053084b9-442c-4d22-a3e6-699d0b919077', '72e2fcf2-e15f-4b49-8a30-42ed780fd542', NULL, 'auth.login', 'write', 'auth_session', '72e2fcf2-e15f-4b49-8a30-42ed780fd542', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:12:43.985855-03');
INSERT INTO public.audit_events VALUES ('35c6914d-80c0-4c89-884a-ab4617ab1f8f', '053084b9-442c-4d22-a3e6-699d0b919077', '72e2fcf2-e15f-4b49-8a30-42ed780fd542', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:12:44.069027-03');
INSERT INTO public.audit_events VALUES ('84e85f9a-b0c8-40c2-8485-754279ecce16', '053084b9-442c-4d22-a3e6-699d0b919077', '72e2fcf2-e15f-4b49-8a30-42ed780fd542', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:12:44.092893-03');
INSERT INTO public.audit_events VALUES ('c28354f0-1757-47a8-aa8f-9146c9431b09', '053084b9-442c-4d22-a3e6-699d0b919077', '72e2fcf2-e15f-4b49-8a30-42ed780fd542', NULL, 'auth.logout', 'write', 'auth_session', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:12:59.998495-03');
INSERT INTO public.audit_events VALUES ('3fb31ced-c7b4-49a2-a404-cd727b06fb66', '053084b9-442c-4d22-a3e6-699d0b919077', '36d41e3d-eabe-4f93-9c2a-3cfd69e6f9f5', NULL, 'auth.login', 'write', 'auth_session', '36d41e3d-eabe-4f93-9c2a-3cfd69e6f9f5', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:01.945139-03');
INSERT INTO public.audit_events VALUES ('494ca106-bada-4cb9-943f-2e44ff1d870d', '053084b9-442c-4d22-a3e6-699d0b919077', '36d41e3d-eabe-4f93-9c2a-3cfd69e6f9f5', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:01.974966-03');
INSERT INTO public.audit_events VALUES ('7c65840f-4795-4ebb-8a1f-72242d9d7852', '053084b9-442c-4d22-a3e6-699d0b919077', '36d41e3d-eabe-4f93-9c2a-3cfd69e6f9f5', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:01.986406-03');
INSERT INTO public.audit_events VALUES ('65c307f4-00c4-49e9-a169-e10afdd3ea80', '053084b9-442c-4d22-a3e6-699d0b919077', '36d41e3d-eabe-4f93-9c2a-3cfd69e6f9f5', NULL, 'auth.logout', 'write', 'auth_session', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:06.892986-03');
INSERT INTO public.audit_events VALUES ('90a381e5-e0fb-4f62-88fe-98b92858130f', NULL, NULL, NULL, 'auth.login', 'write', 'auth_session', NULL, 'denied', 'Credenciales inválidas.', '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:12.060568-03');
INSERT INTO public.audit_events VALUES ('5eecedaa-4aec-4844-866c-70aa7a07e5c4', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', NULL, 'auth.login', 'write', 'auth_session', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:16.618481-03');
INSERT INTO public.audit_events VALUES ('4548c4e1-8a05-4c91-8a91-67b402459ba4', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:16.636601-03');
INSERT INTO public.audit_events VALUES ('3b8472f8-6cf9-4066-b851-983c01c87701', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:16.646119-03');
INSERT INTO public.audit_events VALUES ('95551027-71a8-4c70-87f9-9029f6d9f5d1', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.read', 'read', 'project_security', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:13:45.622937-03');
INSERT INTO public.audit_events VALUES ('8d150612-9345-4871-8a2e-2bad7a2f735f', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.membership.create', 'write', 'project_membership', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:14:54.882172-03');
INSERT INTO public.audit_events VALUES ('1f1407e5-4d2c-44e9-9dc1-32de66239019', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.read', 'read', 'project_security', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:14:54.891953-03');
INSERT INTO public.audit_events VALUES ('29fe7740-0d1f-43c8-a68d-4b740a7e6959', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', NULL, 'auth.me', 'read', 'auth_user', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:14:54.898466-03');
INSERT INTO public.audit_events VALUES ('1b730e12-e535-4c3d-8d29-ec536fc010d3', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:14:54.914456-03');
INSERT INTO public.audit_events VALUES ('6e395451-fa8e-40d5-8f06-f90219cefe68', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:14:54.93425-03');
INSERT INTO public.audit_events VALUES ('791a200a-3a71-4a13-bbf7-0092519e4642', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.read', 'read', 'project_security', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:14:54.953578-03');
INSERT INTO public.audit_events VALUES ('fe51576e-21c0-4750-bac5-146d7ca68dda', '053084b9-442c-4d22-a3e6-699d0b919077', '3ab42827-3205-4d24-a6ad-7db38f7c1e9e', NULL, 'auth.logout', 'write', 'auth_session', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:00.959009-03');
INSERT INTO public.audit_events VALUES ('76453fa6-691e-45c7-9e7e-f00d6144d100', '9485448d-831d-49d7-a5c7-fd18552cb238', 'fa5cf280-402f-411b-b156-7f0a7a1c81b3', NULL, 'auth.login', 'write', 'auth_session', 'fa5cf280-402f-411b-b156-7f0a7a1c81b3', 'success', NULL, '{"login": "gasuarez", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:11.33075-03');
INSERT INTO public.audit_events VALUES ('2bedc8fe-9721-48e8-9516-5a88fc5d3553', '9485448d-831d-49d7-a5c7-fd18552cb238', 'fa5cf280-402f-411b-b156-7f0a7a1c81b3', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:11.349422-03');
INSERT INTO public.audit_events VALUES ('aaf5943c-28cf-44f0-a26b-b5fa40e03d8e', '9485448d-831d-49d7-a5c7-fd18552cb238', 'fa5cf280-402f-411b-b156-7f0a7a1c81b3', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:11.360236-03');
INSERT INTO public.audit_events VALUES ('e0f53ea0-6601-4bcd-9565-bea0d39f4979', '9485448d-831d-49d7-a5c7-fd18552cb238', 'fa5cf280-402f-411b-b156-7f0a7a1c81b3', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:17.364757-03');
INSERT INTO public.audit_events VALUES ('6a89516b-8403-48b1-8aa7-73e2ecb62e0a', '9485448d-831d-49d7-a5c7-fd18552cb238', 'fa5cf280-402f-411b-b156-7f0a7a1c81b3', NULL, 'auth.logout', 'write', 'auth_session', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:50.475305-03');
INSERT INTO public.audit_events VALUES ('17c24551-651d-4f5e-b54a-b9268986d16b', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', NULL, 'auth.login', 'write', 'auth_session', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:52.416588-03');
INSERT INTO public.audit_events VALUES ('46f8cd96-5f5a-4421-95d9-c6852220a8e5', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:52.429346-03');
INSERT INTO public.audit_events VALUES ('b194b7a2-263b-4d12-8ba2-81f61a455b4b', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:52.438583-03');
INSERT INTO public.audit_events VALUES ('20d0cb25-d52f-401b-84b4-e963e03a212b', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.read', 'read', 'project_security', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:15:56.443506-03');
INSERT INTO public.audit_events VALUES ('fe965471-4cdc-4224-a89e-7612ab6043d5', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', NULL, 'project.create', 'write', 'project', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:29.269147-03');
INSERT INTO public.audit_events VALUES ('f7b8a05e-a481-41bf-bd8f-cc560a3ca609', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:29.273442-03');
INSERT INTO public.audit_events VALUES ('6264ef41-3ece-4680-8579-453ce68d7021', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'project.snapshot', 'read', 'project', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:29.289738-03');
INSERT INTO public.audit_events VALUES ('b2ae36dc-5ccf-4705-b583-212cb560c4f5', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'types.create', 'write', 'node_type', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:40.953741-03');
INSERT INTO public.audit_events VALUES ('30f0a117-e82f-4788-b8b2-a4b3977c306b', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:40.968741-03');
INSERT INTO public.audit_events VALUES ('356f0a51-42a9-4bcf-9e8f-1e7b3ee4e8f0', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'project.snapshot', 'read', 'project', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:40.980427-03');
INSERT INTO public.audit_events VALUES ('6457be07-84d9-42d5-8e9f-59fc5910e3c8', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'security.read', 'read', 'project_security', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:43.92406-03');
INSERT INTO public.audit_events VALUES ('563ee965-f583-4240-8d3e-d4215a1b5d4c', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:51.156018-03');
INSERT INTO public.audit_events VALUES ('a0124a3d-91a1-400f-b02a-bd802dea8f5a', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'security.read', 'read', 'project_security', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:53.411347-03');
INSERT INTO public.audit_events VALUES ('86f8e77a-ab40-46b9-8a3f-28fb1d64454f', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'project.snapshot', 'read', 'project', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:17:59.723675-03');
INSERT INTO public.audit_events VALUES ('2b2345f7-bb47-40d0-b015-9d5f764675b4', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'security.read', 'read', 'project_security', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:18:01.163711-03');
INSERT INTO public.audit_events VALUES ('21280e7a-095b-4f2a-8b39-209e5385f86d', '053084b9-442c-4d22-a3e6-699d0b919077', 'c3aaa442-0be3-4382-a205-0bf809bd96ac', NULL, 'auth.logout', 'write', 'auth_session', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:18:07.438959-03');
INSERT INTO public.audit_events VALUES ('a8c1f10e-40cb-4a17-b758-853127cc76e9', '9485448d-831d-49d7-a5c7-fd18552cb238', '69ad2981-cfba-4545-a564-7dfc07cec4a5', NULL, 'auth.login', 'write', 'auth_session', '69ad2981-cfba-4545-a564-7dfc07cec4a5', 'success', NULL, '{"login": "gasuarez", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:18:16.257358-03');
INSERT INTO public.audit_events VALUES ('1388ec12-efff-4488-ac5e-7d484fd2a1d9', '9485448d-831d-49d7-a5c7-fd18552cb238', '69ad2981-cfba-4545-a564-7dfc07cec4a5', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:18:16.279291-03');
INSERT INTO public.audit_events VALUES ('4341ca03-69bc-49de-a781-7dc0c5e73242', '9485448d-831d-49d7-a5c7-fd18552cb238', '69ad2981-cfba-4545-a564-7dfc07cec4a5', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:18:16.287541-03');
INSERT INTO public.audit_events VALUES ('ffcfb93d-967b-4ccd-bf6a-cd1a34a1c135', '9485448d-831d-49d7-a5c7-fd18552cb238', '69ad2981-cfba-4545-a564-7dfc07cec4a5', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:18:18.820409-03');
INSERT INTO public.audit_events VALUES ('32f637db-6a48-4b59-ad98-ded1382dd39e', '053084b9-442c-4d22-a3e6-699d0b919077', '9b57830a-490c-4303-85e8-b07613413b72', NULL, 'auth.login', 'write', 'auth_session', '9b57830a-490c-4303-85e8-b07613413b72', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:12.651451-03');
INSERT INTO public.audit_events VALUES ('23994581-b99f-4a36-aadf-7517df5df9a8', '053084b9-442c-4d22-a3e6-699d0b919077', '9b57830a-490c-4303-85e8-b07613413b72', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:12.679817-03');
INSERT INTO public.audit_events VALUES ('376dde2a-671c-40f4-a7b1-1a82ba37bc3e', '053084b9-442c-4d22-a3e6-699d0b919077', '9b57830a-490c-4303-85e8-b07613413b72', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:12.702716-03');
INSERT INTO public.audit_events VALUES ('6d471342-aee7-43dd-bda1-2d6436f3a58c', '053084b9-442c-4d22-a3e6-699d0b919077', '9b57830a-490c-4303-85e8-b07613413b72', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'documents.list', 'read', 'document_collection', '78b0ec01-7dc4-4acc-8ff9-e60c0fed905c', 'error', 'El nodo seleccionado no acepta documentos.', '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:12.710715-03');
INSERT INTO public.audit_events VALUES ('8636a5ee-e745-4ec0-8f3f-c39fd272ccc1', '053084b9-442c-4d22-a3e6-699d0b919077', '3504bfb1-5324-4568-ab38-c4f5290fa8bc', NULL, 'auth.login', 'write', 'auth_session', '3504bfb1-5324-4568-ab38-c4f5290fa8bc', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:20.929813-03');
INSERT INTO public.audit_events VALUES ('5643f329-6fb7-4740-b2be-f8ce34f4283c', '053084b9-442c-4d22-a3e6-699d0b919077', '3504bfb1-5324-4568-ab38-c4f5290fa8bc', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:20.944388-03');
INSERT INTO public.audit_events VALUES ('40730f7a-c51d-4b77-a15f-8119bf66413d', '053084b9-442c-4d22-a3e6-699d0b919077', '3504bfb1-5324-4568-ab38-c4f5290fa8bc', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:20.955177-03');
INSERT INTO public.audit_events VALUES ('4f4c8b59-6d20-4f42-9efb-079ec07acd82', '053084b9-442c-4d22-a3e6-699d0b919077', '3504bfb1-5324-4568-ab38-c4f5290fa8bc', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'documents.list', 'read', 'document_collection', '151a0f9b-09fc-47df-8dae-a78c2a4b6b29', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 18:47:20.985343-03');
INSERT INTO public.audit_events VALUES ('7bd4ccb7-bcf8-42f6-bbb2-f55d7c4a347e', '053084b9-442c-4d22-a3e6-699d0b919077', '8d5c5bb1-a594-4a12-89f0-3bc87ba68445', NULL, 'auth.login', 'write', 'auth_session', '8d5c5bb1-a594-4a12-89f0-3bc87ba68445', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:53:17.368222-03');
INSERT INTO public.audit_events VALUES ('b1db03f8-f5e6-44f7-bea3-240a32af1ac2', '053084b9-442c-4d22-a3e6-699d0b919077', '8d5c5bb1-a594-4a12-89f0-3bc87ba68445', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:53:17.442149-03');
INSERT INTO public.audit_events VALUES ('b93bfc1e-01b2-45c5-af65-d76970bfd3a7', '053084b9-442c-4d22-a3e6-699d0b919077', '8d5c5bb1-a594-4a12-89f0-3bc87ba68445', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:53:17.455005-03');
INSERT INTO public.audit_events VALUES ('2cc1a349-a509-40e6-960e-34f9dd901940', '053084b9-442c-4d22-a3e6-699d0b919077', '8d5c5bb1-a594-4a12-89f0-3bc87ba68445', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'documents.list', 'read', 'document_collection', '151a0f9b-09fc-47df-8dae-a78c2a4b6b29', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 18:53:30.201508-03');
INSERT INTO public.audit_events VALUES ('bfea7fca-585c-4fe5-9284-577308296183', '053084b9-442c-4d22-a3e6-699d0b919077', '8d5c5bb1-a594-4a12-89f0-3bc87ba68445', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'documents.list', 'read', 'document_collection', '151a0f9b-09fc-47df-8dae-a78c2a4b6b29', 'success', NULL, '{}', '127.0.0.1', 'Dart/3.11 (dart:io)', '2026-03-15 19:00:07.827049-03');
INSERT INTO public.audit_events VALUES ('3306da7c-ab80-40fd-8871-fbab183bfd29', '053084b9-442c-4d22-a3e6-699d0b919077', '5e4e6d20-8477-4ad2-9cec-8d5e65f43df5', NULL, 'auth.login', 'write', 'auth_session', '5e4e6d20-8477-4ad2-9cec-8d5e65f43df5', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:22:16.816676-03');
INSERT INTO public.audit_events VALUES ('7f1d924f-b7ba-45a2-bce1-3e2a8d03cad4', '053084b9-442c-4d22-a3e6-699d0b919077', '5e4e6d20-8477-4ad2-9cec-8d5e65f43df5', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:22:16.83184-03');
INSERT INTO public.audit_events VALUES ('ce84fa8c-69a3-4d7f-b9fd-18cef06df14d', '053084b9-442c-4d22-a3e6-699d0b919077', '5e4e6d20-8477-4ad2-9cec-8d5e65f43df5', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:22:16.84783-03');
INSERT INTO public.audit_events VALUES ('0411fbaa-4aa9-4332-b014-351b1517dc2c', '053084b9-442c-4d22-a3e6-699d0b919077', '7b1f1f38-a7a6-45ad-b0c2-71af9c57d3fa', NULL, 'auth.login', 'write', 'auth_session', '7b1f1f38-a7a6-45ad-b0c2-71af9c57d3fa', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:22:28.384033-03');
INSERT INTO public.audit_events VALUES ('9e60bd9a-6796-4d70-bb02-1f69346b19aa', '053084b9-442c-4d22-a3e6-699d0b919077', '7b1f1f38-a7a6-45ad-b0c2-71af9c57d3fa', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:22:28.401831-03');
INSERT INTO public.audit_events VALUES ('ff0c2c69-4960-49af-b36c-3489a4557851', '053084b9-442c-4d22-a3e6-699d0b919077', '7b1f1f38-a7a6-45ad-b0c2-71af9c57d3fa', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:22:28.418059-03');
INSERT INTO public.audit_events VALUES ('65607080-8ea4-4511-bdaf-f6a6c3ea0bcb', '053084b9-442c-4d22-a3e6-699d0b919077', '2c64e489-b19f-480e-8a39-3d7095a5163f', NULL, 'auth.login', 'write', 'auth_session', '2c64e489-b19f-480e-8a39-3d7095a5163f', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:04.926412-03');
INSERT INTO public.audit_events VALUES ('2ad9f818-30bb-4362-bcc3-591bd6acbf14', '053084b9-442c-4d22-a3e6-699d0b919077', '2c64e489-b19f-480e-8a39-3d7095a5163f', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:04.953291-03');
INSERT INTO public.audit_events VALUES ('70121a1d-7356-46d4-9893-96f0698856b2', '053084b9-442c-4d22-a3e6-699d0b919077', '2c64e489-b19f-480e-8a39-3d7095a5163f', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'project.snapshot', 'read', 'project', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:04.983176-03');
INSERT INTO public.audit_events VALUES ('745971e4-3308-45e7-b0da-f108fa4e50a1', '053084b9-442c-4d22-a3e6-699d0b919077', 'fd50525e-b267-4301-b5f3-b37f2751ca47', NULL, 'auth.login', 'write', 'auth_session', 'fd50525e-b267-4301-b5f3-b37f2751ca47', 'success', NULL, '{"login": "admin", "provider": "local"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:11.697491-03');
INSERT INTO public.audit_events VALUES ('98ccfdb6-4aca-4b50-b3d7-a3e9eff10862', '053084b9-442c-4d22-a3e6-699d0b919077', 'fd50525e-b267-4301-b5f3-b37f2751ca47', NULL, 'project.list', 'read', 'project_collection', NULL, 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:11.71519-03');
INSERT INTO public.audit_events VALUES ('6996ac89-c15a-46b3-9703-632d57f74711', '053084b9-442c-4d22-a3e6-699d0b919077', 'fd50525e-b267-4301-b5f3-b37f2751ca47', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'document_types.create', 'write', 'document_type', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:11.726517-03');
INSERT INTO public.audit_events VALUES ('90b189ab-0874-4698-a987-10e85e16818f', '053084b9-442c-4d22-a3e6-699d0b919077', 'fd50525e-b267-4301-b5f3-b37f2751ca47', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'document_types.delete', 'write', 'document_type', '2bddd4e5-a7a0-4a5a-869b-e415203fea1d', 'success', NULL, '{}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5', '2026-03-15 19:23:11.739969-03');


--
-- Data for Name: auth_identities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.auth_identities VALUES ('b4395db7-2359-4c4e-9316-68269e118e97', '9485448d-831d-49d7-a5c7-fd18552cb238', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'gasuarez', 'gasuarez', '$2a$12$/mSZUc/f/4kjGoKozy2.qeX7w2RtcFv7uuLfPKMFNZIW.am8gW7VC', '{}', true, '2026-03-15 18:18:16.253365-03', '2026-03-15 18:14:54.715037-03', '2026-03-15 18:18:16.253365-03');
INSERT INTO public.auth_identities VALUES ('90d8739d-34fb-465b-b021-510fcf941746', '053084b9-442c-4d22-a3e6-699d0b919077', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'admin', 'admin', '$2a$12$CBfjAXfnvMaxM90KeAL1mO2f5ufMnJ8lx3wm9CK4L30z6aMKKfObO', '{"seeded": true}', true, '2026-03-15 19:23:11.693173-03', '2026-03-15 18:00:06.522718-03', '2026-03-15 19:23:11.693173-03');


--
-- Data for Name: auth_providers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.auth_providers VALUES ('c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'local', 'Credenciales locales', 'local', '{}', true, '2026-03-15 18:00:06.522718-03', '2026-03-15 18:00:06.522718-03');


--
-- Data for Name: auth_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.auth_sessions VALUES ('21240d0f-8b8b-4026-906c-5d380fdb5eb0', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '7c1857bbe98bf87b5da8ae32af0c4bd131b6fcea8b9c1509a1b9276859a2f124', '2026-03-15 18:06:52.991781-03', '2026-03-16 06:06:52.991781-03', NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('8d5c5bb1-a594-4a12-89f0-3bc87ba68445', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '99d524374cb9398e841f4c3346c8802ee415b6baedd30d5307dc89a302a410f9', '2026-03-15 18:53:17.36056-03', '2026-03-16 06:53:17.36056-03', NULL, '2026-03-15 19:00:07.82095-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('7dabe901-f425-44d7-a44b-70db136feebf', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'e9e0d17bdb31ce3c06d4b8eb688dc10496b9a5ab0f12a0a008c90e86dd8e8c9b', '2026-03-15 18:06:52.987681-03', '2026-03-16 06:06:52.987681-03', NULL, '2026-03-15 18:06:53.045537-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('af858da6-1c00-43f2-8cc2-745fa99ff897', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '970e9191e63b7c19a847f0cb370bdeb8ba3d3beb76b1d33c7d2e71293de8886a', '2026-03-15 18:06:52.993331-03', '2026-03-16 06:06:52.993331-03', NULL, '2026-03-15 18:06:53.062098-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('3ab42827-3205-4d24-a6ad-7db38f7c1e9e', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '0483e76e8448890fba7aa5e57f95f2fede8c5f06e2803dfb8eb69ef08233399e', '2026-03-15 18:13:16.611734-03', '2026-03-16 06:13:16.611734-03', '2026-03-15 18:15:00.958155-03', '2026-03-15 18:15:00.955782-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('d2375323-4139-47c1-be42-220fbb3e4ce5', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'c79d377dfe12091036295809a0f6910813b6042518fd70368bc026862e13fdf7', '2026-03-15 18:08:58.352538-03', '2026-03-16 06:08:58.352538-03', NULL, '2026-03-15 18:08:58.406842-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('a1222f16-c193-43ac-9db6-46b99ac75e1c', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '0ac180a4d6e7df02db1f38edc006e028106c626d317e7246952ef48c33720734', '2026-03-15 18:09:53.147235-03', '2026-03-16 06:09:53.147235-03', NULL, NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('c3aaa442-0be3-4382-a205-0bf809bd96ac', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '4cb83ca37e5e0c9ab18c2790574135c77bd750ee8cf7326e0b96903faec98014', '2026-03-15 18:15:52.410683-03', '2026-03-16 06:15:52.410683-03', '2026-03-15 18:18:07.438121-03', '2026-03-15 18:18:07.435822-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('72e2fcf2-e15f-4b49-8a30-42ed780fd542', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '7da678e32ebd86163a70fe467e52c35ff5b4fc15b81e4009daa3ade122723c23', '2026-03-15 18:12:43.979738-03', '2026-03-16 06:12:43.979738-03', '2026-03-15 18:12:59.997355-03', '2026-03-15 18:12:59.996258-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('fd50525e-b267-4301-b5f3-b37f2751ca47', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'da2011c5bdc83422b66443ce9246c151882bcb25978284e6a276d3b653622863', '2026-03-15 19:23:11.691181-03', '2026-03-16 07:23:11.691181-03', NULL, '2026-03-15 19:23:11.733776-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('5e4e6d20-8477-4ad2-9cec-8d5e65f43df5', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '1b8ca2af8e97f587596a47dcecb1681b7672a70720b37bb06af020d1ff10c4c6', '2026-03-15 19:22:16.810117-03', '2026-03-16 07:22:16.810117-03', NULL, '2026-03-15 19:22:16.840845-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('fa5cf280-402f-411b-b156-7f0a7a1c81b3', '9485448d-831d-49d7-a5c7-fd18552cb238', 'b4395db7-2359-4c4e-9316-68269e118e97', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'ea08b072006682d7a9425401df3343074a413b9fef89cde3cec333dd04ab67c4', '2026-03-15 18:15:11.323049-03', '2026-03-16 06:15:11.323049-03', '2026-03-15 18:15:50.474369-03', '2026-03-15 18:15:50.472526-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('36d41e3d-eabe-4f93-9c2a-3cfd69e6f9f5', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'edfff433af9290b85317b8fffbecbe1536ad7ea8ffcb2d8360b9dce210f7c58c', '2026-03-15 18:13:01.939019-03', '2026-03-16 06:13:01.939019-03', '2026-03-15 18:13:06.892076-03', '2026-03-15 18:13:06.891343-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('69ad2981-cfba-4545-a564-7dfc07cec4a5', '9485448d-831d-49d7-a5c7-fd18552cb238', 'b4395db7-2359-4c4e-9316-68269e118e97', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'c81f49f2a2361793c7dfdd6c4f59041b4feab41a2230a56a41627973b1d885ee', '2026-03-15 18:18:16.251313-03', '2026-03-16 06:18:16.251313-03', NULL, '2026-03-15 18:18:18.813196-03', '127.0.0.1', 'Dart/3.11 (dart:io)');
INSERT INTO public.auth_sessions VALUES ('9b57830a-490c-4303-85e8-b07613413b72', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '4a3247e7cf8e204e6f64c5b63fbee3f747f2e190a1045169b623d78128b6293a', '2026-03-15 18:47:12.638778-03', '2026-03-16 06:47:12.638778-03', NULL, '2026-03-15 18:47:12.708346-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('7b1f1f38-a7a6-45ad-b0c2-71af9c57d3fa', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'a50f13563f3201a8711d28f7ce840e856bc9fc4885557862cbb6b94b85339105', '2026-03-15 19:22:28.379291-03', '2026-03-16 07:22:28.379291-03', NULL, '2026-03-15 19:22:28.411043-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('3504bfb1-5324-4568-ab38-c4f5290fa8bc', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', '8703d496fcaf6207305f5a722ec26f09a2b27a7468ca8922e32f51e73c9495a5', '2026-03-15 18:47:20.923576-03', '2026-03-16 06:47:20.923576-03', NULL, '2026-03-15 18:47:20.979524-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');
INSERT INTO public.auth_sessions VALUES ('2c64e489-b19f-480e-8a39-3d7095a5163f', '053084b9-442c-4d22-a3e6-699d0b919077', '90d8739d-34fb-465b-b021-510fcf941746', 'c460e2db-4f34-4411-8a5f-e47cdb6b020c', 'a5f1757ad8a4054541ae3006a9098543f7588a7cac277d84a651470213d321ee', '2026-03-15 19:23:04.91286-03', '2026-03-16 07:23:04.91286-03', NULL, '2026-03-15 19:23:04.965151-03', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26100; es-AR) PowerShell/7.5.5');


--
-- Data for Name: document_attribute_values; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: document_files; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: document_type_attributes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: document_types; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: document_versions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: hierarchy_node_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.hierarchy_node_types VALUES ('42f3a240-12e1-4e69-bae0-78369899b675', 'd1ef6180-a49e-4cf9-986c-920377200d48', '1', 'Caja', 'Contiene biblioratos', false, true, 1, true, '2026-03-15 17:08:05.038289-03', '2026-03-15 17:08:05.038289-03', 'folder');
INSERT INTO public.hierarchy_node_types VALUES ('a6fc8d42-f962-4725-b2d5-dfd2d405b1b6', 'd1ef6180-a49e-4cf9-986c-920377200d48', '2', 'Bibliorato', 'Contiene expedientes', false, false, 2, true, '2026-03-15 17:08:41.818767-03', '2026-03-15 17:08:41.818767-03', 'inventory_2');
INSERT INTO public.hierarchy_node_types VALUES ('9a714ee7-dccc-4dd3-af59-fcadab2b21ba', 'd1ef6180-a49e-4cf9-986c-920377200d48', '123', 'expediente', 'Guarda documentos', true, false, 10, true, '2026-03-15 17:14:20.995707-03', '2026-03-15 17:15:37.247155-03', 'archive');
INSERT INTO public.hierarchy_node_types VALUES ('1e23bb18-980c-4c7d-b9d3-d0c7f1c78530', '7b99518e-8b2c-44cf-9019-0f779a783b83', '1', 'Caja', NULL, true, false, 1, true, '2026-03-15 18:17:40.952706-03', '2026-03-15 18:17:40.952706-03', 'folder');


--
-- Data for Name: hierarchy_nodes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.hierarchy_nodes VALUES ('151a0f9b-09fc-47df-8dae-a78c2a4b6b29', 'd1ef6180-a49e-4cf9-986c-920377200d48', '9a714ee7-dccc-4dd3-af59-fcadab2b21ba', 'c01ecd50-3b3a-4413-8c43-b19d2c26c04a', '3', 'Expe 1', 'Pagina', 3, 2, true, '2026-03-15 17:35:29.503395-03', '2026-03-15 17:35:29.503395-03');
INSERT INTO public.hierarchy_nodes VALUES ('c01ecd50-3b3a-4413-8c43-b19d2c26c04a', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'a6fc8d42-f962-4725-b2d5-dfd2d405b1b6', '78b0ec01-7dc4-4acc-8ff9-e60c0fed905c', '1', 'B1', 'Contiene expedientes del 1 al 5', 1, 1, true, '2026-03-15 17:16:51.339015-03', '2026-03-15 17:35:38.736752-03');
INSERT INTO public.hierarchy_nodes VALUES ('78b0ec01-7dc4-4acc-8ff9-e60c0fed905c', 'd1ef6180-a49e-4cf9-986c-920377200d48', '42f3a240-12e1-4e69-bae0-78369899b675', NULL, '1', 'C1', 'Contiene los biblioratos 1 al 5', 1, 0, true, '2026-03-15 17:16:22.6527-03', '2026-03-15 17:36:25.598926-03');


--
-- Data for Name: hierarchy_type_rules; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.hierarchy_type_rules VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '42f3a240-12e1-4e69-bae0-78369899b675', 'a6fc8d42-f962-4725-b2d5-dfd2d405b1b6', 0, NULL, 0, '2026-03-15 17:15:03.687723-03');
INSERT INTO public.hierarchy_type_rules VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'a6fc8d42-f962-4725-b2d5-dfd2d405b1b6', '9a714ee7-dccc-4dd3-af59-fcadab2b21ba', 0, NULL, 0, '2026-03-15 17:15:14.579105-03');


--
-- Data for Name: node_attribute_values; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.node_attribute_values VALUES ('eb57a869-2a5a-47f8-a006-bf238ae6073a', 'd1ef6180-a49e-4cf9-986c-920377200d48', '151a0f9b-09fc-47df-8dae-a78c2a4b6b29', '520f35a3-cc9b-4414-a8e7-179627efe96f', '1', NULL, NULL, NULL, NULL, '2026-03-15 17:35:29.503395-03', '2026-03-15 17:35:29.503395-03');
INSERT INTO public.node_attribute_values VALUES ('80b79a4c-3f25-4bc8-940b-29cf4ece1b06', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'c01ecd50-3b3a-4413-8c43-b19d2c26c04a', '2bf84321-08d0-4d61-b0b6-8d5b88b9119d', NULL, 123.0000, NULL, NULL, NULL, '2026-03-15 17:35:38.736752-03', '2026-03-15 17:35:38.736752-03');
INSERT INTO public.node_attribute_values VALUES ('cd284875-f4cc-4d1d-afca-9d744c3184d1', 'd1ef6180-a49e-4cf9-986c-920377200d48', '78b0ec01-7dc4-4acc-8ff9-e60c0fed905c', '574473f3-86df-4fea-9e54-ab4513108aea', 'Caja loca.$', NULL, NULL, NULL, NULL, '2026-03-15 17:36:25.598926-03', '2026-03-15 17:36:25.598926-03');


--
-- Data for Name: node_type_attributes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.node_type_attributes VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '42f3a240-12e1-4e69-bae0-78369899b675', '574473f3-86df-4fea-9e54-ab4513108aea', 0);
INSERT INTO public.node_type_attributes VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'a6fc8d42-f962-4725-b2d5-dfd2d405b1b6', '2bf84321-08d0-4d61-b0b6-8d5b88b9119d', 0);
INSERT INTO public.node_type_attributes VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '9a714ee7-dccc-4dd3-af59-fcadab2b21ba', '520f35a3-cc9b-4414-a8e7-179627efe96f', 0);


--
-- Data for Name: permission_catalog; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.permission_catalog VALUES ('project.read', 'Leer proyecto', 'Permite ver proyectos y seleccionar el contexto actual.', 'read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('project.write', 'Modificar proyecto', 'Permite crear, editar y eliminar la configuración base del proyecto.', 'write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('types.read', 'Leer tipos', 'Permite ver tipos de contenedor, atributos y reglas del proyecto.', 'read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('types.write', 'Modificar tipos', 'Permite crear, editar y eliminar tipos, atributos y reglas del proyecto.', 'write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('hierarchy.read', 'Leer jerarquía', 'Permite consultar la jerarquía real del proyecto.', 'read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('hierarchy.write', 'Modificar jerarquía', 'Permite crear, editar y eliminar nodos reales en la jerarquía.', 'write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('security.read', 'Leer seguridad', 'Permite consultar perfiles, permisos y membresías del proyecto.', 'read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('security.write', 'Modificar seguridad', 'Permite crear perfiles y administrar accesos del proyecto.', 'write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.permission_catalog VALUES ('documents.read', 'Ver documentos', 'Permite consultar documentos del proyecto y descargar sus PDFs.', 'read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.permission_catalog VALUES ('documents.write', 'Gestionar documentos', 'Permite escanear, crear documentos y guardar nuevas capturas.', 'write', '2026-03-15 18:45:50.733277-03');


--
-- Data for Name: project_memberships; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_memberships VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '053084b9-442c-4d22-a3e6-699d0b919077', '5d904f04-d81a-4767-9fcf-574e2e7129d1', true, '2026-03-15 18:00:06.522718-03', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_memberships VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '9485448d-831d-49d7-a5c7-fd18552cb238', 'a47c0f81-815a-4dd0-8936-e7561caf1698', true, '2026-03-15 18:14:54.715037-03', '2026-03-15 18:14:54.715037-03');
INSERT INTO public.project_memberships VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '053084b9-442c-4d22-a3e6-699d0b919077', '12713629-e024-4a2e-9d89-3fe1ad1ee635', true, '2026-03-15 18:17:29.264709-03', '2026-03-15 18:17:29.264709-03');


--
-- Data for Name: project_profile_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'project.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'project.write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'types.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'types.write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'hierarchy.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'hierarchy.write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'security.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'security.write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'project.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'types.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'types.write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'hierarchy.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'hierarchy.write', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'a47c0f81-815a-4dd0-8936-e7561caf1698', 'project.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'a47c0f81-815a-4dd0-8936-e7561caf1698', 'types.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'a47c0f81-815a-4dd0-8936-e7561caf1698', 'hierarchy.read', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'project.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'project.write', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'types.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'types.write', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'hierarchy.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'hierarchy.write', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'security.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'security.write', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'project.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'types.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'types.write', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'hierarchy.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'hierarchy.write', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '0b152008-ccb1-4329-8d56-ff9b7e9e458d', 'project.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '0b152008-ccb1-4329-8d56-ff9b7e9e458d', 'types.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '0b152008-ccb1-4329-8d56-ff9b7e9e458d', 'hierarchy.read', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'documents.read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'documents.read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'a47c0f81-815a-4dd0-8936-e7561caf1698', 'documents.read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'documents.read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'documents.read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '0b152008-ccb1-4329-8d56-ff9b7e9e458d', 'documents.read', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '5d904f04-d81a-4767-9fcf-574e2e7129d1', 'documents.write', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', '24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'documents.write', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '12713629-e024-4a2e-9d89-3fe1ad1ee635', 'documents.write', '2026-03-15 18:45:50.733277-03');
INSERT INTO public.project_profile_permissions VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', '584c7265-61ac-4fa9-ae80-fba7683f964c', 'documents.write', '2026-03-15 18:45:50.733277-03');


--
-- Data for Name: project_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_profiles VALUES ('5d904f04-d81a-4767-9fcf-574e2e7129d1', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'admin', 'Administrador del proyecto', 'Acceso completo a configuración, jerarquía y seguridad del proyecto.', true, true, '2026-03-15 18:00:06.522718-03', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profiles VALUES ('24834a17-5a1e-4277-ba80-98fdb35ff0bf', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'editor', 'Editor del proyecto', 'Puede modificar tipos y jerarquía del proyecto, pero no administrar seguridad.', true, true, '2026-03-15 18:00:06.522718-03', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profiles VALUES ('a47c0f81-815a-4dd0-8936-e7561caf1698', 'd1ef6180-a49e-4cf9-986c-920377200d48', 'viewer', 'Consulta del proyecto', 'Puede ver configuración y jerarquía sin realizar cambios.', true, true, '2026-03-15 18:00:06.522718-03', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.project_profiles VALUES ('12713629-e024-4a2e-9d89-3fe1ad1ee635', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'admin', 'Administrador del proyecto', 'Acceso completo a configuración, jerarquía y seguridad del proyecto.', true, true, '2026-03-15 18:17:29.264709-03', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profiles VALUES ('584c7265-61ac-4fa9-ae80-fba7683f964c', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'editor', 'Editor del proyecto', 'Puede modificar tipos y jerarquía del proyecto, pero no administrar seguridad.', true, true, '2026-03-15 18:17:29.264709-03', '2026-03-15 18:17:29.264709-03');
INSERT INTO public.project_profiles VALUES ('0b152008-ccb1-4329-8d56-ff9b7e9e458d', '7b99518e-8b2c-44cf-9019-0f779a783b83', 'viewer', 'Consulta del proyecto', 'Puede ver configuración y jerarquía sin realizar cambios.', true, true, '2026-03-15 18:17:29.264709-03', '2026-03-15 18:17:29.264709-03');


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.projects VALUES ('d1ef6180-a49e-4cf9-986c-920377200d48', 'ministerio', 'Economia', 'Ministerio de economia', true, '2026-03-15 17:07:00.416141-03', '2026-03-15 17:07:00.416141-03');
INSERT INTO public.projects VALUES ('7b99518e-8b2c-44cf-9019-0f779a783b83', 'nuevo', 'Nuevo', 'Gabi no deberia', true, '2026-03-15 18:17:29.264709-03', '2026-03-15 18:17:29.264709-03');


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.schema_migrations VALUES ('V202603151410', 'init_projects_hierarchy_v1', 'sha256:pending', '2026-03-15 16:15:59.627737-03');
INSERT INTO public.schema_migrations VALUES ('V202603151730', 'extend_dynamic_attributes_v2', 'sha256:pending', '2026-03-15 16:15:59.815032-03');
INSERT INTO public.schema_migrations VALUES ('V202603151900', 'add_node_type_icon_key', 'sha256:pending', '2026-03-15 16:29:45.492386-03');
INSERT INTO public.schema_migrations VALUES ('V202603152130', 'add_auth_profiles_and_audit_v3', 'sha256:pending', '2026-03-15 18:00:06.522718-03');
INSERT INTO public.schema_migrations VALUES ('V202603152245', 'add_document_permissions_v4', 'sha256:pending', '2026-03-15 18:45:50.733277-03');


--
-- Name: app_users app_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_pkey PRIMARY KEY (id);


--
-- Name: attribute_definitions attribute_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_definitions
    ADD CONSTRAINT attribute_definitions_pkey PRIMARY KEY (id);


--
-- Name: attribute_options attribute_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT attribute_options_pkey PRIMARY KEY (id);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: auth_identities auth_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT auth_identities_pkey PRIMARY KEY (id);


--
-- Name: auth_providers auth_providers_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_providers
    ADD CONSTRAINT auth_providers_code_key UNIQUE (code);


--
-- Name: auth_providers auth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_providers
    ADD CONSTRAINT auth_providers_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_session_token_key UNIQUE (session_token);


--
-- Name: document_attribute_values document_attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_attribute_values
    ADD CONSTRAINT document_attribute_values_pkey PRIMARY KEY (id);


--
-- Name: document_files document_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_files
    ADD CONSTRAINT document_files_pkey PRIMARY KEY (id);


--
-- Name: document_type_attributes document_type_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_type_attributes
    ADD CONSTRAINT document_type_attributes_pkey PRIMARY KEY (project_id, document_type_id, attribute_definition_id);


--
-- Name: document_types document_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_types
    ADD CONSTRAINT document_types_pkey PRIMARY KEY (id);


--
-- Name: document_versions document_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT document_versions_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: hierarchy_node_types hierarchy_node_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_node_types
    ADD CONSTRAINT hierarchy_node_types_pkey PRIMARY KEY (id);


--
-- Name: hierarchy_nodes hierarchy_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT hierarchy_nodes_pkey PRIMARY KEY (id);


--
-- Name: hierarchy_type_rules hierarchy_type_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_type_rules
    ADD CONSTRAINT hierarchy_type_rules_pkey PRIMARY KEY (project_id, parent_node_type_id, child_node_type_id);


--
-- Name: node_attribute_values node_attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_attribute_values
    ADD CONSTRAINT node_attribute_values_pkey PRIMARY KEY (id);


--
-- Name: node_type_attributes node_type_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_type_attributes
    ADD CONSTRAINT node_type_attributes_pkey PRIMARY KEY (project_id, node_type_id, attribute_definition_id);


--
-- Name: permission_catalog permission_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission_catalog
    ADD CONSTRAINT permission_catalog_pkey PRIMARY KEY (code);


--
-- Name: project_memberships project_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT project_memberships_pkey PRIMARY KEY (project_id, user_id);


--
-- Name: project_profile_permissions project_profile_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profile_permissions
    ADD CONSTRAINT project_profile_permissions_pkey PRIMARY KEY (project_id, profile_id, permission_code);


--
-- Name: project_profiles project_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profiles
    ADD CONSTRAINT project_profiles_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: projects projects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_slug_key UNIQUE (slug);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: attribute_definitions uq_attribute_definitions_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_definitions
    ADD CONSTRAINT uq_attribute_definitions_project_id UNIQUE (project_id, id);


--
-- Name: attribute_definitions uq_attribute_definitions_project_scope_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_definitions
    ADD CONSTRAINT uq_attribute_definitions_project_scope_code UNIQUE (project_id, scope, code);


--
-- Name: attribute_options uq_attribute_options_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT uq_attribute_options_code UNIQUE (project_id, attribute_definition_id, code);


--
-- Name: attribute_options uq_attribute_options_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT uq_attribute_options_project_id UNIQUE (project_id, id);


--
-- Name: auth_identities uq_auth_identities_provider_subject; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT uq_auth_identities_provider_subject UNIQUE (provider_id, subject);


--
-- Name: document_attribute_values uq_document_attribute_values; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_attribute_values
    ADD CONSTRAINT uq_document_attribute_values UNIQUE (project_id, document_id, attribute_definition_id);


--
-- Name: document_types uq_document_types_project_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_types
    ADD CONSTRAINT uq_document_types_project_code UNIQUE (project_id, code);


--
-- Name: document_types uq_document_types_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_types
    ADD CONSTRAINT uq_document_types_project_id UNIQUE (project_id, id);


--
-- Name: document_versions uq_document_versions_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT uq_document_versions_project_id UNIQUE (project_id, id);


--
-- Name: document_versions uq_document_versions_project_version; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT uq_document_versions_project_version UNIQUE (project_id, document_id, version_number);


--
-- Name: documents uq_documents_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT uq_documents_project_id UNIQUE (project_id, id);


--
-- Name: hierarchy_node_types uq_hierarchy_node_types_project_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_node_types
    ADD CONSTRAINT uq_hierarchy_node_types_project_code UNIQUE (project_id, code);


--
-- Name: hierarchy_node_types uq_hierarchy_node_types_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_node_types
    ADD CONSTRAINT uq_hierarchy_node_types_project_id UNIQUE (project_id, id);


--
-- Name: hierarchy_nodes uq_hierarchy_nodes_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT uq_hierarchy_nodes_project_id UNIQUE (project_id, id);


--
-- Name: hierarchy_nodes uq_hierarchy_nodes_sibling_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT uq_hierarchy_nodes_sibling_code UNIQUE NULLS NOT DISTINCT (project_id, parent_id, code);


--
-- Name: hierarchy_nodes uq_hierarchy_nodes_sibling_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT uq_hierarchy_nodes_sibling_name UNIQUE NULLS NOT DISTINCT (project_id, parent_id, name);


--
-- Name: node_attribute_values uq_node_attribute_values; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_attribute_values
    ADD CONSTRAINT uq_node_attribute_values UNIQUE (project_id, node_id, attribute_definition_id);


--
-- Name: project_profiles uq_project_profiles_project_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profiles
    ADD CONSTRAINT uq_project_profiles_project_code UNIQUE (project_id, code);


--
-- Name: project_profiles uq_project_profiles_project_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profiles
    ADD CONSTRAINT uq_project_profiles_project_id UNIQUE (project_id, id);


--
-- Name: idx_attribute_definitions_project_scope_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attribute_definitions_project_scope_active ON public.attribute_definitions USING btree (project_id, scope, is_active, name);


--
-- Name: idx_attribute_options_project_attribute; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attribute_options_project_attribute ON public.attribute_options USING btree (project_id, attribute_definition_id, sort_order, label);


--
-- Name: idx_audit_events_action_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_events_action_created_at ON public.audit_events USING btree (action_code, created_at DESC);


--
-- Name: idx_audit_events_project_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_events_project_created_at ON public.audit_events USING btree (project_id, created_at DESC);


--
-- Name: idx_audit_events_user_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_events_user_created_at ON public.audit_events USING btree (user_id, created_at DESC);


--
-- Name: idx_auth_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_sessions_user ON public.auth_sessions USING btree (user_id, revoked_at, expires_at DESC);


--
-- Name: idx_document_attribute_values_attribute_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_document_attribute_values_attribute_date ON public.document_attribute_values USING btree (project_id, attribute_definition_id, value_date) WHERE (value_date IS NOT NULL);


--
-- Name: idx_document_attribute_values_attribute_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_document_attribute_values_attribute_number ON public.document_attribute_values USING btree (project_id, attribute_definition_id, value_number) WHERE (value_number IS NOT NULL);


--
-- Name: idx_document_attribute_values_attribute_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_document_attribute_values_attribute_text ON public.document_attribute_values USING btree (project_id, attribute_definition_id, value_text) WHERE (value_text IS NOT NULL);


--
-- Name: idx_document_versions_project_document; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_document_versions_project_document ON public.document_versions USING btree (project_id, document_id, version_number DESC);


--
-- Name: idx_documents_project_node; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documents_project_node ON public.documents USING btree (project_id, node_id, updated_at DESC);


--
-- Name: idx_hierarchy_node_types_project_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hierarchy_node_types_project_order ON public.hierarchy_node_types USING btree (project_id, sort_order, name);


--
-- Name: idx_hierarchy_nodes_project_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hierarchy_nodes_project_parent ON public.hierarchy_nodes USING btree (project_id, parent_id, sort_order, name);


--
-- Name: idx_hierarchy_nodes_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hierarchy_nodes_project_type ON public.hierarchy_nodes USING btree (project_id, node_type_id);


--
-- Name: idx_hierarchy_type_rules_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hierarchy_type_rules_parent ON public.hierarchy_type_rules USING btree (project_id, parent_node_type_id, sort_order, child_node_type_id);


--
-- Name: idx_node_attribute_values_attribute_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_attribute_values_attribute_date ON public.node_attribute_values USING btree (project_id, attribute_definition_id, value_date) WHERE (value_date IS NOT NULL);


--
-- Name: idx_node_attribute_values_attribute_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_attribute_values_attribute_number ON public.node_attribute_values USING btree (project_id, attribute_definition_id, value_number) WHERE (value_number IS NOT NULL);


--
-- Name: idx_node_attribute_values_attribute_text; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_attribute_values_attribute_text ON public.node_attribute_values USING btree (project_id, attribute_definition_id, value_text) WHERE (value_text IS NOT NULL);


--
-- Name: idx_project_memberships_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_memberships_project ON public.project_memberships USING btree (project_id, is_active, user_id);


--
-- Name: idx_project_memberships_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_memberships_user ON public.project_memberships USING btree (user_id, is_active, project_id);


--
-- Name: uq_auth_identities_provider_login; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_auth_identities_provider_login ON public.auth_identities USING btree (provider_id, lower((login_name)::text)) WHERE (login_name IS NOT NULL);


--
-- Name: app_users trg_app_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_app_users_updated_at BEFORE UPDATE ON public.app_users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: attribute_definitions trg_attribute_definitions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attribute_definitions_updated_at BEFORE UPDATE ON public.attribute_definitions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: attribute_definitions trg_attribute_definitions_validate_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attribute_definitions_validate_before_write BEFORE INSERT OR UPDATE OF data_type, type_extension, validation_regex, settings_json ON public.attribute_definitions FOR EACH ROW EXECUTE FUNCTION public.validate_attribute_definition();


--
-- Name: attribute_options trg_attribute_options_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attribute_options_updated_at BEFORE UPDATE ON public.attribute_options FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: attribute_options trg_attribute_options_validate_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attribute_options_validate_before_write BEFORE INSERT OR UPDATE OF attribute_definition_id, project_id, code, label ON public.attribute_options FOR EACH ROW EXECUTE FUNCTION public.validate_attribute_option();


--
-- Name: auth_identities trg_auth_identities_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auth_identities_updated_at BEFORE UPDATE ON public.auth_identities FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: auth_providers trg_auth_providers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auth_providers_updated_at BEFORE UPDATE ON public.auth_providers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: document_attribute_values trg_document_attribute_values_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_document_attribute_values_updated_at BEFORE UPDATE ON public.document_attribute_values FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: document_attribute_values trg_document_attribute_values_validate_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_document_attribute_values_validate_before_write BEFORE INSERT OR UPDATE OF project_id, document_id, attribute_definition_id, value_text, value_number, value_date, value_boolean, value_json ON public.document_attribute_values FOR EACH ROW EXECUTE FUNCTION public.validate_document_attribute_value();


--
-- Name: document_type_attributes trg_document_type_attributes_validate_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_document_type_attributes_validate_before_write BEFORE INSERT OR UPDATE OF attribute_definition_id, project_id ON public.document_type_attributes FOR EACH ROW EXECUTE FUNCTION public.validate_document_type_attribute();


--
-- Name: document_types trg_document_types_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_document_types_updated_at BEFORE UPDATE ON public.document_types FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: documents trg_documents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_documents_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: hierarchy_node_types trg_hierarchy_node_types_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_hierarchy_node_types_updated_at BEFORE UPDATE ON public.hierarchy_node_types FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: hierarchy_nodes trg_hierarchy_nodes_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_hierarchy_nodes_before_write BEFORE INSERT OR UPDATE OF project_id, node_type_id, parent_id ON public.hierarchy_nodes FOR EACH ROW EXECUTE FUNCTION public.hierarchy_nodes_before_write();


--
-- Name: hierarchy_nodes trg_hierarchy_nodes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_hierarchy_nodes_updated_at BEFORE UPDATE ON public.hierarchy_nodes FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: node_attribute_values trg_node_attribute_values_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_node_attribute_values_updated_at BEFORE UPDATE ON public.node_attribute_values FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: node_attribute_values trg_node_attribute_values_validate_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_node_attribute_values_validate_before_write BEFORE INSERT OR UPDATE OF project_id, node_id, attribute_definition_id, value_text, value_number, value_date, value_boolean, value_json ON public.node_attribute_values FOR EACH ROW EXECUTE FUNCTION public.validate_node_attribute_value();


--
-- Name: node_type_attributes trg_node_type_attributes_validate_before_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_node_type_attributes_validate_before_write BEFORE INSERT OR UPDATE OF attribute_definition_id, project_id ON public.node_type_attributes FOR EACH ROW EXECUTE FUNCTION public.validate_node_type_attribute();


--
-- Name: project_memberships trg_project_memberships_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_project_memberships_updated_at BEFORE UPDATE ON public.project_memberships FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: project_profiles trg_project_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_project_profiles_updated_at BEFORE UPDATE ON public.project_profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: projects trg_projects_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: attribute_definitions fk_attribute_definitions_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_definitions
    ADD CONSTRAINT fk_attribute_definitions_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: attribute_options fk_attribute_options_attribute; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT fk_attribute_options_attribute FOREIGN KEY (project_id, attribute_definition_id) REFERENCES public.attribute_definitions(project_id, id) ON DELETE CASCADE;


--
-- Name: attribute_options fk_attribute_options_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT fk_attribute_options_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: audit_events fk_audit_events_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_audit_events_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: audit_events fk_audit_events_session; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_audit_events_session FOREIGN KEY (session_id) REFERENCES public.auth_sessions(id) ON DELETE SET NULL;


--
-- Name: audit_events fk_audit_events_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_audit_events_user FOREIGN KEY (user_id) REFERENCES public.app_users(id) ON DELETE SET NULL;


--
-- Name: auth_identities fk_auth_identities_provider; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT fk_auth_identities_provider FOREIGN KEY (provider_id) REFERENCES public.auth_providers(id) ON DELETE RESTRICT;


--
-- Name: auth_identities fk_auth_identities_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT fk_auth_identities_user FOREIGN KEY (user_id) REFERENCES public.app_users(id) ON DELETE CASCADE;


--
-- Name: auth_sessions fk_auth_sessions_identity; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT fk_auth_sessions_identity FOREIGN KEY (identity_id) REFERENCES public.auth_identities(id) ON DELETE CASCADE;


--
-- Name: auth_sessions fk_auth_sessions_provider; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT fk_auth_sessions_provider FOREIGN KEY (provider_id) REFERENCES public.auth_providers(id) ON DELETE RESTRICT;


--
-- Name: auth_sessions fk_auth_sessions_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT fk_auth_sessions_user FOREIGN KEY (user_id) REFERENCES public.app_users(id) ON DELETE CASCADE;


--
-- Name: document_attribute_values fk_document_attribute_values_attribute; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_attribute_values
    ADD CONSTRAINT fk_document_attribute_values_attribute FOREIGN KEY (project_id, attribute_definition_id) REFERENCES public.attribute_definitions(project_id, id) ON DELETE CASCADE;


--
-- Name: document_attribute_values fk_document_attribute_values_document; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_attribute_values
    ADD CONSTRAINT fk_document_attribute_values_document FOREIGN KEY (project_id, document_id) REFERENCES public.documents(project_id, id) ON DELETE CASCADE;


--
-- Name: document_attribute_values fk_document_attribute_values_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_attribute_values
    ADD CONSTRAINT fk_document_attribute_values_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: document_files fk_document_files_document_version; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_files
    ADD CONSTRAINT fk_document_files_document_version FOREIGN KEY (project_id, document_version_id) REFERENCES public.document_versions(project_id, id) ON DELETE CASCADE;


--
-- Name: document_files fk_document_files_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_files
    ADD CONSTRAINT fk_document_files_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: document_type_attributes fk_document_type_attributes_attribute; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_type_attributes
    ADD CONSTRAINT fk_document_type_attributes_attribute FOREIGN KEY (project_id, attribute_definition_id) REFERENCES public.attribute_definitions(project_id, id) ON DELETE CASCADE;


--
-- Name: document_type_attributes fk_document_type_attributes_document_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_type_attributes
    ADD CONSTRAINT fk_document_type_attributes_document_type FOREIGN KEY (project_id, document_type_id) REFERENCES public.document_types(project_id, id) ON DELETE CASCADE;


--
-- Name: document_type_attributes fk_document_type_attributes_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_type_attributes
    ADD CONSTRAINT fk_document_type_attributes_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: document_types fk_document_types_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_types
    ADD CONSTRAINT fk_document_types_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: document_versions fk_document_versions_document; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT fk_document_versions_document FOREIGN KEY (project_id, document_id) REFERENCES public.documents(project_id, id) ON DELETE CASCADE;


--
-- Name: document_versions fk_document_versions_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT fk_document_versions_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: documents fk_documents_document_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT fk_documents_document_type FOREIGN KEY (project_id, document_type_id) REFERENCES public.document_types(project_id, id) ON DELETE SET NULL;


--
-- Name: documents fk_documents_node; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT fk_documents_node FOREIGN KEY (project_id, node_id) REFERENCES public.hierarchy_nodes(project_id, id) ON DELETE SET NULL;


--
-- Name: documents fk_documents_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT fk_documents_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: hierarchy_node_types fk_hierarchy_node_types_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_node_types
    ADD CONSTRAINT fk_hierarchy_node_types_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: hierarchy_nodes fk_hierarchy_nodes_node_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT fk_hierarchy_nodes_node_type FOREIGN KEY (project_id, node_type_id) REFERENCES public.hierarchy_node_types(project_id, id) ON DELETE RESTRICT;


--
-- Name: hierarchy_nodes fk_hierarchy_nodes_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT fk_hierarchy_nodes_parent FOREIGN KEY (project_id, parent_id) REFERENCES public.hierarchy_nodes(project_id, id) ON DELETE RESTRICT;


--
-- Name: hierarchy_nodes fk_hierarchy_nodes_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_nodes
    ADD CONSTRAINT fk_hierarchy_nodes_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: hierarchy_type_rules fk_hierarchy_type_rules_child_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_type_rules
    ADD CONSTRAINT fk_hierarchy_type_rules_child_type FOREIGN KEY (project_id, child_node_type_id) REFERENCES public.hierarchy_node_types(project_id, id) ON DELETE CASCADE;


--
-- Name: hierarchy_type_rules fk_hierarchy_type_rules_parent_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_type_rules
    ADD CONSTRAINT fk_hierarchy_type_rules_parent_type FOREIGN KEY (project_id, parent_node_type_id) REFERENCES public.hierarchy_node_types(project_id, id) ON DELETE CASCADE;


--
-- Name: hierarchy_type_rules fk_hierarchy_type_rules_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hierarchy_type_rules
    ADD CONSTRAINT fk_hierarchy_type_rules_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: node_attribute_values fk_node_attribute_values_attribute; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_attribute_values
    ADD CONSTRAINT fk_node_attribute_values_attribute FOREIGN KEY (project_id, attribute_definition_id) REFERENCES public.attribute_definitions(project_id, id) ON DELETE CASCADE;


--
-- Name: node_attribute_values fk_node_attribute_values_node; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_attribute_values
    ADD CONSTRAINT fk_node_attribute_values_node FOREIGN KEY (project_id, node_id) REFERENCES public.hierarchy_nodes(project_id, id) ON DELETE CASCADE;


--
-- Name: node_attribute_values fk_node_attribute_values_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_attribute_values
    ADD CONSTRAINT fk_node_attribute_values_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: node_type_attributes fk_node_type_attributes_attribute; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_type_attributes
    ADD CONSTRAINT fk_node_type_attributes_attribute FOREIGN KEY (project_id, attribute_definition_id) REFERENCES public.attribute_definitions(project_id, id) ON DELETE CASCADE;


--
-- Name: node_type_attributes fk_node_type_attributes_node_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_type_attributes
    ADD CONSTRAINT fk_node_type_attributes_node_type FOREIGN KEY (project_id, node_type_id) REFERENCES public.hierarchy_node_types(project_id, id) ON DELETE CASCADE;


--
-- Name: node_type_attributes fk_node_type_attributes_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_type_attributes
    ADD CONSTRAINT fk_node_type_attributes_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_memberships fk_project_memberships_profile; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT fk_project_memberships_profile FOREIGN KEY (project_id, profile_id) REFERENCES public.project_profiles(project_id, id) ON DELETE RESTRICT;


--
-- Name: project_memberships fk_project_memberships_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT fk_project_memberships_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_memberships fk_project_memberships_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT fk_project_memberships_user FOREIGN KEY (user_id) REFERENCES public.app_users(id) ON DELETE CASCADE;


--
-- Name: project_profile_permissions fk_project_profile_permissions_permission; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profile_permissions
    ADD CONSTRAINT fk_project_profile_permissions_permission FOREIGN KEY (permission_code) REFERENCES public.permission_catalog(code) ON DELETE RESTRICT;


--
-- Name: project_profile_permissions fk_project_profile_permissions_profile; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profile_permissions
    ADD CONSTRAINT fk_project_profile_permissions_profile FOREIGN KEY (project_id, profile_id) REFERENCES public.project_profiles(project_id, id) ON DELETE CASCADE;


--
-- Name: project_profile_permissions fk_project_profile_permissions_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profile_permissions
    ADD CONSTRAINT fk_project_profile_permissions_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_profiles fk_project_profiles_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_profiles
    ADD CONSTRAINT fk_project_profiles_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict SftWkUb67xIrigOyJcimirhkZfklCHSzfoaEIOvMxaUZjhHYHCGbWlQUF5vLAvA

