import 'package:flutter/material.dart';

import 'scan_document_active_sessions_labels.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionsPageVolumeFilters extends StatelessWidget {
  const ScanDocumentActiveSessionsPageVolumeFilters({
    required this.selectedFilter,
    required this.isBusy,
    required this.onFilterChanged,
    super.key,
  });

  final ScanDocumentSessionPageVolumeFilter selectedFilter;
  final bool isBusy;
  final ValueChanged<ScanDocumentSessionPageVolumeFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScanDocumentSessionPageVolumeFilter.values
          .map(
            (filter) => ChoiceChip(
              label: Text(
                ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(filter),
              ),
              selected: selectedFilter == filter,
              onSelected: isBusy ? null : (_) => onFilterChanged(filter),
            ),
          )
          .toList(growable: false),
    );
  }
}
