-- Actualizacion manual para bases existentes.
--
-- Ejecutar con psql desde la raiz del repositorio:
--   psql "<connection-string>" -v ON_ERROR_STOP=1 -f database/updates/update_document_structure_hierarchy.sql
--
-- Este archivo delega en la migracion canonica para evitar duplicar DDL.
\set ON_ERROR_STOP on
\echo 'Aplicando estructura documental configurable...'
\ir ../scripts/020_document_structure_hierarchy.sql
\echo 'Estructura documental configurable aplicada.'
