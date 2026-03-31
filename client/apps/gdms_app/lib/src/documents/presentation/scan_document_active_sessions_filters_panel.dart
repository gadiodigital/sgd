import 'package:flutter/material.dart';

import 'scan_document_active_sessions_activity_filters.dart';
import 'scan_document_active_sessions_labels.dart';
import 'scan_document_active_sessions_page_volume_filters.dart';
import 'scan_document_active_sessions_preset.dart';
import 'scan_document_active_sessions_presets.dart';
import 'scan_document_active_sessions_preset_support.dart';
import 'scan_document_active_sessions_status_filters.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionsFiltersPanel extends StatelessWidget {
  const ScanDocumentActiveSessionsFiltersPanel({
    required this.isBusy,
    required this.query,
    required this.onQueryChanged,
    required this.presetAvailabilities,
    required this.recommendedPreset,
    required this.selectedPreset,
    required this.isCustomState,
    required this.onResetRequested,
    required this.onPresetSelected,
    required this.filter,
    required this.onFilterChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.pageVolumeFilter,
    required this.onPageVolumeFilterChanged,
    required this.activityFilter,
    required this.onActivityFilterChanged,
    required this.scannerOptions,
    required this.selectedScanner,
    required this.onScannerChanged,
    required this.sort,
    required this.onSortChanged,
    super.key,
  });

  final bool isBusy;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<ScanDocumentActiveSessionsPresetAvailability> presetAvailabilities;
  final ScanDocumentActiveSessionsPresetRecommendation? recommendedPreset;
  final ScanDocumentActiveSessionsPreset? selectedPreset;
  final bool isCustomState;
  final VoidCallback onResetRequested;
  final ValueChanged<ScanDocumentActiveSessionsPresetConfig> onPresetSelected;
  final ScanDocumentSessionFilter filter;
  final ValueChanged<ScanDocumentSessionFilter> onFilterChanged;
  final ScanDocumentSessionStatusFilter statusFilter;
  final ValueChanged<ScanDocumentSessionStatusFilter> onStatusFilterChanged;
  final ScanDocumentSessionPageVolumeFilter pageVolumeFilter;
  final ValueChanged<ScanDocumentSessionPageVolumeFilter> onPageVolumeFilterChanged;
  final ScanDocumentSessionActivityFilter activityFilter;
  final ValueChanged<ScanDocumentSessionActivityFilter> onActivityFilterChanged;
  final List<String> scannerOptions;
  final String selectedScanner;
  final ValueChanged<String> onScannerChanged;
  final ScanDocumentSessionSort sort;
  final ValueChanged<ScanDocumentSessionSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final activePreset = ScanDocumentActiveSessionsPresetCatalog.findById(
      selectedPreset,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          enabled: !isBusy,
          controller: TextEditingController(text: query)
            ..selection = TextSelection.collapsed(offset: query.length),
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar por scanner, sesion, modo o estado',
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 8),
        ScanDocumentActiveSessionsPresets(
          presetAvailabilities: presetAvailabilities,
          recommendedPreset: recommendedPreset,
          selectedPreset: selectedPreset,
          isBusy: isBusy,
          onPresetSelected: onPresetSelected,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (activePreset != null)
              Chip(
                label: Text('Preset: ${activePreset.label}'),
                visualDensity: VisualDensity.compact,
              )
            else if (isCustomState)
              const Chip(
                label: Text('Vista personalizada'),
                visualDensity: VisualDensity.compact,
              ),
            if (activePreset != null)
              Text(activePreset.description)
            else if (isCustomState)
              const Text('Combinacion manual de filtros'),
            if (isCustomState || activePreset != null || query.isNotEmpty)
              TextButton(
                onPressed: isBusy ? null : onResetRequested,
                child: const Text('Vista general'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ScanDocumentSessionFilter.values
              .map(
                (item) => ChoiceChip(
                  label: Text(
                    ScanDocumentActiveSessionsLabels.filterLabel(item),
                  ),
                  selected: filter == item,
                  onSelected: isBusy ? null : (_) => onFilterChanged(item),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        ScanDocumentActiveSessionsStatusFilters(
          selectedFilter: statusFilter,
          isBusy: isBusy,
          onFilterChanged: onStatusFilterChanged,
        ),
        const SizedBox(height: 8),
        ScanDocumentActiveSessionsPageVolumeFilters(
          selectedFilter: pageVolumeFilter,
          isBusy: isBusy,
          onFilterChanged: onPageVolumeFilterChanged,
        ),
        const SizedBox(height: 8),
        ScanDocumentActiveSessionsActivityFilters(
          selectedFilter: activityFilter,
          isBusy: isBusy,
          onFilterChanged: onActivityFilterChanged,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButtonFormField<String>(
            initialValue: scannerOptions.contains(selectedScanner)
                ? selectedScanner
                : '',
            key: ValueKey(selectedScanner),
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Scanner',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todos los scanners'),
              ),
              ...scannerOptions.map(
                (scanner) => DropdownMenuItem(
                  value: scanner,
                  child: Text(scanner),
                ),
              ),
            ],
            onChanged: isBusy ? null : (value) => onScannerChanged(value ?? ''),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButtonFormField<ScanDocumentSessionSort>(
            initialValue: sort,
            key: ValueKey(sort),
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Orden',
              isDense: true,
            ),
            items: ScanDocumentSessionSort.values
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      ScanDocumentActiveSessionsLabels.sortLabel(item),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isBusy
                ? null
                : (value) {
                    if (value != null) {
                      onSortChanged(value);
                    }
                  },
          ),
        ),
      ],
    );
  }
}
