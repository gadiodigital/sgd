import 'package:flutter/material.dart';

import 'scan_document_active_sessions_labels.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionsStatusFilters extends StatelessWidget {
  const ScanDocumentActiveSessionsStatusFilters({
    required this.selectedFilter,
    required this.isBusy,
    required this.onFilterChanged,
    super.key,
  });

  final ScanDocumentSessionStatusFilter selectedFilter;
  final bool isBusy;
  final ValueChanged<ScanDocumentSessionStatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScanDocumentSessionStatusFilter.values
          .map(
            (filter) => ChoiceChip(
              label: Text(ScanDocumentActiveSessionsLabels.statusFilterLabel(filter)),
              selected: selectedFilter == filter,
              onSelected: isBusy ? null : (_) => onFilterChanged(filter),
            ),
          )
          .toList(growable: false),
    );
  }
}
