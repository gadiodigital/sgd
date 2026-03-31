/// Represents an active retention policy available for assignment in the UI.
final class RetentionPolicyOption {
  const RetentionPolicyOption({
    required this.code,
    required this.name,
    required this.retentionDays,
    required this.dispositionAction,
  });

  factory RetentionPolicyOption.fromJson(Map<String, dynamic> json) {
    return RetentionPolicyOption(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      retentionDays: json['retentionDays'] as int? ?? 0,
      dispositionAction: json['dispositionAction'] as String? ?? '',
    );
  }

  final String code;
  final String name;
  final int retentionDays;
  final String dispositionAction;

  String get displayLabel => '$name ($code)';
}
