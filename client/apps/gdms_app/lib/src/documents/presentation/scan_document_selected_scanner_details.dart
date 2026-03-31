import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/scanner_device.dart';

class ScanDocumentSelectedScannerDetails extends StatelessWidget {
  const ScanDocumentSelectedScannerDetails({required this.scanner, super.key});

  final ScannerDevice scanner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GdmsStatusBadge(
              label: scanner.sourceIdLabel,
              tone: GdmsStatusTone.info,
            ),
            GdmsStatusBadge(
              label: scanner.manufacturer.isEmpty
                  ? 'Fabricante sin dato'
                  : scanner.manufacturer,
              tone: GdmsStatusTone.info,
            ),
            GdmsStatusBadge(
              label: scanner.productFamily.isEmpty
                  ? 'Familia sin dato'
                  : scanner.productFamily,
              tone: GdmsStatusTone.info,
            ),
            GdmsStatusBadge(
              label: scanner.twainVersion.isEmpty
                  ? 'TWAIN sin dato'
                  : 'TWAIN ${scanner.twainVersion}',
              tone: scanner.hasTwainMetadata
                  ? GdmsStatusTone.info
                  : GdmsStatusTone.warning,
            ),
            GdmsStatusBadge(
              label: scanner.sourceStatusLabel,
              tone: scanner.isOpen
                  ? GdmsStatusTone.warning
                  : GdmsStatusTone.info,
            ),
            GdmsStatusBadge(
              label: scanner.compatibilityLabel,
              tone: scanner.hasTwainMetadata
                  ? GdmsStatusTone.info
                  : GdmsStatusTone.warning,
            ),
          ],
        ),
        if (_advice != null) ...[const SizedBox(height: 8), Text(_advice!)],
      ],
    );
  }

  String? get _advice {
    if (scanner.isOpen) {
      return 'El source aparece abierto. Cierra otras aplicaciones de escaneo antes de capturar.';
    }
    if (!scanner.hasTwainMetadata) {
      return 'Faltan metadatos TWAIN. Conviene revisar o reinstalar el driver del escaner.';
    }
    return null;
  }
}
