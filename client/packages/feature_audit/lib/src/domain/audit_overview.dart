import 'audit_event_item.dart';

/// Represents the current audit summary shown in the audit workspace.
final class AuditOverview {
  const AuditOverview({
    required this.totalEvents,
    required this.criticalEvents,
    required this.warningEvents,
    required this.recentEvents,
  });

  final int totalEvents;
  final int criticalEvents;
  final int warningEvents;
  final List<AuditEventItem> recentEvents;
}
