import '../domain/admin_audit_event.dart';
import '../domain/admin_overview.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_tenant_summary.dart';

/// Supplies platform governance demo data during initial UI construction.
final class DemoAdminRepository implements AdminRepository {
  @override
  Future<AdminOverview> loadOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 210));

    return const AdminOverview(
      activeTenants: 9,
      pendingProvisioning: 2,
      failedLogins24h: 3,
      storageAlerts: 1,
      tenants: [
        AdminTenantSummary(
          id: 'tenant-norte-real',
          code: 'NORTE-REAL',
          name: 'Norte Real Estate',
          sector: 'INMOBILIARIA',
          createdAtLabel: '18 Mar 2026',
        ),
        AdminTenantSummary(
          id: 'tenant-lex-ar',
          code: 'LEX-AR',
          name: 'Lex Argentina',
          sector: 'JURIDICO',
          createdAtLabel: '17 Mar 2026',
        ),
      ],
      recentEvents: [
        AdminAuditEvent(
          tenantCode: 'NORTE-REAL',
          eventType: 'LOGIN_FAILED',
          severity: 'WARNING',
          occurredAtLabel: 'Hoy 09:15',
        ),
        AdminAuditEvent(
          tenantCode: 'LEX-AR',
          eventType: 'DOCUMENT_CREATED',
          severity: 'INFO',
          occurredAtLabel: 'Hoy 08:40',
        ),
      ],
      tasks: [
        GovernanceTask(
          title: 'Revisar claves JWT y politicas de expiracion',
          ownerLabel: 'Seguridad',
          priorityLabel: 'Alta',
        ),
        GovernanceTask(
          title: 'Asignar COMPLIANCE_OFFICER al tenant NORTE-REAL',
          ownerLabel: 'Plataforma',
          priorityLabel: 'Media',
        ),
        GovernanceTask(
          title: 'Completar baseline de Remote Config no sensible',
          ownerLabel: 'Arquitectura',
          priorityLabel: 'Media',
        ),
      ],
    );
  }
}
