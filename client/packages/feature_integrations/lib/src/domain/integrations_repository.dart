import 'integrations_overview.dart';

/// Defines the contract required by the integrations dashboard.
abstract interface class IntegrationsRepository {
  Future<IntegrationsOverview> loadOverview();
}
