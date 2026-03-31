final class ActiveScanSession {
  const ActiveScanSession({
    required this.sessionId,
    required this.createdAtUtc,
    required this.lastTouchedAtUtc,
    required this.scannerName,
    required this.mode,
    required this.status,
    required this.pageCount,
    required this.isRehydrated,
  });

  factory ActiveScanSession.fromJson(Map<String, dynamic> json) {
    return ActiveScanSession(
      sessionId: (json['sessionId'] as String? ?? '').trim(),
      createdAtUtc:
          DateTime.tryParse((json['createdAtUtc'] as String? ?? '').trim())
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastTouchedAtUtc:
          DateTime.tryParse((json['lastTouchedAtUtc'] as String? ?? '').trim())
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      scannerName: (json['scannerName'] as String? ?? '').trim(),
      mode: (json['mode'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      pageCount: json['pageCount'] as int? ?? 0,
      isRehydrated: json['isRehydrated'] as bool? ?? false,
    );
  }

  final String sessionId;
  final DateTime createdAtUtc;
  final DateTime lastTouchedAtUtc;
  final String scannerName;
  final String mode;
  final String status;
  final int pageCount;
  final bool isRehydrated;

  bool get isAdf => mode.toLowerCase().startsWith('adf');
  bool get isFlatbed => mode.toLowerCase().startsWith('flatbed');
  bool get isFinished {
    final normalized = status.toLowerCase();
    return normalized == 'completed' ||
        normalized == 'empty' ||
        normalized == 'canceled' ||
        normalized == 'error';
  }
  bool get isDormant =>
      DateTime.now().toUtc().difference(lastTouchedAtUtc.toUtc()).inMinutes >=
      15;
  bool get isStale =>
      DateTime.now().toUtc().difference(lastTouchedAtUtc.toUtc()).inHours >= 2;

  String get modeLabel {
    final normalized = mode.toLowerCase();
    if (normalized == 'flatbed-single') return 'Cama plana';
    if (normalized == 'adf-duplex') return 'ADF duplex';
    if (normalized == 'adf-simplex') return 'ADF simplex';
    return mode.isEmpty ? 'sin dato' : mode;
  }
}
