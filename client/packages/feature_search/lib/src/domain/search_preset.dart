/// Represents a reusable search preset for common operational queries.
final class SearchPreset {
  const SearchPreset({
    required this.label,
    required this.query,
    required this.documentTypeCode,
    required this.status,
    required this.onlyOnLegalHold,
  });

  final String label;
  final String query;
  final String documentTypeCode;
  final String status;
  final bool onlyOnLegalHold;
}
