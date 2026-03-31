import '../domain/active_scan_session.dart';

enum ScanDocumentSessionFilter {
  all,
  attention,
  rehydrated,
  stale,
  adf,
  flatbed,
}
enum ScanDocumentSessionSort {
  attentionFirst,
  recentActivity,
  oldestActivity,
  newest,
  largest,
}
enum ScanDocumentSessionStatusFilter { all, running, completed, error }
enum ScanDocumentSessionPageVolumeFilter { all, singlePage, smallBatch, largeBatch }
enum ScanDocumentSessionActivityFilter {
  all,
  last15Minutes,
  lastHour,
  olderThanHour,
}

final class ScanDocumentSessionSummary {
  const ScanDocumentSessionSummary({
    required this.totalSessions,
    required this.totalPages,
    required this.attentionSessions,
    required this.rehydratedSessions,
    required this.staleSessions,
    required this.completedSessions,
    required this.errorSessions,
    required this.runningSessions,
    required this.uniqueScanners,
    required this.primaryScannerLabel,
    required this.adfSessions,
    required this.flatbedSessions,
    required this.mostRecentActivityAtUtc,
    required this.oldestActivityAtUtc,
  });

  final int totalSessions;
  final int totalPages;
  final int attentionSessions;
  final int rehydratedSessions;
  final int staleSessions;
  final int completedSessions;
  final int errorSessions;
  final int runningSessions;
  final int uniqueScanners;
  final String primaryScannerLabel;
  final int adfSessions;
  final int flatbedSessions;
  final DateTime? mostRecentActivityAtUtc;
  final DateTime? oldestActivityAtUtc;
}

