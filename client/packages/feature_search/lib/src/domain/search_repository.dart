import 'search_filters.dart';
import 'search_overview.dart';

/// Defines the contract used by the search workspace.
abstract interface class SearchRepository {
  Future<SearchOverview> search({
    required String query,
    required SearchFilters filters,
  });
}
