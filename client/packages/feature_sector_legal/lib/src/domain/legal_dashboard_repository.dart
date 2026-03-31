import 'legal_dashboard_overview.dart';

/// Defines the contract used by the legal vertical dashboard.
abstract interface class LegalDashboardRepository {
  Future<LegalDashboardOverview> loadOverview();
}
