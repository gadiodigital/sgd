/// Represents the authenticated identity resolved from /api/auth/me.
final class AppIdentity {
  const AppIdentity({
    required this.userId,
    required this.tenantId,
    required this.tenantCode,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  factory AppIdentity.fromJson(Map<String, dynamic> json) {
    return AppIdentity(
      userId: json['userId'] as String,
      tenantId: json['tenantId'] as String,
      tenantCode: json['tenantCode'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
    );
  }

  final String userId;
  final String tenantId;
  final String tenantCode;
  final String email;
  final String fullName;
  final List<String> roles;

  bool get isPlatformAdmin => roles.contains('PLATFORM_ADMIN');
  bool get canManageTenantUsers =>
      isPlatformAdmin || roles.contains('TENANT_ADMIN');
}
