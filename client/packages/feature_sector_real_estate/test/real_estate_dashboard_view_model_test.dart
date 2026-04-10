import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_sector_real_estate/feature_sector_real_estate.dart';

void main() {
  test('load sincroniza overview y publica mensaje operativo', () async {
    final repository = _RecordingRealEstateRepository();
    final viewModel = RealEstateDashboardViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.activeFiles, 4);
    expect(viewModel.overview?.files.length, 2);
    expect(viewModel.message, 'Panel inmobiliario sincronizado.');
    expect(viewModel.state, ViewState.success);
  });

  test('load deja el view model en error cuando el repositorio falla', () async {
    final viewModel = RealEstateDashboardViewModel(
      _FailingRealEstateRepository(),
    );

    await expectLater(viewModel.load(), throwsException);

    expect(viewModel.overview, isNull);
    expect(viewModel.state, ViewState.error);
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingRealEstateRepository
    implements RealEstateDashboardRepository {
  int loadCalls = 0;

  @override
  Future<RealEstateDashboardOverview> loadOverview() async {
    loadCalls++;
    return const RealEstateDashboardOverview(
      activeFiles: 4,
      pendingApprovals: 2,
      complianceAlerts: 1,
      files: [
        RealEstateFileItem(
          id: 're-1',
          title: 'Legajo de inmueble',
          subtitle: 'Contrato pendiente de aprobación',
          status: 'WARNING',
        ),
        RealEstateFileItem(
          id: 're-2',
          title: 'Expediente de alquiler',
          subtitle: 'Incumplimiento documental detectado',
          status: 'CRITICAL',
        ),
      ],
    );
  }
}

final class _FailingRealEstateRepository
    implements RealEstateDashboardRepository {
  @override
  Future<RealEstateDashboardOverview> loadOverview() {
    throw Exception('real estate unavailable');
  }
}
