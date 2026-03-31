final class WindowsTwainServiceStatus {
  const WindowsTwainServiceStatus({
    required this.application,
    required this.version,
    required this.baseUrl,
    required this.runMode,
    required this.startupLogPath,
    required this.scannerSummary,
    required this.activeSessions,
    required this.sessionsRootPath,
    required this.lastCleanupAtUtc,
    required this.lastCleanupDeletedCount,
    required this.operations,
  });

  factory WindowsTwainServiceStatus.fromJson(Map<String, dynamic> json) {
    return WindowsTwainServiceStatus(
      application: (json['application'] as String? ?? '').trim(),
      version: (json['version'] as String? ?? '').trim(),
      baseUrl: (json['baseUrl'] as String? ?? '').trim(),
      runMode: (json['runMode'] as String? ?? '').trim(),
      startupLogPath: (json['startupLogPath'] as String? ?? '').trim(),
      scannerSummary: _scannerSummaryFrom(json['scanner']),
      activeSessions: _activeSessionsFrom(json['sessions']),
      sessionsRootPath: _sessionsRootPathFrom(json['sessions']),
      lastCleanupAtUtc: _lastCleanupAtUtcFrom(json['sessions']),
      lastCleanupDeletedCount: _lastCleanupDeletedCountFrom(json['sessions']),
      operations: _operationsFrom(json['operations']),
    );
  }

  final String application;
  final String version;
  final String baseUrl;
  final String runMode;
  final String startupLogPath;
  final String scannerSummary;
  final int activeSessions;
  final String sessionsRootPath;
  final DateTime? lastCleanupAtUtc;
  final int lastCleanupDeletedCount;
  final List<String> operations;

  bool supportsOperation(String operationId) =>
      operations.any((operation) => operation == operationId);

  static String _scannerSummaryFrom(Object? rawScanner) {
    if (rawScanner is String) {
      return rawScanner.trim();
    }
    if (rawScanner is Map<String, dynamic>) {
      final summary =
          rawScanner['message'] ??
          rawScanner['status'] ??
          rawScanner['transport'];
      if (summary is String && summary.trim().isNotEmpty) {
        return summary.trim();
      }
    }
    return '';
  }

  static List<String> _operationsFrom(Object? rawOperations) {
    if (rawOperations is! List<dynamic>) {
      return const [];
    }
    return rawOperations
        .map((entry) {
          if (entry is String) {
            return entry.trim();
          }
          if (entry is Map<String, dynamic>) {
            final availability = (entry['availability'] as String? ?? '')
                .trim()
                .toLowerCase();
            if (availability.isNotEmpty && availability != 'ready') {
              return '';
            }
            final operationId = entry['operationId'] ?? entry['id'];
            if (operationId is String) {
              return operationId.trim();
            }
          }
          return '';
        })
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static int _activeSessionsFrom(Object? rawSessions) {
    if (rawSessions is Map<String, dynamic>) {
      return rawSessions['activeSessions'] as int? ?? 0;
    }
    return 0;
  }

  static String _sessionsRootPathFrom(Object? rawSessions) {
    if (rawSessions is Map<String, dynamic>) {
      return (rawSessions['sessionsRootPath'] as String? ?? '').trim();
    }
    return '';
  }

  static int _lastCleanupDeletedCountFrom(Object? rawSessions) {
    if (rawSessions is Map<String, dynamic>) {
      return rawSessions['lastCleanupDeletedCount'] as int? ?? 0;
    }
    return 0;
  }

  static DateTime? _lastCleanupAtUtcFrom(Object? rawSessions) {
    if (rawSessions is Map<String, dynamic>) {
      final rawValue = (rawSessions['lastCleanupAtUtc'] as String? ?? '')
          .trim();
      if (rawValue.isEmpty) {
        return null;
      }
      return DateTime.tryParse(rawValue)?.toUtc();
    }
    return null;
  }
}
