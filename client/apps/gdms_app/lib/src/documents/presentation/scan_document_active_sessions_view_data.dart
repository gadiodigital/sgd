import '../domain/active_scan_session.dart';
import 'scan_document_active_sessions_labels.dart';
import 'scan_document_active_sessions_preset.dart';
import 'scan_document_active_sessions_preset_support.dart';
import 'scan_document_active_sessions_priority.dart';
import 'scan_document_active_sessions_support.dart';

final class ScanDocumentActiveSessionsViewData {
  const ScanDocumentActiveSessionsViewData({
    required this.filteredSessions,
    required this.presetAvailabilities,
    required this.recommendedPreset,
    required this.summary,
    required this.activePreset,
    required this.scannerOptions,
    required this.activeFilterLabels,
    required this.visibleSessions,
    required this.prioritySessionId,
    required this.prioritySession,
    required this.attentionSessions,
    required this.errorSessions,
    required this.runningSessions,
    required this.firstAttentionSessionId,
  });

  final List<ActiveScanSession> filteredSessions;
  final List<ScanDocumentActiveSessionsPresetAvailability> presetAvailabilities;
  final ScanDocumentActiveSessionsPresetRecommendation? recommendedPreset;
  final ScanDocumentSessionSummary summary;
  final ScanDocumentActiveSessionsPresetConfig? activePreset;
  final List<String> scannerOptions;
  final List<String> activeFilterLabels;
  final List<ActiveScanSession> visibleSessions;
  final String? prioritySessionId;
  final ActiveScanSession? prioritySession;
  final List<ActiveScanSession> attentionSessions;
  final List<ActiveScanSession> errorSessions;
  final List<ActiveScanSession> runningSessions;
  final String? firstAttentionSessionId;
}

final class ScanDocumentActiveSessionsViewDataResolver {
  static ScanDocumentActiveSessionsViewData resolve({
    required List<ActiveScanSession> sessions,
    required ScanDocumentSessionFilter filter,
    required ScanDocumentSessionStatusFilter statusFilter,
    required ScanDocumentSessionPageVolumeFilter pageVolumeFilter,
    required ScanDocumentSessionActivityFilter activityFilter,
    required ScanDocumentSessionSort sort,
    required ScanDocumentActiveSessionsPreset? selectedPreset,
    required String selectedScanner,
    required String query,
    required bool showAllSessions,
  }) {
    final filteredSessions = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: filter,
      statusFilter: statusFilter,
      sort: sort,
      pageVolumeFilter: pageVolumeFilter,
      activityFilter: activityFilter,
      selectedScanner: selectedScanner,
      query: query,
    );
    final presetAvailabilities =
        ScanDocumentActiveSessionsPresetSupport.resolveAvailabilities(sessions);
    final recommendedPreset = ScanDocumentActiveSessionsPresetSupport
        .recommendPreset(presetAvailabilities);
    final activePreset = ScanDocumentActiveSessionsPresetCatalog.findById(
      selectedPreset,
    );
    final scannerOptions = sessions
        .map((session) => session.scannerName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final activeFilterLabels = <String>[
      if (filter != ScanDocumentSessionFilter.all)
        ScanDocumentActiveSessionsLabels.filterLabel(filter),
      if (statusFilter != ScanDocumentSessionStatusFilter.all)
        ScanDocumentActiveSessionsLabels.statusFilterLabel(statusFilter),
      if (pageVolumeFilter != ScanDocumentSessionPageVolumeFilter.all)
        ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(pageVolumeFilter),
      if (activityFilter != ScanDocumentSessionActivityFilter.all)
        ScanDocumentActiveSessionsLabels.activityFilterLabel(activityFilter),
      if (sort != ScanDocumentSessionSort.recentActivity)
        ScanDocumentActiveSessionsLabels.sortLabel(sort),
      if (selectedScanner.isNotEmpty)
        ScanDocumentActiveSessionsLabels.scannerFilterLabel(selectedScanner),
      if (query.trim().isNotEmpty)
        ScanDocumentActiveSessionsLabels.queryFilterLabel(query.trim()),
    ];
    final visibleSessions = showAllSessions
        ? filteredSessions
        : filteredSessions.take(6).toList(growable: false);
    final prioritySessionId = resolvePrioritySessionId(visibleSessions);
    final prioritySession = prioritySessionId == null
        ? null
        : visibleSessions.firstWhere(
            (session) => session.sessionId == prioritySessionId,
          );
    final attentionSessions = filteredSessions
        .where(ScanDocumentActiveSessionsSupport.requiresAttention)
        .toList(growable: false);
    final errorSessions = filteredSessions
        .where((session) => session.status.trim().toLowerCase() == 'error')
        .toList(growable: false);
    final runningSessions = filteredSessions
        .where((session) => session.status.trim().toLowerCase() == 'running')
        .toList(growable: false);
    return ScanDocumentActiveSessionsViewData(
      filteredSessions: filteredSessions,
      presetAvailabilities: presetAvailabilities,
      recommendedPreset: recommendedPreset,
      summary: ScanDocumentActiveSessionsSupport.summarizeSessions(
        filteredSessions,
      ),
      activePreset: activePreset,
      scannerOptions: scannerOptions,
      activeFilterLabels: activeFilterLabels,
      visibleSessions: visibleSessions,
      prioritySessionId: prioritySessionId,
      prioritySession: prioritySession,
      attentionSessions: attentionSessions,
      errorSessions: errorSessions,
      runningSessions: runningSessions,
      firstAttentionSessionId: attentionSessions.firstOrNull?.sessionId,
    );
  }
}
