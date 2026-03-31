import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ScanDocumentReadinessChecklist extends StatelessWidget {
  const ScanDocumentReadinessChecklist({
    required this.sourceLabel,
    required this.serviceAvailable,
    required this.hasScanners,
    required this.hasSelectedScanner,
    required this.modeSupported,
    super.key,
  });

  final String sourceLabel;
  final bool serviceAvailable;
  final bool hasScanners;
  final bool hasSelectedScanner;
  final bool modeSupported;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Checklist previa',
      subtitle:
          'Antes de escanear, confirma estos cuatro puntos para $sourceLabel.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _item(serviceAvailable, 'Servicio local'),
          _item(hasScanners, 'Scanner detectado'),
          _item(hasSelectedScanner, 'Scanner seleccionado'),
          _item(modeSupported, 'Modo compatible'),
        ],
      ),
    );
  }

  GdmsStatusBadge _item(bool ok, String label) {
    return GdmsStatusBadge(
      label: ok ? '$label OK' : '$label pendiente',
      tone: ok ? GdmsStatusTone.info : GdmsStatusTone.warning,
    );
  }
}
