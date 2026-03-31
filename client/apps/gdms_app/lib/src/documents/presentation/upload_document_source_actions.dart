import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadDocumentSourceActions extends StatelessWidget {
  const UploadDocumentSourceActions({
    required this.selectedFile,
    required this.isBusy,
    required this.supportsScannerIntegration,
    required this.onPickFile,
    required this.onScanDocument,
    super.key,
  });

  final PlatformFile? selectedFile;
  final bool isBusy;
  final bool supportsScannerIntegration;
  final Future<void> Function() onPickFile;
  final Future<void> Function() onScanDocument;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: isBusy ? null : onPickFile,
          icon: const Icon(Icons.attach_file),
          label: Text(
            selectedFile == null ? 'Seleccionar archivo' : selectedFile!.name,
          ),
        ),
        if (supportsScannerIntegration)
          OutlinedButton.icon(
            onPressed: isBusy ? null : onScanDocument,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Escanear documento'),
          ),
      ],
    );
  }
}
