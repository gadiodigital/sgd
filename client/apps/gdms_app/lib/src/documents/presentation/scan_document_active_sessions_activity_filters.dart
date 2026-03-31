import 'package:flutter/material.dart';

import 'scan_document_active_sessions_labels.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionsActivityFilters extends StatelessWidget {
  const ScanDocumentActiveSessionsActivityFilters({
    required this.selectedFilter,
    required this.isBusy,
    required this.onFilterChanged,
    super.key,
  });

  final ScanDocumentSessionActivityFilter selectedFilter;
  final bool isBusy;
  final ValueChanged<ScanDocumentSessionActivityFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScanDocumentSessionActivityFilter.values
          .map(
            (filter) => ChoiceChip(
              label: Text(
                ScanDocumentActiveSessionsLabels.activityFilterLabel(filter),
              ),
              selected: selectedFilter == filter,
              onSelected: isBusy ? null : (_) => onFilterChanged(filter),
            ),
          )
          .toList(growable: false),
    );
  }
}
