import 'package:flutter/material.dart';

/// Renders the primary actions available in the document details dialog.
class DocumentDetailsActionsBar extends StatelessWidget {
  const DocumentDetailsActionsBar({
    required this.isBusy,
    required this.hasMetadataFields,
    required this.isEditing,
    required this.supportsScannerIntegration,
    required this.onDownloadRequested,
    required this.onVersionUploadRequested,
    required this.onScanVersionRequested,
    required this.onEvidenceExportRequested,
    required this.onLinkToCaseRequested,
    required this.onManageAccessRequested,
    required this.onEditToggleRequested,
    super.key,
  });

  final bool isBusy;
  final bool hasMetadataFields;
  final bool isEditing;
  final bool supportsScannerIntegration;
  final Future<void> Function() onDownloadRequested;
  final Future<void> Function() onVersionUploadRequested;
  final Future<void> Function() onScanVersionRequested;
  final Future<void> Function() onEvidenceExportRequested;
  final Future<void> Function() onLinkToCaseRequested;
  final Future<void> Function() onManageAccessRequested;
  final VoidCallback onEditToggleRequested;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : onDownloadRequested,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: const Text('Descargar binario'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onVersionUploadRequested,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Nueva versión'),
          ),
          if (supportsScannerIntegration)
            OutlinedButton.icon(
              onPressed: isBusy ? null : onScanVersionRequested,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Escanear versión'),
            ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onEvidenceExportRequested,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Exportar evidencia'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onLinkToCaseRequested,
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Vincular a expediente'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onManageAccessRequested,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Permisos'),
          ),
          if (hasMetadataFields)
            OutlinedButton.icon(
              onPressed: isBusy ? null : onEditToggleRequested,
              icon: Icon(isEditing ? Icons.close : Icons.edit),
              label: Text(isEditing ? 'Cancelar edición' : 'Editar metadatos'),
            ),
        ],
      ),
    );
  }
}
