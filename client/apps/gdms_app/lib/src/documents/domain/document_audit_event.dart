/// Represents one recent audit event linked to a document.
final class DocumentAuditEvent {
  const DocumentAuditEvent({
    required this.eventType,
    required this.severity,
    required this.occurredAtLabel,
  });

  final String eventType;
  final String severity;
  final String occurredAtLabel;
}
