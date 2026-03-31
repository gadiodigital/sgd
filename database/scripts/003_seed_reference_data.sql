INSERT INTO identity.roles (code, name, description)
VALUES
    ('PLATFORM_ADMIN', 'Platform Administrator', 'Administrador global de la plataforma.'),
    ('TENANT_ADMIN', 'Tenant Administrator', 'Administrador funcional de tenant.'),
    ('COMPLIANCE_OFFICER', 'Compliance Officer', 'Responsable de cumplimiento y retención.'),
    ('DOCUMENT_OPERATOR', 'Document Operator', 'Operador documental diario.'),
    ('AUDITOR', 'Auditor', 'Perfil de consulta y revisión auditora.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO configuration.document_types (tenant_id, code, name, sector)
VALUES
    (NULL, 'CONTRACT', 'Contrato', 'CORPORATE'),
    (NULL, 'PROPERTY_DOSSIER', 'Legajo de Inmueble', 'REAL_ESTATE'),
    (NULL, 'CASE_FILE', 'Expediente Jurídico', 'LEGAL'),
    (NULL, 'INVOICE', 'Comprobante', 'CORPORATE')
ON CONFLICT (tenant_id, code) DO NOTHING;

INSERT INTO records.retention_policies (tenant_id, code, name, retention_days, disposition_action)
VALUES
    (NULL, 'CONTRACT_10Y', 'Retención contractual 10 años', 3650, 'ARCHIVE'),
    (NULL, 'CORPORATE_SUPPORT_10Y', 'Respaldo societario y contable 10 años', 3650, 'ARCHIVE'),
    (NULL, 'HR_5Y', 'Documentación operativa de RR.HH. 5 años', 1825, 'REVIEW'),
    (NULL, 'LEGAL_HOLD_DEFAULT', 'Bloqueo legal por revisión', 3650, 'REVIEW')
ON CONFLICT (tenant_id, code) DO NOTHING;
