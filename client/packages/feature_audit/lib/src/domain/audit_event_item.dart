/// Represents one event rendered in the audit workspace.
final class AuditEventItem {
  const AuditEventItem({
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
