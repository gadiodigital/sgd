import 'package:feature_admin/feature_admin.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Loads organization-scoped governance detail for platform administration dialogs.
final class ApiAdminTenantDetailsRepository {
  const ApiAdminTenantDetailsRepository(
    this._apiClient,
    this._sessionViewModel,
  );

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  Future<AdminTenantDetails> loadTenantDetails(
    AdminTenantSummary tenant,
  ) async {
    final identity = _sessionViewModel.identity;
    if (identity == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final eventsJson = await _apiClient.getList(
      '/api/tenants/${tenant.id}/audit/events/recent?limit=30',
    );
    final recentEvents = eventsJson
        .cast<Map<String, dynamic>>()
        .map((item) {
          final occurredAt = DateTime.parse(
            item['occurredAtUtc'] as String,
          ).toUtc();
          return AdminAuditEvent(
            tenantCode: item['tenantCode'] as String? ?? tenant.code,
            eventType: item['eventType'] as String? ?? 'UNKNOWN',
            severity: item['severity'] as String? ?? 'INFO',
            occurredAtLabel: ApiRepositoryFormatters.formatRelativeDate(
              occurredAt,
            ),
          );
        })
        .toList(growable: false);

    final now = DateTime.now().toUtc();
    final failedLogins24h = eventsJson.cast<Map<String, dynamic>>().where((
      item,
    ) {
      if ((item['eventType'] as String? ?? '') != 'LOGIN_FAILED') {
        return false;
      }

      final occurredAt = DateTime.parse(
        item['occurredAtUtc'] as String,
      ).toUtc();
      return occurredAt.isAfter(now.subtract(const Duration(hours: 24)));
    }).length;

    final warningEvents = recentEvents
        .where((item) => item.severity == 'WARNING' || item.severity == 'ERROR')
        .length;
    final criticalEvents = recentEvents
        .where((item) => item.severity == 'CRITICAL')
        .length;

    return AdminTenantDetails(
      totalEvents: recentEvents.length,
      warningEvents: warningEvents,
      criticalEvents: criticalEvents,
      failedLogins24h: failedLogins24h,
      recentEvents: recentEvents,
    );
  }
}

/// Represents organization governance detail derived from existing API endpoints.
final class AdminTenantDetails {
  const AdminTenantDetails({
    required this.totalEvents,
    required this.warningEvents,
    required this.criticalEvents,
    required this.failedLogins24h,
    required this.recentEvents,
  });

  final int totalEvents;
  final int warningEvents;
  final int criticalEvents;
  final int failedLogins24h;
  final List<AdminAuditEvent> recentEvents;
}
