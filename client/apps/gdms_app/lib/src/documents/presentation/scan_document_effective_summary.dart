import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/scanner_device.dart';
import '../domain/scan_source.dart';

class ScanDocumentEffectiveSummary extends StatelessWidget {
  const ScanDocumentEffectiveSummary({
    required this.selectedScanner,
    required this.source,
    required this.duplex,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
    required this.canScan,
    required this.readinessReason,
    super.key,
  });

  final ScannerDevice? selectedScanner;
  final ScanSource source;
  final bool duplex;
  final int dpi;
  final String pixelType;
  final String discardBlankPages;
  final bool canScan;
  final String readinessReason;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Configuracion efectiva',
      subtitle:
          '${selectedScanner?.displayLabel ?? 'Sin escaner'} · '
          '${source == ScanSource.flatbed ? 'cama plana' : (duplex ? 'duplex' : 'simplex')} · '
          '$dpi dpi',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          GdmsStatusBadge(
            label: canScan ? 'Listo para escanear' : readinessReason,
            tone: canScan ? GdmsStatusTone.info : GdmsStatusTone.critical,
          ),
          GdmsStatusBadge(
            label: _pixelTypeLabel(pixelType),
            tone: GdmsStatusTone.info,
          ),
          GdmsStatusBadge(
            label: source == ScanSource.flatbed
                ? 'Una pagina'
                : (discardBlankPages == 'auto'
                      ? 'Descarta blancas'
                      : 'Conserva blancas'),
            tone: GdmsStatusTone.info,
          ),
        ],
      ),
    );
  }

  String _pixelTypeLabel(String value) {
    switch (value) {
      case 'gray':
        return 'Escala de grises';
      case 'bw':
        return 'Blanco y negro';
      default:
        return 'Color';
    }
  }
}
