/// Represents one immutable version of a document shown in the detail dialog.
final class DocumentVersionItem {
  const DocumentVersionItem({
    required this.versionNumber,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.fileHashPreview,
    required this.uploadedAtLabel,
  });

  final int versionNumber;
  final String mimeType;
  final int fileSizeBytes;
  final String fileHashPreview;
  final String uploadedAtLabel;
}
