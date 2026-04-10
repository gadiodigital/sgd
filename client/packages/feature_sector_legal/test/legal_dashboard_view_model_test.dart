import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_sector_legal/feature_sector_legal.dart';

void main() {
  test('load sincroniza overview y publica mensaje operativo', () async {
    final repository = _RecordingLegalRepository();
    final viewModel = LegalDashboardViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.openTasks, 3);
    expect(viewModel.overview?.caseFiles.length, 2);
    expect(viewModel.overview?.matters.length, 2);
    expect(viewModel.message, 'Panel jurídico sincronizado.');
    expect(viewModel.state, ViewState.success);
  });

  test('load deja el view model en error cuando el repositorio falla', () async {
    final viewModel = LegalDashboardViewModel(_FailingLegalRepository());

    await expectLater(viewModel.load(), throwsException);

    expect(viewModel.overview, isNull);
    expect(viewModel.state, ViewState.error);
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingLegalRepository implements LegalDashboardRepository {
  int loadCalls = 0;

  @override
  Future<LegalDashboardOverview> loadOverview() async {
    loadCalls++;
    return const LegalDashboardOverview(
      openTasks: 3,
      dueEvidenceReviews: 1,
      failedLogins24h: 0,
      caseFiles: [
        LegalCaseFileItem(
          id: 'case-1',
          title: 'Expediente civil',
          subtitle: 'EXP-2026-001 · JURIDICO',
          status: 'OPEN',
        ),
        LegalCaseFileItem(
          id: 'case-2',
          title: 'Expediente laboral',
          subtitle: 'EXP-2026-014 · RRLL',
          status: 'CLOSED',
        ),
      ],
      matters: [
        LegalMatterItem(
          title: 'Custodia de evidencia',
          subtitle: 'Expediente con revisión pendiente',
          status: 'WARNING',
        ),
        LegalMatterItem(
          title: 'Incidente de acceso',
          subtitle: 'Requiere revisión del equipo legal',
          status: 'CRITICAL',
        ),
      ],
    );
  }
}

final class _FailingLegalRepository implements LegalDashboardRepository {
  @override
  Future<LegalDashboardOverview> loadOverview() {
    throw Exception('legal unavailable');
  }
}
