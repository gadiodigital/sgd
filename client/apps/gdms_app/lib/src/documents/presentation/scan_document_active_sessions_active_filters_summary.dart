import 'package:flutter/material.dart';

class ScanDocumentActiveSessionsActiveFiltersSummary extends StatelessWidget {
  const ScanDocumentActiveSessionsActiveFiltersSummary({
    required this.filters,
    this.activePresetLabel,
    this.activePresetDescription,
    this.onFilterRemoved,
    this.onActivePresetRemoved,
    this.onClearAll,
    super.key,
  });

  final List<String> filters;
  final String? activePresetLabel;
  final String? activePresetDescription;
  final ValueChanged<String>? onFilterRemoved;
  final VoidCallback? onActivePresetRemoved;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty && activePresetLabel == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (activePresetLabel != null)
          Tooltip(
            message:
                activePresetDescription == null
                ? 'Preset activo'
                : 'Preset activo: $activePresetDescription',
            child: InputChip(
              label: Text('Preset: $activePresetLabel'),
              visualDensity: VisualDensity.compact,
              onDeleted: onActivePresetRemoved,
            ),
          ),
        ...filters.map(
          (filter) => InputChip(
            label: Text(filter),
            visualDensity: VisualDensity.compact,
            onDeleted: onFilterRemoved == null
                ? null
                : () => onFilterRemoved!(filter),
          ),
        ),
        if (onClearAll != null)
          ActionChip(
            label: const Text('Limpiar todo'),
            visualDensity: VisualDensity.compact,
            onPressed: onClearAll,
          ),
      ],
    );
  }
}
