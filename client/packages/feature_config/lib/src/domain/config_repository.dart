import 'config_overview.dart';

/// Defines the configuration reads and writes used by the config workspace.
abstract interface class ConfigRepository {
  Future<ConfigOverview> loadOverview();

  Future<void> savePreferences({
    required String preferredLandingModule,
    required bool showComplianceTips,
  });
}
