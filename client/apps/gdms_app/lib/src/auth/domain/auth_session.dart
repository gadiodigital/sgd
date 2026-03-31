/// Represents the authenticated session returned by /api/auth/token.
final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAtUtc,
    required this.expiresInSeconds,
    required this.mustChangePassword,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roles,
    required this.tenantId,
    required this.tenantCode,
    required this.tenantName,
    required this.apiBaseUrl,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json, String apiBaseUrl) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
      mustChangePassword: json['mustChangePassword'] as bool,
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
      tenantId: json['tenantId'] as String,
      tenantCode: json['tenantCode'] as String,
      tenantName: json['tenantName'] as String,
      apiBaseUrl: apiBaseUrl,
    );
  }

  final String accessToken;
  final String tokenType;
  final DateTime expiresAtUtc;
  final int expiresInSeconds;
  final bool mustChangePassword;
  final String userId;
  final String email;
  final String fullName;
  final List<String> roles;
  final String tenantId;
  final String tenantCode;
  final String tenantName;
  final String apiBaseUrl;
}
