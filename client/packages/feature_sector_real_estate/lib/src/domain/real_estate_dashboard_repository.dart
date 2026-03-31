import 'real_estate_dashboard_overview.dart';

/// Defines the contract used by the real-estate vertical dashboard.
abstract interface class RealEstateDashboardRepository {
  Future<RealEstateDashboardOverview> loadOverview();
}
