/// Represents a tenant card shown in the admin dashboard.
final class AdminTenantSummary {
  const AdminTenantSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.sector,
    required this.createdAtLabel,
  });

  final String id;
  final String code;
  final String name;
  final String sector;
  final String createdAtLabel;
}
