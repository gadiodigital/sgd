import 'dart:typed_data';

/// Represents a downloaded binary payload returned by the GDMS API.
final class DownloadedBinaryFile {
  const DownloadedBinaryFile({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}
