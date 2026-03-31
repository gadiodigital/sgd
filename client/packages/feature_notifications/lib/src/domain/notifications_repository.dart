import 'notifications_overview.dart';

/// Defines the read model used by the notifications inbox.
abstract interface class NotificationsRepository {
  Future<NotificationsOverview> loadOverview();
}
