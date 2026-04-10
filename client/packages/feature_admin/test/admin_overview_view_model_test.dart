import 'package:feature_admin/feature_admin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load sincroniza overview y publica mensaje de exito', () async {
    final repository = _RecordingAdminRepository();
    final viewModel = AdminOverviewViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.activeTenants, 2);
    expect(viewModel.overview?.pendingProvisioning, 1);
    expect(viewModel.overview?.tasks.length, 1);
    expect(viewModel.message, 'Gobierno de plataforma sincronizado.');
  });

  test('load informa error si el repositorio falla', () async {
    final viewModel = AdminOverviewViewModel(_FailingAdminRepository());

    await viewModel.load();

    expect(viewModel.overview, isNull);
    expect(
      viewModel.message,
      'No se pudo cargar el tablero de administracion.',
    );
  });
}

final class _RecordingAdminRepository implements AdminRepository {
  int loadCalls = 0;

  @override
  Future<AdminOverview> loadOverview() async {
    loadCalls++;
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

final class _FailingAdminRepository implements AdminRepository {
  @override
  Future<AdminOverview> loadOverview() {
    throw Exception('backend down');
  }
}
