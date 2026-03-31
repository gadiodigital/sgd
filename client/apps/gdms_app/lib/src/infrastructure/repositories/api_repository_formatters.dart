/// Formats dates and labels for lightweight dashboard presentation.
final class ApiRepositoryFormatters {
  static String formatShortDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  static String formatRelativeDate(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    }

    if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    }

    if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    }

    return formatShortDate(local);
  }
}
