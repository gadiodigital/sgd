import 'package:flutter_test/flutter_test.dart';

import 'package:feature_auth/feature_auth.dart';

void main() {
  test('loads auth overview data', () async {
    final viewModel = AuthOverviewViewModel(_FakeSessionOverviewRepository());

    await viewModel.load();

    expect(viewModel.session?.tenantCode, 'TENANT-01');
    expect(viewModel.message, isNotNull);
  });
}

final class _FakeSessionOverviewRepository
    implements SessionOverviewRepository {
  @override
  Future<SessionOverview> loadCurrentSession() async {
    return const SessionOverview(
      userName: 'Usuario Demo',
      email: 'demo@example.com',
      tenantName: 'Tenant Demo',
      tenantCode: 'TENANT-01',
      primaryRole: 'TENANT_ADMIN',
      lastLoginLabel: 'Hoy',
      passwordRotationDays: 30,
      mfaEnabled: true,
    );
  }
}
