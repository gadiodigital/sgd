import 'package:feature_reports/feature_reports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads reports overview data', () async {
    final viewModel = ReportsViewModel(_FakeReportsRepository());

    await viewModel.load();

    expect(viewModel.overview?.totalDocuments, 12);
    expect(viewModel.overview?.pendingSignatures, 2);
    expect(viewModel.visibleOperationalMetrics.length, 7);
    expect(viewModel.visiblePlatformMetrics.length, 6);

    viewModel.updateLens(ReportsLens.signatures);
    expect(viewModel.visibleOperationalMetrics.length, 2);
  });
}

final class _FakeReportsRepository implements ReportsRepository {
  @override
  Future<OperationalReportOverview> loadOverview() async {
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
