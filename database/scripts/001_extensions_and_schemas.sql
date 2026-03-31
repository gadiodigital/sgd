CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS identity;
CREATE SCHEMA IF NOT EXISTS configuration;
CREATE SCHEMA IF NOT EXISTS documents;
CREATE SCHEMA IF NOT EXISTS records;
CREATE SCHEMA IF NOT EXISTS audit;

COMMENT ON SCHEMA platform IS 'Objetos base de plataforma y multi-tenant.';
COMMENT ON SCHEMA identity IS 'Identidad, usuarios, roles y asignaciones.';
COMMENT ON SCHEMA configuration IS 'Catálogos, tipos documentales y configuración relacional.';
COMMENT ON SCHEMA documents IS 'Documentos, versiones y metadatos estructurales.';
COMMENT ON SCHEMA records IS 'Retención, disposición y legal holds.';
COMMENT ON SCHEMA audit IS 'Auditoría inmutable y trazabilidad de eventos.';
