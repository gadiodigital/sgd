import 'search_result_item.dart';
import 'search_filters.dart';

/// Represents the current result set and counts of the search workspace.
final class SearchOverview {
  const SearchOverview({
    required this.query,
    required this.filters,
    required this.resultsCount,
    required this.results,
  });

  final String query;
  final SearchFilters filters;
  final int resultsCount;
  final List<SearchResultItem> results;
}
