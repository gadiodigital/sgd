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

    final organization = await _loadCurrentOrganization();
    final auditEvents = await _loadRecentEvents(identity.isPlatformAdmin);
    final failedLogins24h = auditEvents
        .where((item) => item.eventType == 'LOGIN_FAILED')
        .where(
          (item) => item.occurredAt.isAfter(
            DateTime.now().toUtc().subtract(const Duration(hours: 24)),
          ),
        )
        .length;

    return AdminOverview(
      activeTenants: 1,
      pendingProvisioning: identity.isPlatformAdmin ? 0 : 0,
      failedLogins24h: failedLogins24h,
      storageAlerts: 0,
      tenants: [
        AdminTenantSummary(
          id: organization.id,
          code: organization.code,
          name: organization.name,
          sector: organization.sector,
          createdAtLabel: ApiRepositoryFormatters.formatShortDate(
            organization.createdAt,
          ),
        ),
      ],
      recentEvents: auditEvents
          .map((item) {
            return AdminAuditEvent(
              tenantCode: item.tenantCode,
              eventType: item.eventType,
              severity: item.severity,
              occurredAtLabel: ApiRepositoryFormatters.formatRelativeDate(
                item.occurredAt,
              ),
            );
          })
          .toList(growable: false),
      tasks: [
        if (failedLogins24h > 0)
          GovernanceTask(
            title:
                'Investigar $failedLogins24h intentos fallidos de login recientes',
            ownerLabel: identity.isPlatformAdmin
                ? 'Plataforma'
                : 'Organización',
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
          ownerLabel: identity.isPlatformAdmin ? 'Plataforma' : 'Organización',
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

  Future<_TenantSnapshot> _loadCurrentOrganization() async {
    final session = _sessionViewModel.session!;
    try {
      final organizationJson = await _apiClient.getObject(
        '/api/organization/current',
      );
      return _TenantSnapshot(
        id: organizationJson['id'] as String,
        code: organizationJson['code'] as String,
        name: organizationJson['name'] as String,
        sector: organizationJson['sector'] as String,
        createdAt: DateTime.parse(organizationJson['createdAtUtc'] as String),
      );
    } on ApiException {
      return _TenantSnapshot(
        id: session.tenantId,
        code: session.tenantCode,
        name: session.tenantName,
        sector: 'ORGANIZACION_ACTUAL',
        createdAt: DateTime.now().toUtc(),
      );
    }
  }

  Future<List<_AuditEventSnapshot>> _loadRecentEvents(
    bool isPlatformAdmin,
  ) async {
    try {
      final eventsJson = await _apiClient.getList(
        isPlatformAdmin
            ? '/api/audit/events/recent?limit=100'
            : '/api/organization/audit/events/recent?limit=100',
      );
      return eventsJson
          .cast<Map<String, dynamic>>()
          .map((item) {
            return _AuditEventSnapshot(
              tenantCode: item['tenantCode'] as String,
              eventType: item['eventType'] as String,
              severity: item['severity'] as String,
              occurredAt: DateTime.parse(
                item['occurredAtUtc'] as String,
              ).toUtc(),
            );
          })
          .toList(growable: false);
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
