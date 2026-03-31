import '../../auth/application/app_session_view_model.dart';
import '../../documents/domain/document_access_entry_record.dart';
import '../../documents/domain/document_access_user_option.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';

/// Loads and grants explicit document ACL entries against the GDMS API.
final class ApiDocumentAccessRepository {
  const ApiDocumentAccessRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  Future<List<DocumentAccessEntryRecord>> loadEntries(String documentId) async {
    final session = _requireSession();
    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/documents/$documentId/access-entries',
    );
    return response
        .cast<Map<String, dynamic>>()
        .map((item) {
          final grantedAt = DateTime.tryParse(
            item['grantedAtUtc'] as String? ?? '',
          );
          return DocumentAccessEntryRecord(
            id: item['id'] as String? ?? '',
            userId: item['userId'] as String? ?? '',
            permissionCode: item['permissionCode'] as String? ?? 'READ',
            grantedAtLabel: _formatDate(grantedAt),
          );
        })
        .toList(growable: false);
  }

  Future<List<DocumentAccessUserOption>> loadTenantUsers() async {
    final session = _requireSession();
    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/users',
    );
    return response
        .cast<Map<String, dynamic>>()
        .map((item) {
          return DocumentAccessUserOption(
            id: item['id'] as String? ?? '',
            fullName: item['fullName'] as String? ?? 'Usuario',
            email: item['email'] as String? ?? '',
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> grant({
    required String documentId,
    required String userId,
    required String permissionCode,
  }) async {
    final session = _requireSession();
    await _apiClient.postObject(
      '/api/tenants/${session.tenantId}/documents/$documentId/access-entries',
      {'userId': userId, 'permissionCode': permissionCode},
    );
  }

  dynamic _requireSession() {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }
    return session;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Sin fecha';
    }

    final localValue = value.toLocal();
    return '${localValue.day.toString().padLeft(2, '0')}/'
        '${localValue.month.toString().padLeft(2, '0')}/${localValue.year}';
  }
}
