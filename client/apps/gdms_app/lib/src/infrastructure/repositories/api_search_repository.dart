import 'package:feature_search/feature_search.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../config/application/firebase_runtime_state.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Connects the dedicated search workspace to the GDMS API.
final class ApiSearchRepository implements SearchRepository {
  ApiSearchRepository(
    this._apiClient,
    this._sessionViewModel,
    this._firebaseRuntimeState,
  );

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  final FirebaseRuntimeState _firebaseRuntimeState;

  @override
  Future<SearchOverview> search({
    required String query,
    required SearchFilters filters,
  }) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final trimmedQuery = query.trim();
    final hasFilters = filters.documentTypeCode.isNotEmpty ||
        filters.status.isNotEmpty ||
        filters.onlyOnLegalHold;
    if (trimmedQuery.isEmpty && !hasFilters) {
      return const SearchOverview(
        query: '',
        filters: SearchFilters(),
        resultsCount: 0,
        results: [],
      );
    }

    final limit = await _resolveSearchLimit();
    final buffer = StringBuffer('/api/tenants/$tenantId/documents/search?limit=$limit');
    if (trimmedQuery.isNotEmpty) {
      buffer.write('&query=${Uri.encodeQueryComponent(trimmedQuery)}');
    }
    if (filters.documentTypeCode.isNotEmpty) {
      buffer.write(
        '&documentTypeCode=${Uri.encodeQueryComponent(filters.documentTypeCode)}',
      );
    }
    if (filters.status.isNotEmpty) {
      buffer.write('&status=${Uri.encodeQueryComponent(filters.status)}');
    }
    if (filters.onlyOnLegalHold) {
      buffer.write('&onLegalHold=true');
    }
    final response = await _apiClient.getList(
      buffer.toString(),
    );
    final results = response.cast<Map<String, dynamic>>().map((item) {
      return SearchResultItem(
        id: item['id'] as String? ?? '',
        title: item['title'] as String? ?? 'Documento sin título',
        documentTypeCode: item['documentTypeCode'] as String? ?? 'UNKNOWN',
        status: item['status'] as String? ?? 'UNKNOWN',
        updatedAtLabel: ApiRepositoryFormatters.formatRelativeDate(
          DateTime.parse(item['createdAtUtc'] as String).toUtc(),
        ),
      );
    }).toList(growable: false);

    return SearchOverview(
      query: trimmedQuery,
      filters: filters,
      resultsCount: results.length,
      results: results,
    );
  }

  Future<int> _resolveSearchLimit() async {
    await _firebaseRuntimeState.ensureInitialized();
    if (!_firebaseRuntimeState.isAvailable) {
      return 25;
    }

    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults(const {'gdms_search_result_limit': 25});
    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {}

    final configured = remoteConfig.getInt('gdms_search_result_limit');
    return configured <= 0 ? 25 : configured;
  }
}
