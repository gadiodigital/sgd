import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_reports/feature_reports.dart';

void main() {
  test('load sincroniza overview y filtra metricas por lente', () async {
    final repository = _RecordingReportsRepository();
    final viewModel = ReportsViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.totalDocuments, 12);
    expect(viewModel.message, 'Reporte operativo sincronizado.');
    expect(viewModel.visibleOperationalMetrics.length, 7);
    expect(viewModel.visiblePlatformMetrics.length, 6);

    viewModel.updateLens(ReportsLens.signatures);

    expect(
      viewModel.visibleOperationalMetrics.map((item) => item.label).toList(),
      ['Firmas pendientes', 'Firmas canceladas'],
    );
  });

  test('load propaga error y deja el estado en error', () async {
    final viewModel = ReportsViewModel(_FailingReportsRepository());

    await expectLater(viewModel.load(), throwsException);

    expect(viewModel.overview, isNull);
    expect(viewModel.state, ViewState.error);
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingReportsRepository implements ReportsRepository {
  int loadCalls = 0;

  @override
  Future<OperationalReportOverview> loadOverview() async {
    loadCalls++;
    return const OperationalReportOverview(
      totalDocuments: 12,
      activeLegalHolds: 1,
      openWorkflowTasks: 4,
      pendingSignatures: 2,
      cancelledSignatures: 1,
      pendingDispositionItems: 3,
      failedLoginsLast24Hours: 1,
      platformSummary: PlatformReportOverview(
        totalTenants: 2,
        totalDocuments: 120,
        openWorkflowTasks: 11,
        pendingSignatures: 5,
        cancelledSignatures: 2,
        failedLoginsLast24Hours: 3,
      ),
    );
  }
}

final class _FailingReportsRepository implements ReportsRepository {
  @override
  Future<OperationalReportOverview> loadOverview() {
    throw Exception('reports unavailable');
  }
}
