import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../domain/document_type_catalog_entry.dart';
import 'document_metadata_fields_section.dart';
import 'upload_document_source_actions.dart';

class UploadDocumentFormSection extends StatelessWidget {
  const UploadDocumentFormSection({
    required this.formKey,
    required this.documentTypes,
    required this.selectedDocumentTypeCode,
    required this.selectedDocumentType,
    required this.titleController,
    required this.metadataControllers,
    required this.booleanMetadataValues,
    required this.selectedFile,
    required this.isBusy,
    required this.supportsScannerIntegration,
    required this.onDocumentTypeChanged,
    required this.onBooleanChanged,
    required this.onPickFile,
    required this.onScanDocument,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final List<DocumentTypeCatalogEntry> documentTypes;
  final String? selectedDocumentTypeCode;
  final DocumentTypeCatalogEntry? selectedDocumentType;
  final TextEditingController titleController;
  final Map<String, TextEditingController> metadataControllers;
  final Map<String, String?> booleanMetadataValues;
  final PlatformFile? selectedFile;
  final bool isBusy;
  final bool supportsScannerIntegration;
  final ValueChanged<String?> onDocumentTypeChanged;
  final void Function(String key, String? value) onBooleanChanged;
  final Future<void> Function() onPickFile;
  final Future<void> Function() onScanDocument;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(selectedDocumentTypeCode),
            initialValue: selectedDocumentTypeCode,
            decoration: const InputDecoration(labelText: 'Tipo documental'),
            items: documentTypes
                .map(
                  (documentType) => DropdownMenuItem<String>(
                    value: documentType.code,
                    child: Text(documentType.displayLabel),
                  ),
                )
                .toList(growable: false),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Selecciona el tipo documental.';
              }
              return null;
            },
            onChanged: isBusy ? null : onDocumentTypeChanged,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Titulo',
              hintText: 'Opcional, usa el nombre del archivo si queda vacio',
            ),
          ),
          const SizedBox(height: 14),
          if (selectedDocumentType != null &&
              selectedDocumentType!.metadataFields.isNotEmpty)
            DocumentMetadataFieldsSection(
              fields: selectedDocumentType!.metadataFields,
              controllers: metadataControllers,
              booleanValues: booleanMetadataValues,
              onBooleanChanged: onBooleanChanged,
            ),
          UploadDocumentSourceActions(
            selectedFile: selectedFile,
            isBusy: isBusy,
            supportsScannerIntegration: supportsScannerIntegration,
            onPickFile: onPickFile,
            onScanDocument: onScanDocument,
          ),
        ],
      ),
    );
  }
}
