import 'notification_item.dart';

/// Represents the current notifications inbox snapshot.
final class NotificationsOverview {
  const NotificationsOverview({
    required this.totalItems,
    required this.criticalItems,
    required this.warningItems,
    required this.items,
  });

  final int totalItems;
  final int criticalItems;
  final int warningItems;
  final List<NotificationItem> items;
}
