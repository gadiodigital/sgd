import 'package:flutter/material.dart';

class ScanDocumentSettingsActions extends StatelessWidget {
  const ScanDocumentSettingsActions({
    required this.isBusy,
    required this.hasSelectedScanner,
    required this.onResetRequested,
    required this.onForgetScannerRequested,
    super.key,
  });

  final bool isBusy;
  final bool hasSelectedScanner;
  final VoidCallback onResetRequested;
  final VoidCallback onForgetScannerRequested;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: isBusy ? null : onResetRequested,
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text('Restaurar defaults'),
        ),
        OutlinedButton.icon(
          onPressed: isBusy || !hasSelectedScanner
              ? null
              : onForgetScannerRequested,
          icon: const Icon(Icons.link_off),
          label: const Text('Olvidar scanner'),
        ),
      ],
    );
  }
}
