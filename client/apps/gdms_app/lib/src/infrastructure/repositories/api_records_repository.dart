import 'package:feature_records/feature_records.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Loads records-management metrics from the GDMS API.
final class ApiRecordsRepository implements RecordsRepository {
  const ApiRecordsRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<RecordsOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final policiesJson = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/records/retention-policies',
    );
    final candidatesJson = await _safeGetDispositionCandidates(
      session.tenantId,
    );
    final candidates = candidatesJson.cast<Map<String, dynamic>>();
    final now = DateTime.now().toUtc();
    final nextWeek = now.add(const Duration(days: 7));

    return RecordsOverview(
      policiesInUse: policiesJson
          .cast<Map<String, dynamic>>()
          .where((item) => item['isActive'] == true)
          .length,
      legalHoldsActive: candidates
          .where((item) => item['hasActiveLegalHold'] == true)
          .length,
      dueThisWeek: candidates.where((item) {
        final dueAt = DateTime.parse(item['dueAtUtc'] as String).toUtc();
        return dueAt.isBefore(nextWeek);
      }).length,
      pendingReview: candidates
          .where((item) => item['recommendedAction'] == 'REVIEW')
          .length,
      dispositionQueue: candidates.take(6).map((item) {
        final actionCode = item['recommendedAction'] as String;
        return DispositionItem(
          documentId: item['documentId'] as String,
          documentTitle: item['title'] as String,
          actionCode: actionCode,
          actionLabel: _formatActionLabel(actionCode),
          dueDateLabel: ApiRepositoryFormatters.formatShortDate(
            DateTime.parse(item['dueAtUtc'] as String),
          ),
          hasLegalHold: item['hasActiveLegalHold'] as bool,
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

  @override
  Future<void> executeDisposition(String documentId) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postNoContent(
      '/api/tenants/${session.tenantId}/records/documents/$documentId/disposition/execute',
      const {},
    );
  }

  String _formatActionLabel(String actionCode) {
    return switch (actionCode) {
      'ARCHIVE' => 'Archivar',
      'DELETE' => 'Eliminar',
      'REVIEW' => 'Revisión manual',
      _ => actionCode,
    };
  }
}
