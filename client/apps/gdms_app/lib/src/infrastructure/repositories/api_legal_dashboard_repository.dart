import 'package:feature_sector_legal/feature_sector_legal.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../legal/domain/case_file_document_reference.dart';
import '../../legal/domain/case_file_reference.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Builds the legal vertical dashboard from existing tenant APIs.
final class ApiLegalDashboardRepository implements LegalDashboardRepository {
  const ApiLegalDashboardRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<LegalDashboardOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final workflowJson = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/workflow/tasks',
    );
    final dispositionJson = await _safeGetDispositionCandidates(
      session.tenantId,
    );
    final auditJson = await _safeGetAuditEvents(session.tenantId);
    final caseFilesJson = await _safeGetCaseFiles(session.tenantId);

    final openTasks = workflowJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['status'] == 'OPEN')
        .toList(growable: false);
    final dueEvidenceReviews = dispositionJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['hasActiveLegalHold'] == true)
        .length;
    final failedLogins24h = auditJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['eventType'] == 'LOGIN_FAILED')
        .length;

    final matters = <LegalMatterItem>[
      ...caseFilesJson.cast<Map<String, dynamic>>().take(4).map((item) {
        return LegalMatterItem(
          title: item['title'] as String? ?? 'Expediente',
          subtitle:
              '${item['code'] ?? 'SIN-CODIGO'} · ${item['category'] ?? 'GENERAL'}',
          status: item['status'] as String? ?? 'OPEN',
        );
      }),
      ...openTasks.take(4).map((item) {
        final dueAtRaw = item['dueAtUtc'] as String?;
        final dueAtLabel = dueAtRaw == null
            ? 'Sin vencimiento'
            : ApiRepositoryFormatters.formatShortDate(
                DateTime.parse(dueAtRaw).toUtc(),
              );
        return LegalMatterItem(
          title: item['title'] as String? ?? 'Tarea jurídica',
          subtitle: 'Workflow pendiente · $dueAtLabel',
          status: 'WARNING',
        );
      }),
      ...dispositionJson
          .cast<Map<String, dynamic>>()
          .where((item) {
            return item['hasActiveLegalHold'] == true;
          })
          .take(4)
          .map((item) {
            return LegalMatterItem(
              title: item['title'] as String? ?? 'Evidencia retenida',
              subtitle: 'Legal hold activo sobre disposición pendiente',
              status: 'CRITICAL',
            );
          }),
    ];

    return LegalDashboardOverview(
      openTasks: openTasks.length,
      dueEvidenceReviews: dueEvidenceReviews,
      failedLogins24h: failedLogins24h,
      caseFiles: caseFilesJson
          .cast<Map<String, dynamic>>()
          .take(6)
          .map(
            (item) => LegalCaseFileItem(
              id: item['id'] as String? ?? '',
              title: item['title'] as String? ?? 'Expediente',
              subtitle:
                  '${item['code'] ?? 'SIN-CODIGO'} · ${item['category'] ?? 'GENERAL'}',
              status: item['status'] as String? ?? 'OPEN',
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
      matters: matters,
    );
  }

  Future<void> createCaseFile({
    required String code,
    required String title,
    required String category,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postObject('/api/tenants/${session.tenantId}/cases', {
      'code': code,
      'title': title,
      'category': category,
    });
  }

  Future<List<CaseFileReference>> loadCaseFiles() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/cases',
    );
    return response
        .cast<Map<String, dynamic>>()
        .map(CaseFileReference.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> attachDocumentToCaseFile({
    required String caseFileId,
    required String documentId,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postNoContent(
      '/api/tenants/${session.tenantId}/cases/$caseFileId/documents',
      {'documentId': documentId},
    );
  }

  Future<List<CaseFileDocumentReference>> loadCaseFileDocuments(
    String caseFileId,
  ) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/cases/$caseFileId/documents',
    );
    return response
        .cast<Map<String, dynamic>>()
        .map(CaseFileDocumentReference.fromJson)
        .where((item) => item.documentId.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<dynamic>> _safeGetDispositionCandidates(String tenantId) async {
    try {
      return await _apiClient.getList(
        '/api/tenants/$tenantId/records/disposition-candidates',
      );
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        return const [];
      }

      rethrow;
    }
  }

  Future<List<dynamic>> _safeGetAuditEvents(String tenantId) async {
    try {
      return await _apiClient.getList(
        '/api/tenants/$tenantId/audit/events/recent?limit=50',
      );
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        return const [];
      }

      rethrow;
    }
  }

  Future<List<dynamic>> _safeGetCaseFiles(String tenantId) async {
    try {
      return await _apiClient.getList('/api/tenants/$tenantId/cases');
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        return const [];
      }

      rethrow;
    }
  }
}
