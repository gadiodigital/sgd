import 'package:feature_sector_corporate/feature_sector_corporate.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../corporate/domain/corporate_record_file_document_reference.dart';
import '../../corporate/domain/corporate_record_file_reference.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Builds the corporate vertical dashboard from existing tenant APIs.
final class ApiCorporateDashboardRepository
    implements CorporateDashboardRepository {
  const ApiCorporateDashboardRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<CorporateDashboardOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final recordFilesJson = await _safeGetCorporateRecordFiles(session.tenantId);
    final workflowJson = await _apiClient.getList('/api/tenants/${session.tenantId}/workflow/tasks');
    final notificationsJson = await _apiClient.getList('/api/tenants/${session.tenantId}/notifications');

    final governanceTasks = workflowJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['status'] == 'OPEN')
        .toList(growable: false);
    final notifications = notificationsJson.cast<Map<String, dynamic>>();

    final records = <CorporateRecordItem>[
      ...recordFilesJson.cast<Map<String, dynamic>>().take(4).map((item) {
        return CorporateRecordItem(
          id: item['id'] as String? ?? '',
          title: item['title'] as String? ?? 'Legajo corporativo',
          subtitle:
              '${item['code'] ?? 'SIN-CODIGO'} · ${item['category'] ?? 'GENERAL'} · ${item['ownerArea'] ?? 'SIN_AREA'}',
          status: item['status'] as String? ?? 'ACTIVE',
        );
      }),
      ...governanceTasks.take(4).map((item) {
        final dueAtRaw = item['dueAtUtc'] as String?;
        final dueAtLabel = dueAtRaw == null
            ? 'Sin vencimiento'
            : ApiRepositoryFormatters.formatShortDate(
                DateTime.parse(dueAtRaw).toUtc(),
              );
        return CorporateRecordItem(
          title: item['title'] as String? ?? 'Tarea corporativa',
          subtitle: 'Workflow corporativo · $dueAtLabel',
          status: 'WARNING',
        );
      }),
      ...notifications.where((item) {
        final category = item['category'] as String? ?? '';
        return category == 'SECURITY' || category == 'WORKFLOW';
      }).take(4).map((item) {
        return CorporateRecordItem(
          title: item['title'] as String? ?? 'Alerta de control',
          subtitle: item['detail'] as String? ?? '',
          status: item['severity'] as String? ?? 'WARNING',
        );
      }),
    ];

    return CorporateDashboardOverview(
      activeContracts: recordFilesJson.length,
      pendingGovernanceTasks: governanceTasks.length,
      controlAlerts: notifications
          .where((item) => item['severity'] == 'CRITICAL' || item['severity'] == 'WARNING')
          .length,
      records: records,
    );
  }

  Future<void> createCorporateRecordFile({
    required String code,
    required String title,
    required String category,
    required String ownerArea,
  }) async {
    final session = _requireSession();
    await _apiClient.postObject(
      '/api/tenants/${session.tenantId}/corporate-record-files',
      {
        'code': code,
        'title': title,
        'category': category,
        'ownerArea': ownerArea,
      },
    );
  }

  Future<List<CorporateRecordFileReference>> loadCorporateRecordFiles() async {
    final session = _requireSession();
    final response = await _safeGetCorporateRecordFiles(session.tenantId);
    return response
        .cast<Map<String, dynamic>>()
        .map(CorporateRecordFileReference.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<CorporateRecordFileDocumentReference>>
  loadCorporateRecordFileDocuments(String corporateRecordFileId) async {
    final session = _requireSession();
    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/corporate-record-files/$corporateRecordFileId/documents',
    );
    return response
        .cast<Map<String, dynamic>>()
        .map(CorporateRecordFileDocumentReference.fromJson)
        .where((item) => item.documentId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> attachDocumentToCorporateRecordFile({
    required String corporateRecordFileId,
    required String documentId,
  }) async {
    final session = _requireSession();
    await _apiClient.postNoContent(
      '/api/tenants/${session.tenantId}/corporate-record-files/$corporateRecordFileId/documents',
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

  Future<List<dynamic>> _safeGetCorporateRecordFiles(String tenantId) async {
    try {
      return await _apiClient.getList(
        '/api/tenants/$tenantId/corporate-record-files',
      );
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        return const [];
      }

      rethrow;
    }
  }
}
