BEGIN;

ALTER TABLE attribute_definitions
    ADD COLUMN IF NOT EXISTS type_extension integer NULL,
    ADD COLUMN IF NOT EXISTS validation_regex text NULL,
    ADD COLUMN IF NOT EXISTS validation_message text NULL,
    ADD COLUMN IF NOT EXISTS settings_json jsonb NOT NULL DEFAULT '{}'::jsonb;

UPDATE attribute_definitions
SET data_type = 'string'
WHERE data_type = 'text';

UPDATE attribute_definitions
SET data_type = 'decimal'
WHERE data_type = 'number';

ALTER TABLE attribute_definitions
    DROP CONSTRAINT IF EXISTS ck_attribute_definitions_data_type;

ALTER TABLE attribute_definitions
    ADD CONSTRAINT ck_attribute_definitions_data_type
    CHECK (data_type IN ('string', 'integer', 'decimal', 'date', 'boolean', 'list', 'json'));

CREATE TABLE IF NOT EXISTS attribute_options (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    attribute_definition_id uuid NOT NULL,
    code varchar(80) NOT NULL,
    label varchar(160) NOT NULL,
    sort_order integer NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_attribute_options_project
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_attribute_options_attribute
        FOREIGN KEY (project_id, attribute_definition_id)
        REFERENCES attribute_definitions(project_id, id)
        ON DELETE CASCADE,
    CONSTRAINT uq_attribute_options_project_id
        UNIQUE (project_id, id),
    CONSTRAINT uq_attribute_options_code
        UNIQUE (project_id, attribute_definition_id, code)
);

CREATE INDEX IF NOT EXISTS idx_attribute_definitions_project_scope_active
    ON attribute_definitions (project_id, scope, is_active, name);

CREATE INDEX IF NOT EXISTS idx_attribute_options_project_attribute
    ON attribute_options (project_id, attribute_definition_id, sort_order, label);

CREATE INDEX IF NOT EXISTS idx_node_attribute_values_attribute_text
    ON node_attribute_values (project_id, attribute_definition_id, value_text)
    WHERE value_text IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_node_attribute_values_attribute_number
    ON node_attribute_values (project_id, attribute_definition_id, value_number)
    WHERE value_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_node_attribute_values_attribute_date
    ON node_attribute_values (project_id, attribute_definition_id, value_date)
    WHERE value_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_document_attribute_values_attribute_text
    ON document_attribute_values (project_id, attribute_definition_id, value_text)
    WHERE value_text IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_document_attribute_values_attribute_number
    ON document_attribute_values (project_id, attribute_definition_id, value_number)
    WHERE value_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_document_attribute_values_attribute_date
    ON document_attribute_values (project_id, attribute_definition_id, value_date)
    WHERE value_date IS NOT NULL;

CREATE OR REPLACE FUNCTION validate_attribute_definition()
RETURNS trigger
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

CREATE OR REPLACE FUNCTION validate_attribute_option()
RETURNS trigger
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

CREATE OR REPLACE FUNCTION validate_node_type_attribute()
RETURNS trigger
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

CREATE OR REPLACE FUNCTION validate_document_type_attribute()
RETURNS trigger
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

CREATE OR REPLACE FUNCTION validate_dynamic_attribute_value(
    p_project_id uuid,
    p_attribute_definition_id uuid,
    p_data_type varchar,
    p_type_extension integer,
    p_validation_regex text,
    p_value_text text,
    p_value_number numeric,
    p_value_date date,
    p_value_boolean boolean,
    p_value_json jsonb
)
RETURNS void
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

CREATE OR REPLACE FUNCTION validate_node_attribute_value()
RETURNS trigger
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

CREATE OR REPLACE FUNCTION validate_document_attribute_value()
RETURNS trigger
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

DROP TRIGGER IF EXISTS trg_attribute_definitions_validate_before_write ON attribute_definitions;
CREATE TRIGGER trg_attribute_definitions_validate_before_write
BEFORE INSERT OR UPDATE OF data_type, type_extension, validation_regex, settings_json
ON attribute_definitions
FOR EACH ROW
EXECUTE FUNCTION validate_attribute_definition();

DROP TRIGGER IF EXISTS trg_attribute_options_updated_at ON attribute_options;
CREATE TRIGGER trg_attribute_options_updated_at
BEFORE UPDATE ON attribute_options
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_attribute_options_validate_before_write ON attribute_options;
CREATE TRIGGER trg_attribute_options_validate_before_write
BEFORE INSERT OR UPDATE OF attribute_definition_id, project_id, code, label
ON attribute_options
FOR EACH ROW
EXECUTE FUNCTION validate_attribute_option();

DROP TRIGGER IF EXISTS trg_node_type_attributes_validate_before_write ON node_type_attributes;
CREATE TRIGGER trg_node_type_attributes_validate_before_write
BEFORE INSERT OR UPDATE OF attribute_definition_id, project_id
ON node_type_attributes
FOR EACH ROW
EXECUTE FUNCTION validate_node_type_attribute();

DROP TRIGGER IF EXISTS trg_document_type_attributes_validate_before_write ON document_type_attributes;
CREATE TRIGGER trg_document_type_attributes_validate_before_write
BEFORE INSERT OR UPDATE OF attribute_definition_id, project_id
ON document_type_attributes
FOR EACH ROW
EXECUTE FUNCTION validate_document_type_attribute();

DROP TRIGGER IF EXISTS trg_node_attribute_values_validate_before_write ON node_attribute_values;
CREATE TRIGGER trg_node_attribute_values_validate_before_write
BEFORE INSERT OR UPDATE OF project_id, node_id, attribute_definition_id, value_text, value_number, value_date, value_boolean, value_json
ON node_attribute_values
FOR EACH ROW
EXECUTE FUNCTION validate_node_attribute_value();

DROP TRIGGER IF EXISTS trg_document_attribute_values_validate_before_write ON document_attribute_values;
CREATE TRIGGER trg_document_attribute_values_validate_before_write
BEFORE INSERT OR UPDATE OF project_id, document_id, attribute_definition_id, value_text, value_number, value_date, value_boolean, value_json
ON document_attribute_values
FOR EACH ROW
EXECUTE FUNCTION validate_document_attribute_value();

INSERT INTO schema_migrations (version, name, checksum)
VALUES (
    'V202603151730',
    'extend_dynamic_attributes_v2',
    'sha256:pending'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
