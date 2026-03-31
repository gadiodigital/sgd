/// Represents a role available for assignment in the admin dialog.
final class AdminRoleOption {
  const AdminRoleOption({
    required this.code,
    required this.name,
    required this.description,
  });

  factory AdminRoleOption.fromJson(Map<String, dynamic> json) {
    return AdminRoleOption(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  final String code;
  final String name;
  final String description;
}
