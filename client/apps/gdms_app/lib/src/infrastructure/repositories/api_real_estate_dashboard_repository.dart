import 'package:feature_sector_real_estate/feature_sector_real_estate.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../real_estate/domain/property_file_document_reference.dart';
import '../../real_estate/domain/property_file_reference.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Builds the real-estate vertical dashboard from existing organization APIs.
final class ApiRealEstateDashboardRepository
    implements RealEstateDashboardRepository {
  const ApiRealEstateDashboardRepository(
    this._apiClient,
    this._sessionViewModel,
  );

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<RealEstateDashboardOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final propertyFilesJson = await _safeGetPropertyFiles(session.tenantId);
    final workflowJson = await _apiClient.getList(
      '/api/organization/workflow/tasks',
    );
    final notificationsJson = await _apiClient.getList(
      '/api/organization/notifications',
    );

    final openTasks = workflowJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['status'] == 'OPEN')
        .toList(growable: false);
    final notifications = notificationsJson.cast<Map<String, dynamic>>();

    final files = <RealEstateFileItem>[
      ...propertyFilesJson.cast<Map<String, dynamic>>().take(4).map((item) {
        return RealEstateFileItem(
          id: item['id'] as String? ?? '',
          title: item['title'] as String? ?? 'Legajo inmobiliario',
          subtitle:
              '${item['code'] ?? 'SIN-CODIGO'} · ${item['operationType'] ?? 'MIXED'} · ${item['address'] ?? 'Sin dirección'}',
          status: item['status'] as String? ?? 'ACTIVE',
        );
      }),
      ...openTasks.take(4).map((item) {
        final dueAtRaw = item['dueAtUtc'] as String?;
        final dueAtLabel = dueAtRaw == null
            ? 'Sin vencimiento'
            : ApiRepositoryFormatters.formatShortDate(
                DateTime.parse(dueAtRaw).toUtc(),
              );
        return RealEstateFileItem(
          title: item['title'] as String? ?? 'Aprobación pendiente',
          subtitle: 'Workflow inmobiliario · $dueAtLabel',
          status: 'WARNING',
        );
      }),
      ...notifications
          .where((item) {
            final category = item['category'] as String? ?? '';
            return category == 'RECORDS' || category == 'SECURITY';
          })
          .take(4)
          .map((item) {
            return RealEstateFileItem(
              title: item['title'] as String? ?? 'Alerta operativa',
              subtitle: item['detail'] as String? ?? '',
              status: item['severity'] as String? ?? 'WARNING',
            );
          }),
    ];

    return RealEstateDashboardOverview(
      activeFiles: propertyFilesJson.length,
      pendingApprovals: openTasks.length,
      complianceAlerts: notifications
          .where(
            (item) =>
                item['severity'] == 'CRITICAL' || item['severity'] == 'WARNING',
          )
          .length,
      files: files,
    );
  }

  Future<void> createPropertyFile({
    required String code,
    required String title,
    required String address,
    required String operationType,
  }) async {
    final session = _requireSession();
    await _apiClient.postObject(
      '/api/tenants/${session.tenantId}/property-files',
      {
        'code': code,
        'title': title,
        'address': address,
        'operationType': operationType,
      },
    );
  }

  Future<List<PropertyFileReference>> loadPropertyFiles() async {
    final session = _requireSession();
    final response = await _safeGetPropertyFiles(session.tenantId);
    return response
        .cast<Map<String, dynamic>>()
        .map(PropertyFileReference.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<PropertyFileDocumentReference>> loadPropertyFileDocuments(
    String propertyFileId,
  ) async {
    final session = _requireSession();
    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/property-files/$propertyFileId/documents',
    );
    return response
        .cast<Map<String, dynamic>>()
        .map(PropertyFileDocumentReference.fromJson)
        .where((item) => item.documentId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> attachDocumentToPropertyFile({
    required String propertyFileId,
    required String documentId,
  }) async {
    final session = _requireSession();
    await _apiClient.postNoContent(
      '/api/tenants/${session.tenantId}/property-files/$propertyFileId/documents',
      {'documentId': documentId},
    );
  }

  dynamic _requireSession() {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    return session;
  }

  Future<List<dynamic>> _safeGetPropertyFiles(String tenantId) async {
    try {
      return await _apiClient.getList('/api/tenants/$tenantId/property-files');
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        return const [];
      }

      rethrow;
    }
  }
}
