import 'corporate_record_item.dart';

/// Represents the current overview of the corporate vertical dashboard.
final class CorporateDashboardOverview {
  const CorporateDashboardOverview({
    required this.activeContracts,
    required this.pendingGovernanceTasks,
    required this.controlAlerts,
    required this.records,
  });

  final int activeContracts;
  final int pendingGovernanceTasks;
  final int controlAlerts;
  final List<CorporateRecordItem> records;
}
