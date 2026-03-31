import 'platform_report_overview.dart';

/// Aggregates the operational KPIs shown in the reports dashboard.
final class OperationalReportOverview {
  const OperationalReportOverview({
    required this.totalDocuments,
    required this.activeLegalHolds,
    required this.openWorkflowTasks,
    required this.pendingSignatures,
    required this.cancelledSignatures,
    required this.pendingDispositionItems,
    required this.failedLoginsLast24Hours,
    this.platformSummary,
  });

  final int totalDocuments;
  final int activeLegalHolds;
  final int openWorkflowTasks;
  final int pendingSignatures;
  final int cancelledSignatures;
  final int pendingDispositionItems;
  final int failedLoginsLast24Hours;
  final PlatformReportOverview? platformSummary;
}
