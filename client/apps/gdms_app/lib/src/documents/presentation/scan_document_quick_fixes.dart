import 'package:flutter/material.dart';

class ScanDocumentQuickFixes extends StatelessWidget {
  const ScanDocumentQuickFixes({
    required this.showRefresh,
    required this.showSelectFirstScanner,
    required this.showSwitchToSimplex,
    required this.showSwitchToAdf,
    required this.showSwitchToFlatbed,
    required this.isBusy,
    required this.onRefreshRequested,
    required this.onSelectFirstScannerRequested,
    required this.onSwitchToSimplexRequested,
    required this.onSwitchToAdfRequested,
    required this.onSwitchToFlatbedRequested,
    super.key,
  });

  final bool showRefresh;
  final bool showSelectFirstScanner;
  final bool showSwitchToSimplex;
  final bool showSwitchToAdf;
  final bool showSwitchToFlatbed;
  final bool isBusy;
  final VoidCallback onRefreshRequested;
  final VoidCallback onSelectFirstScannerRequested;
  final VoidCallback onSwitchToSimplexRequested;
  final VoidCallback onSwitchToAdfRequested;
  final VoidCallback onSwitchToFlatbedRequested;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (showRefresh)
        OutlinedButton.icon(
          onPressed: isBusy ? null : onRefreshRequested,
          icon: const Icon(Icons.refresh),
          label: const Text('Redescubrir'),
        ),
      if (showSelectFirstScanner)
        OutlinedButton.icon(
          onPressed: isBusy ? null : onSelectFirstScannerRequested,
          icon: const Icon(Icons.scanner_outlined),
          label: const Text('Usar primero'),
        ),
      if (showSwitchToSimplex)
        OutlinedButton.icon(
          onPressed: isBusy ? null : onSwitchToSimplexRequested,
          icon: const Icon(Icons.filter_1),
          label: const Text('Pasar a simplex'),
        ),
      if (showSwitchToAdf)
        OutlinedButton.icon(
          onPressed: isBusy ? null : onSwitchToAdfRequested,
          icon: const Icon(Icons.feed_outlined),
          label: const Text('Usar ADF'),
        ),
      if (showSwitchToFlatbed)
        OutlinedButton.icon(
          onPressed: isBusy ? null : onSwitchToFlatbedRequested,
          icon: const Icon(Icons.crop_portrait_outlined),
          label: const Text('Usar flatbed'),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 12, children: buttons);
  }
}
