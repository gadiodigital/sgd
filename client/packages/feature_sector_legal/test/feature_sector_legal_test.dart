import 'package:flutter_test/flutter_test.dart';

import 'package:feature_sector_legal/feature_sector_legal.dart';

void main() {
  test('loads legal dashboard data', () async {
    final viewModel = LegalDashboardViewModel(_FakeLegalRepository());

    await viewModel.load();

    expect(viewModel.overview?.openTasks, 3);
    expect(viewModel.overview?.matters.length, 1);
  });
}

final class _FakeLegalRepository implements LegalDashboardRepository {
  @override
  Future<LegalDashboardOverview> loadOverview() async {
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
      ],
      matters: [
        LegalMatterItem(
          title: 'Custodia de evidencia',
          subtitle: 'Expediente con revisión pendiente',
          status: 'WARNING',
        ),
      ],
    );
  }
}
