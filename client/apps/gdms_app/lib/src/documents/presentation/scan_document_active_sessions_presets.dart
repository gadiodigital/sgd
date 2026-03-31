import 'package:flutter/material.dart';

import 'scan_document_active_sessions_preset.dart';
import 'scan_document_active_sessions_preset_support.dart';

class ScanDocumentActiveSessionsPresets extends StatelessWidget {
  const ScanDocumentActiveSessionsPresets({
    required this.presetAvailabilities,
    required this.recommendedPreset,
    required this.selectedPreset,
    required this.isBusy,
    required this.onPresetSelected,
    super.key,
  });

  final List<ScanDocumentActiveSessionsPresetAvailability> presetAvailabilities;
  final ScanDocumentActiveSessionsPresetRecommendation? recommendedPreset;
  final ScanDocumentActiveSessionsPreset? selectedPreset;
  final bool isBusy;
  final ValueChanged<ScanDocumentActiveSessionsPresetConfig> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final shouldShowRecommendation =
        recommendedPreset != null &&
        selectedPreset != recommendedPreset!.availability.preset.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldShowRecommendation)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Chip(
                  label: Text('Sugerido'),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '${recommendedPreset!.availability.preset.label} (${recommendedPreset!.availability.matchCount}) · ${recommendedPreset!.reason}',
                ),
                FilledButton.tonal(
                  onPressed: isBusy
                      ? null
                      : () => onPresetSelected(recommendedPreset!.availability.preset),
                  child: const Text('Usar sugerido'),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetAvailabilities
              .map(
                (availability) => Tooltip(
                  message: availability.hasMatches
                      ? '${availability.matchCount} sesiones para ${availability.preset.label.toLowerCase()}'
                      : 'Sin sesiones para ${availability.preset.label.toLowerCase()}',
                  child: ChoiceChip(
                    label: Text(
                      '${availability.preset.label} (${availability.matchCount})',
                    ),
                    selected: selectedPreset == availability.preset.id,
                    onSelected: isBusy || !availability.hasMatches
                        ? null
                        : (_) => onPresetSelected(availability.preset),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
