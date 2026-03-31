import 'package:flutter/material.dart';

import '../application/document_scan_preset.dart';

class ScanDocumentPresetChips extends StatelessWidget {
  const ScanDocumentPresetChips({
    required this.presets,
    required this.selectedPresetId,
    required this.selectedPreset,
    required this.duplex,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
    required this.isBusy,
    required this.canApplyPreset,
    required this.unavailableReason,
    required this.onPresetSelected,
    super.key,
  });

  final List<DocumentScanPreset> presets;
  final String? selectedPresetId;
  final DocumentScanPreset? selectedPreset;
  final bool duplex;
  final int dpi;
  final String pixelType;
  final String discardBlankPages;
  final bool isBusy;
  final bool Function(DocumentScanPreset preset) canApplyPreset;
  final String? Function(DocumentScanPreset preset) unavailableReason;
  final ValueChanged<DocumentScanPreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets
              .map(
                (preset) => ChoiceChip(
                  label: Text(preset.label),
                  selected: selectedPresetId == preset.id,
                  onSelected: isBusy || !canApplyPreset(preset)
                      ? null
                      : (_) => onPresetSelected(preset),
                ),
              )
              .toList(growable: false),
        ),
        if (_unavailablePresets().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _unavailablePresets()
                .map((entry) => '${entry.$1}: ${entry.$2}')
                .join(' · '),
          ),
        ],
        if (selectedPreset == null && _suggestedPreset() != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sugerido para este host: ${_suggestedPreset()!.label}.',
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isBusy
                    ? null
                    : () => onPresetSelected(_suggestedPreset()!),
                child: const Text('Usar sugerido'),
              ),
            ],
          ),
        ],
        if (selectedPreset != null) ...[
          const SizedBox(height: 8),
          Text(selectedPreset!.description),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Perfil personalizado: ${duplex ? 'duplex' : 'simplex'} · '
            '$dpi dpi · ${_pixelTypeLabel(pixelType)} · '
            '${discardBlankPages == 'auto' ? 'descarta blancas' : 'conserva blancas'}',
          ),
        ],
      ],
    );
  }

  String _pixelTypeLabel(String value) {
    switch (value) {
      case 'gray':
        return 'grises';
      case 'bw':
        return 'B/N';
      default:
        return 'color';
    }
  }

  List<(String, String)> _unavailablePresets() {
    final result = <(String, String)>[];
    for (final preset in presets) {
      final reason = unavailableReason(preset);
      if (reason != null && reason.isNotEmpty) {
        result.add((preset.label, reason));
      }
    }
    return result;
  }

  DocumentScanPreset? _suggestedPreset() {
    for (final preset in presets) {
      if (canApplyPreset(preset) && preset.id != selectedPresetId) {
        return preset;
      }
    }
    return null;
  }
}
