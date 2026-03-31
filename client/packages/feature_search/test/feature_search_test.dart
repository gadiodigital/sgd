import 'package:flutter_test/flutter_test.dart';

import 'package:feature_search/feature_search.dart';

void main() {
  test('loads search overview data', () async {
    final viewModel = SearchViewModel(_FakeSearchRepository());

    viewModel.applyPreset(viewModel.presets.first);
    await viewModel.load();

    expect(viewModel.overview?.resultsCount, 1);
    expect(viewModel.documentTypeCode, 'CONTRACT');
    expect(viewModel.status, 'ACTIVE');

    viewModel.saveCurrentSearch();
    expect(viewModel.savedSearches.length, 1);

    viewModel.clearFilters();
    viewModel.applySavedSearch(viewModel.savedSearches.first);
    expect(viewModel.documentTypeCode, 'CONTRACT');
  });
}

final class _FakeSearchRepository implements SearchRepository {
  @override
  Future<SearchOverview> search({
    required String query,
    required SearchFilters filters,
  }) async {
    return SearchOverview(
      query: query,
      filters: filters,
      resultsCount: 1,
      results: const [
        SearchResultItem(
          id: '1',
          title: 'Contrato comercial',
          documentTypeCode: 'CONTRACT',
          status: 'ACTIVE',
          updatedAtLabel: 'Hoy',
        ),
      ],
    );
  }
}
