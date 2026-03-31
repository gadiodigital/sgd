/// Represents one explicit ACL entry assigned to a document.
final class DocumentAccessEntryRecord {
  const DocumentAccessEntryRecord({
    required this.id,
    required this.userId,
    required this.permissionCode,
    required this.grantedAtLabel,
  });

  final String id;
  final String userId;
  final String permissionCode;
  final String grantedAtLabel;
}
