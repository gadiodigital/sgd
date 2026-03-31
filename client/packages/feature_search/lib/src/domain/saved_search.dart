import 'search_filters.dart';

/// Represents one saved search snapshot reusable in the current session.
final class SavedSearch {
  const SavedSearch({
    required this.label,
    required this.query,
    required this.filters,
  });

  final String label;
  final String query;
  final SearchFilters filters;
}
