import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_sector_corporate/feature_sector_corporate.dart';

void main() {
  test('load sincroniza overview y publica mensaje operativo', () async {
    final repository = _RecordingCorporateRepository();
    final viewModel = CorporateDashboardViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.activeContracts, 5);
    expect(viewModel.overview?.records.length, 2);
    expect(viewModel.message, 'Panel corporativo sincronizado.');
    expect(viewModel.state, ViewState.success);
  });

  test('load deja el view model en error si el repositorio falla', () async {
    final viewModel = CorporateDashboardViewModel(_FailingCorporateRepository());

    await expectLater(viewModel.load(), throwsException);

    expect(viewModel.overview, isNull);
    expect(viewModel.state, ViewState.error);
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingCorporateRepository
    implements CorporateDashboardRepository {
  int loadCalls = 0;

  @override
  Future<CorporateDashboardOverview> loadOverview() async {
    loadCalls++;
    return const CorporateDashboardOverview(
      activeContracts: 5,
      pendingGovernanceTasks: 2,
      controlAlerts: 1,
      records: [
        CorporateRecordItem(
          id: 'corp-1',
          title: 'Contrato societario',
          subtitle: 'Pendiente de aprobación interna',
          status: 'WARNING',
        ),
        CorporateRecordItem(
          id: 'corp-2',
          title: 'Libro de actas',
          subtitle: 'Requiere actualización regulatoria',
          status: 'CRITICAL',
        ),
      ],
    );
  }
}

final class _FailingCorporateRepository
    implements CorporateDashboardRepository {
  @override
  Future<CorporateDashboardOverview> loadOverview() {
    throw Exception('corporate unavailable');
  }
}
