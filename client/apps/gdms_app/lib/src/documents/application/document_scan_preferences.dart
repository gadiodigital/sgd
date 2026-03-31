import '../domain/scan_source.dart';

final class DocumentScanPreferences {
  const DocumentScanPreferences({
    this.scannerName,
    this.lastSessionId,
    required this.source,
    required this.duplex,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
  });

  static const defaults = DocumentScanPreferences(
    source: ScanSource.adf,
    duplex: true,
    dpi: 300,
    pixelType: 'color',
    discardBlankPages: 'auto',
  );

  static DocumentScanPreferences _current = defaults;

  final String? scannerName;
  final String? lastSessionId;
  final ScanSource source;
  final bool duplex;
  final int dpi;
  final String pixelType;
  final String discardBlankPages;

  static DocumentScanPreferences get current => _current;

  static void save(DocumentScanPreferences preferences) {
    _current = preferences;
  }

  DocumentScanPreferences copyWith({
    String? scannerName,
    bool clearScannerName = false,
    String? lastSessionId,
    bool clearLastSessionId = false,
    ScanSource? source,
    bool? duplex,
    int? dpi,
    String? pixelType,
    String? discardBlankPages,
  }) {
    return DocumentScanPreferences(
      scannerName: clearScannerName ? null : (scannerName ?? this.scannerName),
      lastSessionId: clearLastSessionId
          ? null
          : (lastSessionId ?? this.lastSessionId),
      source: source ?? this.source,
      duplex: duplex ?? this.duplex,
      dpi: dpi ?? this.dpi,
      pixelType: pixelType ?? this.pixelType,
      discardBlankPages: discardBlankPages ?? this.discardBlankPages,
    );
  }
}
