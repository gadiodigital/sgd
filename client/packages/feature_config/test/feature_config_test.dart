import 'package:flutter_test/flutter_test.dart';

import 'package:feature_config/feature_config.dart';

void main() {
  test('loads config overview data', () async {
    final viewModel = ConfigViewModel(_FakeConfigRepository());

    await viewModel.load();

    expect(viewModel.overview?.remoteConfigAvailable, true);
    expect(viewModel.preferredLandingModule, 'search');
  });
}

final class _FakeConfigRepository implements ConfigRepository {
  @override
  Future<ConfigOverview> loadOverview() async {
    return const ConfigOverview(
      remoteConfigAvailable: true,
      firestoreAvailable: true,
      bannerMessage: 'Config activa',
      workflowEnabled: true,
      searchResultLimit: 20,
      preferredLandingModule: 'search',
      showComplianceTips: true,
      statusMessage: 'OK',
    );
  }

  @override
  Future<void> savePreferences({
    required String preferredLandingModule,
    required bool showComplianceTips,
  }) async {}
}
