/// Represents a legal hold shown in the records management dialog.
final class LegalHoldEntry {
  const LegalHoldEntry({
    required this.id,
    required this.reason,
    required this.isActive,
    required this.createdAtUtc,
    this.releaseReason,
  });

  factory LegalHoldEntry.fromJson(Map<String, dynamic> json) {
    return LegalHoldEntry(
      id: json['id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      isActive: json['isActive'] == true,
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      releaseReason: json['releaseReason'] as String?,
    );
  }

  final String id;
  final String reason;
  final bool isActive;
  final DateTime createdAtUtc;
  final String? releaseReason;
}
