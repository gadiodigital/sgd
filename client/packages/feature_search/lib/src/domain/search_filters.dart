/// Captures the current filters applied to the search workspace.
final class SearchFilters {
  const SearchFilters({
    this.documentTypeCode = '',
    this.status = '',
    this.onlyOnLegalHold = false,
  });

  final String documentTypeCode;
  final String status;
  final bool onlyOnLegalHold;
}
