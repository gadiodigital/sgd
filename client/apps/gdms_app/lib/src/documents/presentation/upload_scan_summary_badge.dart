import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/scanned_document_file.dart';

class UploadScanSummaryBadge extends StatelessWidget {
  const UploadScanSummaryBadge({required this.scannedFile, super.key});

  final ScannedDocumentFile scannedFile;

  @override
  Widget build(BuildContext context) {
    final scannerName = scannedFile.scannerName.trim().isEmpty
        ? 'scanner local'
        : scannedFile.scannerName.trim();

    return GdmsStatusBadge(
      label:
          'PDF escaneado desde $scannerName con ${scannedFile.pageCount} pagina(s).',
      tone: GdmsStatusTone.info,
    );
  }
}
