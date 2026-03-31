import 'package:feature_integrations/feature_integrations.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';

/// Connects the integrations dashboard to the tenant integrations API.
final class ApiIntegrationsRepository implements IntegrationsRepository {
  const ApiIntegrationsRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<IntegrationsOverview> loadOverview() async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final response = await _apiClient.getList(
      '/api/tenants/$tenantId/integrations/status',
    );
    final items = response
        .cast<Map<String, dynamic>>()
        .map((item) {
          return IntegrationStatusItem(
            code: item['code'] as String? ?? 'UNKNOWN',
            displayName: item['displayName'] as String? ?? 'Integración',
            category: item['category'] as String? ?? 'UNKNOWN',
            status: item['status'] as String? ?? 'UNKNOWN',
            detail: item['detail'] as String? ?? '',
          );
        })
        .toList(growable: false);

    return IntegrationsOverview(
      readyCount: items
          .where((item) => item.status == 'READY' || item.status == 'EMULATOR')
          .length,
      warningCount: items
          .where((item) => item.status != 'READY' && item.status != 'EMULATOR')
          .length,
      items: items,
    );
  }
}
