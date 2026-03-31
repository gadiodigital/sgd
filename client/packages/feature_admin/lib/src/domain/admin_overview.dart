import 'admin_audit_event.dart';
import 'admin_tenant_summary.dart';

enum AdminMetricKind {
  activeTenants,
  pendingProvisioning,
  failedLogins24h,
  storageAlerts,
}

final class AdminMetricItem {
  const AdminMetricItem({
    required this.label,
    required this.value,
    required this.colorHex,
    required this.kind,
  });

  final String label;
  final int value;
  final int colorHex;
  final AdminMetricKind kind;
}

/// Represents one governance task pending action by administrators.
final class GovernanceTask {
  const GovernanceTask({
    required this.title,
    required this.ownerLabel,
    required this.priorityLabel,
  });

  final String title;
  final String ownerLabel;
  final String priorityLabel;
}

/// Aggregates tenant and platform governance health indicators.
final class AdminOverview {
  const AdminOverview({
    required this.activeTenants,
    required this.pendingProvisioning,
    required this.failedLogins24h,
    required this.storageAlerts,
    required this.tenants,
    required this.recentEvents,
    required this.tasks,
  });

  final int activeTenants;
  final int pendingProvisioning;
  final int failedLogins24h;
  final int storageAlerts;
  final List<AdminTenantSummary> tenants;
  final List<AdminAuditEvent> recentEvents;
  final List<GovernanceTask> tasks;
}
