import 'package:flutter_test/flutter_test.dart';

import 'package:feature_sector_corporate/feature_sector_corporate.dart';

void main() {
  test('loads corporate dashboard data', () async {
    final viewModel = CorporateDashboardViewModel(_FakeRepository());

    await viewModel.load();

    expect(viewModel.overview?.activeContracts, 5);
    expect(viewModel.overview?.records.length, 1);
  });
}

final class _FakeRepository implements CorporateDashboardRepository {
  @override
  Future<CorporateDashboardOverview> loadOverview() async {
    return const CorporateDashboardOverview(
      activeContracts: 5,
      pendingGovernanceTasks: 2,
      controlAlerts: 1,
      records: [
        CorporateRecordItem(
          title: 'Contrato societario',
          subtitle: 'Pendiente de aprobación interna',
          status: 'WARNING',
        ),
      ],
    );
  }
}
