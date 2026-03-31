/// Represents one recent audit event surfaced in the admin dashboard.
final class AdminAuditEvent {
  const AdminAuditEvent({
    required this.tenantCode,
    required this.eventType,
    required this.severity,
    required this.occurredAtLabel,
  });

  final String tenantCode;
  final String eventType;
  final String severity;
  final String occurredAtLabel;
}
