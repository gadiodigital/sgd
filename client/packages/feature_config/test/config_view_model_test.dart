import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_config/feature_config.dart';

void main() {
  test('load sincroniza overview y preferencias visibles', () async {
    final repository = _RecordingConfigRepository();
    final viewModel = ConfigViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.remoteConfigAvailable, isTrue);
    expect(viewModel.preferredLandingModule, 'search');
    expect(viewModel.showComplianceTips, isTrue);
    expect(viewModel.message, 'OK');
    expect(viewModel.state, ViewState.success);
  });

  test('savePreferences persiste cambios y refresca snapshot', () async {
    final repository = _RecordingConfigRepository();
    final viewModel = ConfigViewModel(repository);

    await viewModel.load();
    viewModel.updatePreferredLandingModule('workflow');
    viewModel.updateShowComplianceTips(false);
    await viewModel.savePreferences();

    expect(
      repository.savedRequests,
      [
        const _SaveRequest(
          preferredLandingModule: 'workflow',
          showComplianceTips: false,
        ),
      ],
    );
    expect(viewModel.preferredLandingModule, 'workflow');
    expect(viewModel.showComplianceTips, isFalse);
    expect(viewModel.message, 'Preferencias guardadas correctamente.');
    expect(repository.loadCalls, 2);
  });
}

final class _RecordingConfigRepository implements ConfigRepository {
  int loadCalls = 0;
  final List<_SaveRequest> savedRequests = <_SaveRequest>[];
  String _preferredLandingModule = 'search';
  bool _showComplianceTips = true;

  @override
  Future<ConfigOverview> loadOverview() async {
    loadCalls++;
    return ConfigOverview(
      remoteConfigAvailable: true,
      firestoreAvailable: true,
      bannerMessage: 'Config activa',
      workflowEnabled: true,
      searchResultLimit: 20,
      preferredLandingModule: _preferredLandingModule,
      showComplianceTips: _showComplianceTips,
      statusMessage: 'OK',
    );
  }

  @override
  Future<void> savePreferences({
    required String preferredLandingModule,
    required bool showComplianceTips,
  }) async {
    savedRequests.add(
      _SaveRequest(
        preferredLandingModule: preferredLandingModule,
        showComplianceTips: showComplianceTips,
      ),
    );
    _preferredLandingModule = preferredLandingModule;
    _showComplianceTips = showComplianceTips;
  }
}

final class _SaveRequest {
  const _SaveRequest({
    required this.preferredLandingModule,
    required this.showComplianceTips,
  });

  final String preferredLandingModule;
  final bool showComplianceTips;

  @override
  bool operator ==(Object other) {
    return other is _SaveRequest &&
        other.preferredLandingModule == preferredLandingModule &&
        other.showComplianceTips == showComplianceTips;
  }

  @override
  int get hashCode => Object.hash(preferredLandingModule, showComplianceTips);
}
