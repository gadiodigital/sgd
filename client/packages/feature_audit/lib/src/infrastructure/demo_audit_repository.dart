import '../domain/audit_event_item.dart';
import '../domain/audit_overview.dart';
import '../domain/audit_repository.dart';

/// Provides fallback audit data for isolated previews and tests.
final class DemoAuditRepository implements AuditRepository {
  const DemoAuditRepository();

  @override
  Future<AuditOverview> loadOverview() async {
    return const AuditOverview(
      totalEvents: 3,
      criticalEvents: 1,
      warningEvents: 1,
      recentEvents: [
        AuditEventItem(
          tenantCode: 'GDMS',
          eventType: 'LOGIN_FAILED',
          severity: 'WARNING',
          occurredAtLabel: 'Hace 10 min',
        ),
        AuditEventItem(
          tenantCode: 'GDMS',
          eventType: 'DOCUMENT_CREATED',
          severity: 'INFO',
          occurredAtLabel: 'Hace 30 min',
        ),
        AuditEventItem(
          tenantCode: 'GDMS',
          eventType: 'LEGAL_HOLD_CREATED',
          severity: 'CRITICAL',
          occurredAtLabel: 'Ayer',
        ),
      ],
    );
  }
}
