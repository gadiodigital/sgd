import 'package:feature_auth/feature_auth.dart';

import '../../auth/application/app_session_view_model.dart';

/// Adapts the authenticated app session to the auth feature repository.
final class ApiAuthOverviewRepository implements SessionOverviewRepository {
  const ApiAuthOverviewRepository(this._sessionViewModel);

  final AppSessionViewModel _sessionViewModel;

  @override
  Future<SessionOverview> loadCurrentSession() async {
    final session = _sessionViewModel.session;
    final identity = _sessionViewModel.identity;

    if (session == null || identity == null) {
      throw StateError('No hay sesion autenticada disponible.');
    }

    return SessionOverview(
      userName: identity.fullName,
      email: identity.email,
      tenantName: session.tenantName,
      tenantCode: identity.tenantCode,
      primaryRole: identity.roles.isNotEmpty ? identity.roles.first : 'SIN_ROL',
      lastLoginLabel: 'Sesion actual',
      passwordRotationDays: session.mustChangePassword ? 0 : 30,
      mfaEnabled: false,
    );
  }
}