final class ScanDocumentActiveSessionsSupport {
  static List<ActiveScanSession> filterSessions(
    List<ActiveScanSession> sessions, {
    required ScanDocumentSessionFilter filter,
    required ScanDocumentSessionStatusFilter statusFilter,
    required ScanDocumentSessionSort sort,
    required ScanDocumentSessionPageVolumeFilter pageVolumeFilter,
    required ScanDocumentSessionActivityFilter activityFilter,
    required String selectedScanner,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedScanner = selectedScanner.trim().toLowerCase();
    return sessions
        .where((session) => _matchesFilter(session, filter))
        .where((session) => _matchesStatusFilter(session, statusFilter))
        .where((session) => _matchesPageVolumeFilter(session, pageVolumeFilter))
        .where((session) => _matchesActivityFilter(session, activityFilter))
        .where((session) => _matchesScanner(session, normalizedScanner))
        .where((session) => _matchesQuery(session, normalizedQuery))
        .toList(growable: false)
      ..sort((left, right) => _compareSessions(left, right, sort));
  }

  static ScanDocumentSessionSummary summarizeSessions(
    List<ActiveScanSession> sessions,
  ) {
    final scanners = <String, int>{};
    for (final session in sessions) {
      final scannerName = session.scannerName.trim();
      final key = scannerName.isEmpty ? 'Sin scanner' : scannerName;
      scanners.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    final topScanner = scanners.entries.fold<MapEntry<String, int>?>(
      null,
      (current, entry) =>
          current == null || entry.value > current.value ? entry : current,
    );
    final mostRecentActivity = sessions.isEmpty
        ? null
        : sessions
              .map((session) => session.lastTouchedAtUtc)
              .reduce((left, right) => left.isAfter(right) ? left : right);
    final oldestActivity = sessions.isEmpty
        ? null
        : sessions
              .map((session) => session.lastTouchedAtUtc)
              .reduce((left, right) => left.isBefore(right) ? left : right);
    return ScanDocumentSessionSummary(
      totalSessions: sessions.length,
      totalPages: sessions.fold(
        0,
        (pages, session) => pages + session.pageCount,
      ),
      attentionSessions: sessions.where(_requiresAttention).length,
      rehydratedSessions: sessions.where((session) => session.isRehydrated).length,
      staleSessions: sessions.where((session) => session.isStale).length,
      completedSessions: sessions
          .where((session) => session.status.toLowerCase() == 'completed')
          .length,
      errorSessions: sessions
          .where((session) => session.status.toLowerCase() == 'error')
          .length,
      runningSessions: sessions
          .where((session) => session.status.toLowerCase() == 'running')
          .length,
      uniqueScanners: scanners.length,
      primaryScannerLabel: topScanner?.key ?? 'sin dato',
      adfSessions: sessions.where((session) => session.isAdf).length,
      flatbedSessions: sessions.where((session) => session.isFlatbed).length,
      mostRecentActivityAtUtc: mostRecentActivity,
      oldestActivityAtUtc: oldestActivity,
    );
  }

  static bool _matchesFilter(
    ActiveScanSession session,
    ScanDocumentSessionFilter filter,
  ) {
    return switch (filter) {
      ScanDocumentSessionFilter.all => true,
      ScanDocumentSessionFilter.attention => _requiresAttention(session),
      ScanDocumentSessionFilter.rehydrated => session.isRehydrated,
      ScanDocumentSessionFilter.stale => session.isStale,
      ScanDocumentSessionFilter.adf => session.isAdf,
      ScanDocumentSessionFilter.flatbed => session.isFlatbed,
    };
  }

  static bool _matchesQuery(ActiveScanSession session, String query) {
    if (query.isEmpty) {
      return true;
    }
    return session.sessionId.toLowerCase().contains(query) ||
        session.scannerName.toLowerCase().contains(query) ||
        session.modeLabel.toLowerCase().contains(query) ||
        session.status.toLowerCase().contains(query);
  }

  static bool _matchesScanner(ActiveScanSession session, String scanner) {
    if (scanner.isEmpty) {
      return true;
    }
    return session.scannerName.trim().toLowerCase() == scanner;
  }

  static bool _matchesPageVolumeFilter(
    ActiveScanSession session,
    ScanDocumentSessionPageVolumeFilter filter,
  ) {
    return switch (filter) {
      ScanDocumentSessionPageVolumeFilter.all => true,
      ScanDocumentSessionPageVolumeFilter.singlePage => session.pageCount == 1,
      ScanDocumentSessionPageVolumeFilter.smallBatch =>
        session.pageCount >= 2 && session.pageCount <= 5,
      ScanDocumentSessionPageVolumeFilter.largeBatch => session.pageCount >= 6,
    };
  }

  static bool _matchesActivityFilter(
    ActiveScanSession session,
    ScanDocumentSessionActivityFilter filter,
  ) {
    final age = DateTime.now().toUtc().difference(session.lastTouchedAtUtc.toUtc());
    return switch (filter) {
      ScanDocumentSessionActivityFilter.all => true,
      ScanDocumentSessionActivityFilter.last15Minutes => age.inMinutes < 15,
      ScanDocumentSessionActivityFilter.lastHour => age.inHours < 1,
      ScanDocumentSessionActivityFilter.olderThanHour => age.inHours >= 1,
    };
  }

  static bool _matchesStatusFilter(
    ActiveScanSession session,
    ScanDocumentSessionStatusFilter statusFilter,
  ) {
    final normalized = session.status.toLowerCase();
    return switch (statusFilter) {
      ScanDocumentSessionStatusFilter.all => true,
      ScanDocumentSessionStatusFilter.running => normalized == 'running',
      ScanDocumentSessionStatusFilter.completed => normalized == 'completed',
      ScanDocumentSessionStatusFilter.error => normalized == 'error',
    };
  }

  static int _compareSessions(
    ActiveScanSession left,
    ActiveScanSession right,
    ScanDocumentSessionSort sort,
  ) {
    return switch (sort) {
      ScanDocumentSessionSort.attentionFirst => _compareAttentionFirst(
          left,
          right,
        ),
      ScanDocumentSessionSort.recentActivity => right.lastTouchedAtUtc
          .compareTo(left.lastTouchedAtUtc),
      ScanDocumentSessionSort.oldestActivity => left.lastTouchedAtUtc
          .compareTo(right.lastTouchedAtUtc),
      ScanDocumentSessionSort.newest => right.createdAtUtc.compareTo(
          left.createdAtUtc,
        ),
      ScanDocumentSessionSort.largest => right.pageCount.compareTo(
          left.pageCount,
        ),
    };
  }

  static bool requiresAttention(ActiveScanSession session) =>
      _requiresAttention(session);

  static String formatDateTime(DateTime value) {
    final localValue = value.toLocal();
    final day = localValue.day.toString().padLeft(2, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');
    return '$day/$month/${localValue.year} $hour:$minute';
  }

  static String statusLabel(String status) {
    return switch (status.trim().toLowerCase()) {
      'running' => 'Running',
      'completed' => 'Completed',
      'error' => 'Error',
      'empty' => 'Empty',
      'canceled' => 'Canceled',
      _ => status.trim().isEmpty ? 'Sin estado' : status.trim(),
    };
  }

  static bool _requiresAttention(ActiveScanSession session) {
    final normalized = session.status.trim().toLowerCase();
    return session.isStale ||
        session.isRehydrated ||
        normalized == 'error' ||
        normalized == 'empty' ||
        normalized == 'canceled';
  }

  static int _compareAttentionFirst(
    ActiveScanSession left,
    ActiveScanSession right,
  ) {
    final leftAttention = _requiresAttention(left);
    final rightAttention = _requiresAttention(right);
    if (leftAttention != rightAttention) {
      return rightAttention ? 1 : -1;
    }
    return right.lastTouchedAtUtc.compareTo(left.lastTouchedAtUtc);
  }
}
