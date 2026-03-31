final class ScanSessionSnapshot {
  const ScanSessionSnapshot({
    required this.sessionId,
    required this.status,
    required this.pageCount,
  });

  factory ScanSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return ScanSessionSnapshot(
      sessionId: (json['sessionId'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim().toLowerCase(),
      pageCount: json['pageCount'] as int? ?? 0,
    );
  }

  final String sessionId;
  final String status;
  final int pageCount;

  bool get isEmpty => pageCount <= 0 || status == 'empty';
}
