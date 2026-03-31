import 'package:flutter_test/flutter_test.dart';

import 'package:feature_sector_real_estate/feature_sector_real_estate.dart';

void main() {
  test('loads real estate dashboard data', () async {
    final viewModel = RealEstateDashboardViewModel(_FakeRepository());

    await viewModel.load();

    expect(viewModel.overview?.activeFiles, 4);
    expect(viewModel.overview?.files.length, 1);
  });
}

final class _FakeRepository implements RealEstateDashboardRepository {
  @override
  Future<RealEstateDashboardOverview> loadOverview() async {
    return const RealEstateDashboardOverview(
      activeFiles: 4,
      pendingApprovals: 2,
      complianceAlerts: 1,
      files: [
        RealEstateFileItem(
          title: 'Legajo de inmueble',
          subtitle: 'Contrato pendiente de aprobación',
          status: 'WARNING',
        ),
      ],
    );
  }
}
