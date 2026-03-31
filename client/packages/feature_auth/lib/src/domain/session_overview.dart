/// Provides a typed summary of the current authenticated session.
final class SessionOverview {
  const SessionOverview({
    required this.userName,
    required this.email,
    required this.tenantName,
    required this.tenantCode,
    required this.primaryRole,
    required this.lastLoginLabel,
    required this.passwordRotationDays,
    required this.mfaEnabled,
  });

  final String userName;
  final String email;
  final String tenantName;
  final String tenantCode;
  final String primaryRole;
  final String lastLoginLabel;
  final int passwordRotationDays;
  final bool mfaEnabled;
}
