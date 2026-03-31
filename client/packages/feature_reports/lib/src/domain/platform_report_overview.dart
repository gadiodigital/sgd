/// Aggregates the platform-wide KPIs shown to platform administrators.
final class PlatformReportOverview {
  const PlatformReportOverview({
    required this.totalTenants,
    required this.totalDocuments,
    required this.openWorkflowTasks,
    required this.pendingSignatures,
    required this.cancelledSignatures,
    required this.failedLoginsLast24Hours,
  });

  final int totalTenants;
  final int totalDocuments;
  final int openWorkflowTasks;
  final int pendingSignatures;
  final int cancelledSignatures;
  final int failedLoginsLast24Hours;
}
