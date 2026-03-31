import 'package:flutter_test/flutter_test.dart';

import 'package:feature_admin/feature_admin.dart';

void main() {
  test('loads admin overview data', () async {
    final viewModel = AdminOverviewViewModel(_FakeAdminRepository());

    await viewModel.load();

    expect(viewModel.overview?.activeTenants, 2);
    expect(viewModel.overview?.pendingProvisioning, 1);
    expect(viewModel.overview?.tasks.length, 1);
  });
}

final class _FakeAdminRepository implements AdminRepository {
  @override
  Future<AdminOverview> loadOverview() async {
    return const AdminOverview(
      activeTenants: 2,
      pendingProvisioning: 1,
      failedLogins24h: 0,
      storageAlerts: 0,
      tenants: [
        AdminTenantSummary(
          id: 'tenant-1',
          code: 'TENANT-1',
          name: 'Tenant 1',
          sector: 'EMPRESA',
          createdAtLabel: 'Hoy',
        ),
      ],
      recentEvents: [
        AdminAuditEvent(
          tenantCode: 'TENANT-1',
          eventType: 'LOGIN_SUCCEEDED',
          severity: 'INFO',
          occurredAtLabel: 'Hoy',
        ),
      ],
      tasks: [
        GovernanceTask(
          title: 'Task',
          ownerLabel: 'Owner',
          priorityLabel: 'Alta',
        ),
      ],
    );
  }
}
