import 'package:flutter_test/flutter_test.dart';

import 'package:feature_search/feature_search.dart';

void main() {
  test('load usa filtros actuales y guarda busquedas sin duplicar', () async {
    final repository = _RecordingSearchRepository();
    final viewModel = SearchViewModel(repository);

    viewModel.updateQuery('contrato');
    viewModel.updateDocumentTypeCode(' contract ');
    viewModel.updateStatus(' active ');
    viewModel.updateOnlyOnLegalHold(true);
    await viewModel.load();

    expect(repository.requests.length, 1);
    expect(repository.requests.single.query, 'contrato');
    expect(repository.requests.single.filters.documentTypeCode, 'CONTRACT');
    expect(repository.requests.single.filters.status, 'ACTIVE');
    expect(repository.requests.single.filters.onlyOnLegalHold, isTrue);
    expect(viewModel.message, 'Se encontraron 1 resultados.');

    viewModel.saveCurrentSearch();
    expect(viewModel.savedSearches.length, 1);
    expect(viewModel.savedSearches.first.label, 'Busqueda: contrato');

    viewModel.saveCurrentSearch();
    expect(viewModel.savedSearches.length, 1);
    expect(viewModel.message, 'La búsqueda actual ya estaba guardada.');

    viewModel.clearFilters();
    expect(viewModel.query, isEmpty);
    expect(viewModel.documentTypeCode, isEmpty);
    expect(viewModel.status, isEmpty);
    expect(viewModel.onlyOnLegalHold, isFalse);
  });

  test('applyPreset y applySavedSearch recompone filtros visibles', () async {
    final viewModel = SearchViewModel(_RecordingSearchRepository());

    viewModel.applyPreset(viewModel.presets.first);
    expect(viewModel.documentTypeCode, 'CONTRACT');
    expect(viewModel.status, 'ACTIVE');

    viewModel.saveCurrentSearch();
    viewModel.clearFilters();
    viewModel.applySavedSearch(viewModel.savedSearches.first);

    expect(viewModel.documentTypeCode, 'CONTRACT');
    expect(viewModel.status, 'ACTIVE');

    viewModel.removeSavedSearch(viewModel.savedSearches.first);
    expect(viewModel.savedSearches, isEmpty);
  });
}

final class _RecordingSearchRepository implements SearchRepository {
  final List<_SearchRequest> requests = <_SearchRequest>[];

  @override
  Future<SearchOverview> search({
    required String query,
    required SearchFilters filters,
  }) async {
    requests.add(_SearchRequest(query: query, filters: filters));
    return SearchOverview(
      query: query,
      filters: filters,
      resultsCount: 1,
      results: const [
        SearchResultItem(
          id: 'doc-1',
          title: 'Contrato comercial',
          documentTypeCode: 'CONTRACT',
          status: 'ACTIVE',
          updatedAtLabel: 'Hoy',
        ),
      ],
    );
  }
}

final class _SearchRequest {
  const _SearchRequest({required this.query, required this.filters});

  final String query;
  final SearchFilters filters;
}
