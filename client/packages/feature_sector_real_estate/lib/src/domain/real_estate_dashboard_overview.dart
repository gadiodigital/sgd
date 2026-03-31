import 'real_estate_file_item.dart';

/// Represents the current overview of the real-estate vertical dashboard.
final class RealEstateDashboardOverview {
  const RealEstateDashboardOverview({
    required this.activeFiles,
    required this.pendingApprovals,
    required this.complianceAlerts,
    required this.files,
  });

  final int activeFiles;
  final int pendingApprovals;
  final int complianceAlerts;
  final List<RealEstateFileItem> files;
}
