final class ScanSessionDetails {
  const ScanSessionDetails({
    required this.sessionId,
    required this.status,
    required this.mode,
    required this.pageCount,
    required this.scannerName,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
  });

  factory ScanSessionDetails.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'];
    final settingsMap = settings is Map<String, dynamic>
        ? settings
        : const <String, dynamic>{};
    return ScanSessionDetails(
      sessionId: (json['sessionId'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      mode: (json['mode'] as String? ?? '').trim(),
      pageCount: json['pageCount'] as int? ?? 0,
      scannerName: (json['scannerName'] as String? ?? '').trim(),
      dpi: _asInt(settingsMap['dpi']),
      pixelType: (settingsMap['pixelType'] as String? ?? '').trim(),
      discardBlankPages: (settingsMap['discardBlankPages'] as String? ?? '')
          .trim(),
    );
  }

  final String sessionId;
  final String status;
  final String mode;
  final int pageCount;
  final String scannerName;
  final int? dpi;
  final String pixelType;
  final String discardBlankPages;

  bool get isFlatbed => mode.toLowerCase().startsWith('flatbed');
  bool get isAdf => mode.toLowerCase().startsWith('adf');

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return null;
  }
}
