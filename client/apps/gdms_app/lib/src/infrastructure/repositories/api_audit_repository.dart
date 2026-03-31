import 'package:feature_audit/feature_audit.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Loads dedicated audit workspace data from the GDMS API.
final class ApiAuditRepository implements AuditRepository {
  const ApiAuditRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<AuditOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    final identity = _sessionViewModel.identity;
    if (session == null || identity == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final eventsJson = await _apiClient.getList(
      identity.isPlatformAdmin
          ? '/api/audit/events/recent?limit=100'
          : '/api/tenants/${session.tenantId}/audit/events/recent?limit=100',
    );
    final events = eventsJson.cast<Map<String, dynamic>>().map((item) {
      return AuditEventItem(
        tenantCode: item['tenantCode'] as String? ?? session.tenantCode,
        eventType: item['eventType'] as String? ?? 'UNKNOWN',
        severity: item['severity'] as String? ?? 'INFO',
        occurredAtLabel: ApiRepositoryFormatters.formatRelativeDate(
          DateTime.parse(item['occurredAtUtc'] as String).toUtc(),
        ),
      );
    }).toList(growable: false);

    return AuditOverview(
      totalEvents: events.length,
      criticalEvents: events.where((item) => item.severity == 'CRITICAL').length,
      warningEvents: events
          .where((item) => item.severity == 'WARNING' || item.severity == 'ERROR')
          .length,
      recentEvents: events,
    );
  }
}
