import '../domain/session_overview.dart';
import '../domain/session_overview_repository.dart';

/// Provides deterministic demo data while the auth API is integrated.
final class DemoSessionOverviewRepository implements SessionOverviewRepository {
  @override
  Future<SessionOverview> loadCurrentSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return const SessionOverview(
      userName: 'Claudio Paz',
      email: 'cpaz@gdms.local',
      tenantName: 'Estudio Juridico Delta',
      tenantCode: 'DELTA-LAW',
      primaryRole: 'TENANT_ADMIN',
      lastLoginLabel: 'Hoy, 08:35',
      passwordRotationDays: 21,
      mfaEnabled: true,
    );
  }
}
