import 'package:flutter/material.dart';

import '../domain/scan_source.dart';
import '../domain/scanner_device.dart';
import '../domain/windows_twain_service_status.dart';
import 'scan_document_selected_scanner_details.dart';

class ScanDocumentConfigurationFields extends StatelessWidget {
  const ScanDocumentConfigurationFields({
    required this.source,
    required this.scanners,
    required this.selectedScanner,
    required this.isBusy,
    required this.canUseAdf,
    required this.canScanFlatbed,
    required this.canScanSimplex,
    required this.canScanDuplex,
    required this.duplex,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
    required this.serviceStatus,
    required this.onSourceChanged,
    required this.onScannerChanged,
    required this.onDuplexChanged,
    required this.onDpiChanged,
    required this.onPixelTypeChanged,
    required this.onDiscardBlankPagesChanged,
    super.key,
  });

  static const _dpiOptions = [200, 300, 400];
  static const _pixelTypes = ['color', 'gray', 'bw'];
  static const _blankModes = ['auto', 'off'];

  final ScanSource source;
  final List<ScannerDevice> scanners;
  final ScannerDevice? selectedScanner;
  final bool isBusy;
  final bool canUseAdf;
  final bool canScanFlatbed;
  final bool canScanSimplex;
  final bool canScanDuplex;
  final bool duplex;
  final int dpi;
  final String pixelType;
  final String discardBlankPages;
  final WindowsTwainServiceStatus? serviceStatus;
  final ValueChanged<ScanSource> onSourceChanged;
  final ValueChanged<ScannerDevice?> onScannerChanged;
  final ValueChanged<bool> onDuplexChanged;
  final ValueChanged<int> onDpiChanged;
  final ValueChanged<String> onPixelTypeChanged;
  final ValueChanged<String> onDiscardBlankPagesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ScanSource>(
          segments: [
            ButtonSegment<ScanSource>(
              value: ScanSource.adf,
              label: const Text('ADF'),
              icon: const Icon(Icons.feed_outlined),
              enabled: canUseAdf,
            ),
            ButtonSegment<ScanSource>(
              value: ScanSource.flatbed,
              label: const Text('Cama plana'),
              icon: const Icon(Icons.crop_portrait_outlined),
              enabled: canScanFlatbed,
            ),
          ],
          selected: {source},
          onSelectionChanged: isBusy
              ? null
              : (selection) => onSourceChanged(selection.first),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<ScannerDevice>(
          key: ValueKey(selectedScanner?.name),
          initialValue: selectedScanner,
          decoration: const InputDecoration(labelText: 'Escaner'),
          items: scanners
              .map(
                (scanner) => DropdownMenuItem<ScannerDevice>(
                  value: scanner,
                  child: Text(scanner.displayLabel),
                ),
              )
              .toList(growable: false),
          onChanged: isBusy ? null : onScannerChanged,
        ),
        if (selectedScanner != null) ...[
          const SizedBox(height: 8),
          ScanDocumentSelectedScannerDetails(scanner: selectedScanner!),
        ],
        const SizedBox(height: 14),
        if (source == ScanSource.adf) ...[
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: false,
                label: Text('Simplex'),
                icon: Icon(Icons.filter_1),
                enabled: canScanSimplex,
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Duplex'),
                icon: Icon(Icons.filter_2),
                enabled: canScanDuplex,
              ),
            ],
            selected: {duplex},
            onSelectionChanged: isBusy
                ? null
                : (selection) => onDuplexChanged(selection.first),
          ),
          if (serviceStatus != null &&
              serviceStatus!.operations.isNotEmpty &&
              !serviceStatus!.supportsOperation('scan-adf-duplex')) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'El host actual no publica soporte para escaneo duplex.',
              ),
            ),
          ],
          const SizedBox(height: 14),
        ] else ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Cama plana captura una sola pagina por disparo y no usa duplex.',
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (scanners.isEmpty && !isBusy)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No hay escaneres detectados. Verifica drivers TWAIN, '
              'ADF cargado y arquitectura compatible.',
            ),
          ),
        if (scanners.isEmpty && !isBusy) const SizedBox(height: 14),
        if (scanners.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Escaneres detectados: ${scanners.length}'),
          ),
        if (scanners.isNotEmpty) const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          key: ValueKey(dpi),
          initialValue: dpi,
          decoration: const InputDecoration(labelText: 'DPI'),
          items: _dpiOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value dpi'),
                ),
              )
              .toList(growable: false),
          onChanged: isBusy
              ? null
              : (value) {
                  if (value != null) {
                    onDpiChanged(value);
                  }
                },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey(pixelType),
          initialValue: pixelType,
          decoration: const InputDecoration(labelText: 'Modo de color'),
          items: _pixelTypes
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(_pixelTypeLabel(value)),
                ),
              )
              .toList(growable: false),
          onChanged: isBusy
              ? null
              : (value) {
                  if (value != null) {
                    onPixelTypeChanged(value);
                  }
                },
        ),
        const SizedBox(height: 14),
        if (source == ScanSource.adf)
          DropdownButtonFormField<String>(
            key: ValueKey(discardBlankPages),
            initialValue: discardBlankPages,
            decoration: const InputDecoration(labelText: 'Paginas en blanco'),
            items: _blankModes
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'auto'
                          ? 'Descartar automaticamente'
                          : 'Conservar todas',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isBusy
                ? null
                : (value) {
                    if (value != null) {
                      onDiscardBlankPagesChanged(value);
                    }
                  },
          ),
      ],
    );
  }

  String _pixelTypeLabel(String value) => switch (value) {
    'gray' => 'Escala de grises',
    'bw' => 'Blanco y negro',
    _ => 'Color',
  };
}
