import 'corporate_dashboard_overview.dart';

/// Defines the contract used by the corporate vertical dashboard.
abstract interface class CorporateDashboardRepository {
  Future<CorporateDashboardOverview> loadOverview();
}
