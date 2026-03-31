/// Represents one tenant user shown in the admin access dialog.
final class TenantUserEntry {
  const TenantUserEntry({
    required this.id,
    required this.email,
    required this.fullName,
    required this.status,
    required this.roleCodes,
  });

  factory TenantUserEntry.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => item['code'] as String? ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return TenantUserEntry(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      roleCodes: roles,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String status;
  final List<String> roleCodes;
}
