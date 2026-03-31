final class ScannedDocumentFile {
  const ScannedDocumentFile({
    required this.sessionId,
    required this.fileName,
    required this.bytes,
    required this.pageCount,
    required this.scannerName,
  });

  final String sessionId;
  final String fileName;
  final List<int> bytes;
  final int pageCount;
  final String scannerName;

  ScannedDocumentFile copyWith({
    String? sessionId,
    String? fileName,
    List<int>? bytes,
    int? pageCount,
    String? scannerName,
  }) {
    return ScannedDocumentFile(
      sessionId: sessionId ?? this.sessionId,
      fileName: fileName ?? this.fileName,
      bytes: bytes ?? this.bytes,
      pageCount: pageCount ?? this.pageCount,
      scannerName: scannerName ?? this.scannerName,
    );
  }
}
