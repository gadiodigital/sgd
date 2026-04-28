import 'package:feature_notifications/feature_notifications.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Connects the notifications inbox to the organization notifications API.
final class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<NotificationsOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final response = await _apiClient.getList('/api/organization/notifications');
    final items = response.cast<Map<String, dynamic>>().map((item) {
      return NotificationItem(
        category: item['category'] as String? ?? 'UNKNOWN',
        title: item['title'] as String? ?? 'Notificación',
        detail: item['detail'] as String? ?? '',
        severity: item['severity'] as String? ?? 'INFO',
        occurredAtLabel: ApiRepositoryFormatters.formatRelativeDate(
          DateTime.parse(item['occurredAtUtc'] as String).toUtc(),
        ),
      );
    }).toList(growable: false);

    return NotificationsOverview(
      totalItems: items.length,
      criticalItems: items.where((item) => item.severity == 'CRITICAL').length,
      warningItems: items
          .where((item) => item.severity == 'WARNING' || item.severity == 'ERROR')
          .length,
      items: items,
    );
  }
}
