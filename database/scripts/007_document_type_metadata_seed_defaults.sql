UPDATE configuration.document_types
SET metadata_schema = '{
  "counterparty": { "type": "string", "required": true, "maxLength": 160, "label": "Contraparte" },
  "contractNumber": { "type": "string", "required": true, "maxLength": 50, "label": "Numero de contrato" },
  "effectiveDate": { "type": "date", "required": true, "label": "Fecha de vigencia" }
}'::jsonb
WHERE tenant_id IS NULL
  AND code = 'CONTRACT';

UPDATE configuration.document_types
SET metadata_schema = '{
  "propertyCode": { "type": "string", "required": true, "maxLength": 40, "label": "Codigo de inmueble" },
  "cadastralReference": { "type": "string", "required": false, "maxLength": 80, "label": "Referencia catastral" },
  "ownerName": { "type": "string", "required": true, "maxLength": 160, "label": "Titular" }
}'::jsonb
WHERE tenant_id IS NULL
  AND code = 'PROPERTY_DOSSIER';

UPDATE configuration.document_types
SET metadata_schema = '{
  "caseNumber": { "type": "string", "required": true, "maxLength": 50, "label": "Numero de expediente" },
  "jurisdiction": { "type": "string", "required": true, "maxLength": 80, "label": "Jurisdiccion" },
  "leadAttorney": { "type": "string", "required": false, "maxLength": 160, "label": "Abogado responsable" }
}'::jsonb
WHERE tenant_id IS NULL
  AND code = 'CASE_FILE';

UPDATE configuration.document_types
SET metadata_schema = '{
  "invoiceNumber": { "type": "string", "required": true, "maxLength": 50, "label": "Numero de comprobante" },
  "issueDate": { "type": "date", "required": true, "label": "Fecha de emision" },
  "issuerTaxId": { "type": "string", "required": true, "maxLength": 20, "label": "CUIT emisor" }
}'::jsonb
WHERE tenant_id IS NULL
  AND code = 'INVOICE';
