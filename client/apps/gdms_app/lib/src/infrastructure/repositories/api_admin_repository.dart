import 'package:feature_admin/feature_admin.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Loads platform governance indicators from available API endpoints.
final class ApiAdminRepository implements AdminRepository {
  const ApiAdminRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<AdminOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    final identity = _sessionViewModel.identity;

    if (session == null || identity == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final tenants = await _loadTenants(identity.isPlatformAdmin);
    final auditEvents = await _loadRecentEvents(identity.isPlatformAdmin);
    final failedLogins24h = auditEvents
        .where((item) => item.eventType == 'LOGIN_FAILED')
        .where((item) => item.occurredAt.isAfter(DateTime.now().toUtc().subtract(const Duration(hours: 24))))
        .length;

    return AdminOverview(
      activeTenants: tenants.length,
      pendingProvisioning: identity.isPlatformAdmin ? 0 : 0,
      failedLogins24h: failedLogins24h,
      storageAlerts: 0,
      tenants: tenants.map((item) {
        return AdminTenantSummary(
          id: item.id,
          code: item.code,
          name: item.name,
          sector: item.sector,
          createdAtLabel: ApiRepositoryFormatters.formatShortDate(item.createdAt),
        );
      }).toList(growable: false),
      recentEvents: auditEvents.map((item) {
        return AdminAuditEvent(
          tenantCode: item.tenantCode,
          eventType: item.eventType,
          severity: item.severity,
          occurredAtLabel: ApiRepositoryFormatters.formatRelativeDate(
            item.occurredAt,
          ),
        );
      }).toList(growable: false),
      tasks: [
        if (failedLogins24h > 0)
          GovernanceTask(
            title: 'Investigar $failedLogins24h intentos fallidos de login recientes',
            ownerLabel: identity.isPlatformAdmin ? 'Plataforma' : 'Tenant',
            priorityLabel: 'Alta',
          ),
        if (session.mustChangePassword)
          const GovernanceTask(
            title: 'Rotar la credencial inicial del administrador',
            ownerLabel: 'Seguridad',
            priorityLabel: 'Alta',
          ),
        GovernanceTask(
          title: 'Revisar permisos vigentes para ${session.tenantCode}',
          ownerLabel: identity.isPlatformAdmin ? 'Plataforma' : 'Tenant',
          priorityLabel: 'Media',
        ),
        if (identity.isPlatformAdmin)
          const GovernanceTask(
            title: 'Completar integracion de Remote Config no sensible',
            ownerLabel: 'Arquitectura',
            priorityLabel: 'Media',
          ),
      ],
    );
  }

  Future<List<_TenantSnapshot>> _loadTenants(bool isPlatformAdmin) async {
    if (!isPlatformAdmin) {
      final session = _sessionViewModel.session!;
      return [
        _TenantSnapshot(
          id: session.tenantId,
          code: session.tenantCode,
          name: session.tenantName,
          sector: 'TENANT_ACTUAL',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    }

    try {
      final tenantsJson = await _apiClient.getList('/api/tenants');
      return tenantsJson.cast<Map<String, dynamic>>().map((item) {
        return _TenantSnapshot(
          id: item['id'] as String,
          code: item['code'] as String,
          name: item['name'] as String,
          sector: item['sector'] as String,
          createdAt: DateTime.parse(item['createdAtUtc'] as String),
        );
      }).toList(growable: false);
    } on ApiException {
      return const [];
    }
  }

  Future<List<_AuditEventSnapshot>> _loadRecentEvents(bool isPlatformAdmin) async {
    try {
      final eventsJson = await _apiClient.getList(
        isPlatformAdmin
            ? '/api/audit/events/recent?limit=100'
            : '/api/tenants/${_sessionViewModel.session!.tenantId}/audit/events/recent?limit=100',
      );
      return eventsJson.cast<Map<String, dynamic>>().map((item) {
        return _AuditEventSnapshot(
          tenantCode: item['tenantCode'] as String,
          eventType: item['eventType'] as String,
          severity: item['severity'] as String,
          occurredAt: DateTime.parse(item['occurredAtUtc'] as String).toUtc(),
        );
      }).toList(growable: false);
    } on ApiException {
      return const [];
    }
  }
}

final class _TenantSnapshot {
  const _TenantSnapshot({
    required this.id,
    required this.code,
    required this.name,
    required this.sector,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final String sector;
  final DateTime createdAt;
}

final class _AuditEventSnapshot {
  const _AuditEventSnapshot({
    required this.tenantCode,
    required this.eventType,
    required this.severity,
    required this.occurredAt,
  });

  final String tenantCode;
  final String eventType;
  final String severity;
  final DateTime occurredAt;
}
