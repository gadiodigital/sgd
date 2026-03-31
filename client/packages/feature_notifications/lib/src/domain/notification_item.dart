/// Represents one item rendered in the notifications inbox.
final class NotificationItem {
  const NotificationItem({
    required this.category,
    required this.title,
    required this.detail,
    required this.severity,
    required this.occurredAtLabel,
  });

  final String category;
  final String title;
  final String detail;
  final String severity;
  final String occurredAtLabel;
}
