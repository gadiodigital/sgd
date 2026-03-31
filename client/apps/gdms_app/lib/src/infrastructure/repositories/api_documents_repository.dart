import 'package:feature_documents/feature_documents.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Loads document metrics and recent documents from the real GDMS API.
final class ApiDocumentsRepository implements DocumentsRepository {
  const ApiDocumentsRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<DocumentsOverview> loadOverview({String query = ''}) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final documentsJson = query.trim().isEmpty
        ? await _apiClient.getList('/api/tenants/${session.tenantId}/documents')
        : await _apiClient.getList(
            '/api/tenants/${session.tenantId}/documents/search?query='
            '${Uri.encodeQueryComponent(query.trim())}&limit=25',
          );
    final dispositionJson = await _safeGetDispositionCandidates(
      session.tenantId,
    );

    final documents = documentsJson.cast<Map<String, dynamic>>();
    final legalHoldDocumentIds = dispositionJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['hasActiveLegalHold'] == true)
        .map((item) => item['documentId'] as String)
        .toSet();

    final sortedDocuments = [...documents]
      ..sort(
        (left, right) => DateTime.parse(
          right['createdAtUtc'] as String,
        ).compareTo(DateTime.parse(left['createdAtUtc'] as String)),
      );

    return DocumentsOverview(
      activeDocuments: documents
          .where((item) => item['status'] != 'DISPOSED')
          .length,
      pendingClassification: documents
          .where((item) => item['status'] == 'DRAFT')
          .length,
      documentsOnHold: legalHoldDocumentIds.length,
      storageUsedLabel: '${documents.length} items',
      recentDocuments: sortedDocuments.take(6).map((item) {
        final documentId = item['id'] as String;
        return DocumentRecord(
          id: documentId,
          title: item['title'] as String,
          typeLabel: item['documentTypeCode'] as String,
          classificationLabel: item['documentTypeCode'] as String,
          statusLabel: item['status'] as String,
          ownerLabel: session.tenantCode,
          updatedAtLabel: ApiRepositoryFormatters.formatRelativeDate(
            DateTime.parse(item['createdAtUtc'] as String),
          ),
          onLegalHold: legalHoldDocumentIds.contains(documentId),
        );
      }).toList(),
    );
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
}
