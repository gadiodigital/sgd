/// Represents one document returned by the dedicated search workspace.
final class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.documentTypeCode,
    required this.status,
    required this.updatedAtLabel,
  });

  final String id;
  final String title;
  final String documentTypeCode;
  final String status;
  final String updatedAtLabel;
}
