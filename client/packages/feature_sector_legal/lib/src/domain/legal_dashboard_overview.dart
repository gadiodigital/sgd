import 'legal_case_file_item.dart';
import 'legal_matter_item.dart';

/// Represents the current overview of the legal vertical dashboard.
final class LegalDashboardOverview {
  const LegalDashboardOverview({
    required this.openTasks,
    required this.dueEvidenceReviews,
    required this.failedLogins24h,
    required this.caseFiles,
    required this.matters,
  });

  final int openTasks;
  final int dueEvidenceReviews;
  final int failedLogins24h;
  final List<LegalCaseFileItem> caseFiles;
  final List<LegalMatterItem> matters;
}
