import 'notification_item.dart';

/// Resolves the primary user-facing action label for a notification item.
final class NotificationCategoryActions {
  const NotificationCategoryActions._();

  static String labelFor(NotificationItem item) {
    return switch (item.category) {
      'WORKFLOW' => 'Abrir workflow',
      'SIGNATURE' => 'Abrir firma',
      'RECORDS' => 'Abrir records',
      'SECURITY' => 'Abrir auditoría',
      _ => 'Ver detalle',
    };
  }
}
