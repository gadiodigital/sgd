/// Represents a tenant user available for ACL assignment.
final class DocumentAccessUserOption {
  const DocumentAccessUserOption({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;
}
