import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_auth/feature_auth.dart';

void main() {
  test('load sincroniza sesion y publica mensaje operativo', () async {
    final repository = _RecordingSessionOverviewRepository();
    final viewModel = AuthOverviewViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.session?.tenantCode, 'TENANT-01');
    expect(viewModel.session?.primaryRole, 'TENANT_ADMIN');
    expect(viewModel.message, 'Sesion preparada para operar.');
    expect(viewModel.state, ViewState.success);
    expect(viewModel.isBusy, isFalse);
  });

  test('load informa error cuando el repositorio falla', () async {
    final viewModel = AuthOverviewViewModel(_FailingSessionOverviewRepository());

    await viewModel.load();

    expect(viewModel.session, isNull);
    expect(viewModel.message, 'No se pudo cargar la sesion actual.');
    expect(viewModel.state, ViewState.error);
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingSessionOverviewRepository
    implements SessionOverviewRepository {
  int loadCalls = 0;

  @override
  Future<SessionOverview> loadCurrentSession() async {
    loadCalls++;
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

final class _FailingSessionOverviewRepository
    implements SessionOverviewRepository {
  @override
  Future<SessionOverview> loadCurrentSession() {
    throw Exception('auth unavailable');
  }
}
