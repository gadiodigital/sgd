import 'package:flutter/material.dart';

import '../domain/active_scan_session.dart';
import 'scan_document_active_sessions_active_filters_summary.dart';
import 'scan_document_active_sessions_actions.dart';
import 'scan_document_active_session_card.dart';
import 'scan_document_active_sessions_clipboard.dart';
import 'scan_document_active_session_details_dialog.dart';
import 'scan_document_active_sessions_filters_panel.dart';
import 'scan_document_active_sessions_labels.dart';
import 'scan_document_active_sessions_preset.dart';
import 'scan_document_active_sessions_support.dart';
import 'scan_document_active_sessions_summary.dart';
import 'scan_document_active_sessions_view_data.dart';
import 'scan_document_active_sessions_visibility_toggle.dart';
class ScanDocumentActiveSessions extends StatefulWidget {
  const ScanDocumentActiveSessions({
    required this.sessions,
    required this.isBusy,
    required this.currentSessionId,
    required this.onResumeRequested,
    required this.onDiscardRequested,
    required this.onDiscardManyRequested,
    required this.onExportVisibleRequested,
    super.key,
  });

  final List<ActiveScanSession> sessions;
  final bool isBusy;
  final String? currentSessionId;
  final ValueChanged<String> onResumeRequested;
  final ValueChanged<String> onDiscardRequested;
  final ValueChanged<List<String>> onDiscardManyRequested;
  final ValueChanged<List<ActiveScanSession>> onExportVisibleRequested;

  @override
  State<ScanDocumentActiveSessions> createState() =>
      _ScanDocumentActiveSessionsState();
}
class _ScanDocumentActiveSessionsState extends State<ScanDocumentActiveSessions> {
  ScanDocumentSessionFilter _filter = ScanDocumentSessionFilter.all;
  ScanDocumentSessionStatusFilter _statusFilter =
      ScanDocumentSessionStatusFilter.all;
  ScanDocumentSessionPageVolumeFilter _pageVolumeFilter =
      ScanDocumentSessionPageVolumeFilter.all;
  ScanDocumentSessionActivityFilter _activityFilter =
      ScanDocumentSessionActivityFilter.all;
  ScanDocumentActiveSessionsPreset? _selectedPreset;
  ScanDocumentSessionSort _sort = ScanDocumentSessionSort.recentActivity;
  String _selectedScanner = '';
  String _query = '';
  bool _showAllSessions = false;

  void _applyPreset(ScanDocumentActiveSessionsPresetConfig preset) {
    setState(() {
      _selectedPreset = preset.id;
      _filter = preset.filter;
      _statusFilter = preset.statusFilter;
      _pageVolumeFilter = preset.pageVolumeFilter;
      _activityFilter = preset.activityFilter;
      _selectedScanner = '';
      _query = '';
    });
  }

  void _clearPresetSelection() {
    if (_selectedPreset == null) {
      return;
    }
    setState(() => _selectedPreset = null);
  }

  void _clearActivePreset() {
    _resetFiltersToDefault();
  }

  void _removeActiveFilterLabel(String label) {
    _clearPresetSelection();
    setState(() {
      if (label == ScanDocumentActiveSessionsLabels.filterLabel(_filter)) _filter = ScanDocumentSessionFilter.all;
      if (label == ScanDocumentActiveSessionsLabels.statusFilterLabel(_statusFilter)) _statusFilter = ScanDocumentSessionStatusFilter.all;
      if (label == ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(_pageVolumeFilter)) _pageVolumeFilter = ScanDocumentSessionPageVolumeFilter.all;
      if (label == ScanDocumentActiveSessionsLabels.activityFilterLabel(_activityFilter)) _activityFilter = ScanDocumentSessionActivityFilter.all;
      if (label == ScanDocumentActiveSessionsLabels.sortLabel(_sort)) _sort = ScanDocumentSessionSort.recentActivity;
      if (label == ScanDocumentActiveSessionsLabels.scannerFilterLabel(_selectedScanner)) _selectedScanner = '';
      if (label == ScanDocumentActiveSessionsLabels.queryFilterLabel(_query.trim())) _query = '';
    });
  }
  bool get _isDefaultView => _selectedPreset == null && _filter == ScanDocumentSessionFilter.all && _statusFilter == ScanDocumentSessionStatusFilter.all && _pageVolumeFilter == ScanDocumentSessionPageVolumeFilter.all && _activityFilter == ScanDocumentSessionActivityFilter.all && _sort == ScanDocumentSessionSort.recentActivity && _selectedScanner.isEmpty && _query.isEmpty;
  void _resetFiltersToDefault() {
    setState(() {
      _selectedPreset = null;
      _filter = ScanDocumentSessionFilter.all;
      _statusFilter = ScanDocumentSessionStatusFilter.all;
      _pageVolumeFilter = ScanDocumentSessionPageVolumeFilter.all;
      _activityFilter = ScanDocumentSessionActivityFilter.all;
      _sort = ScanDocumentSessionSort.recentActivity;
      _selectedScanner = '';
      _query = '';
    });
  }
  Future<void> _showSessionDetails(ActiveScanSession session) {
    return showDialog<void>(
      context: context,
      builder: (context) => ScanDocumentActiveSessionDetailsDialog(
        session: session,
        isCurrent: widget.currentSessionId == session.sessionId,
        isBusy: widget.isBusy,
        onResumeRequested: widget.onResumeRequested,
        onDiscardRequested: widget.onDiscardRequested,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('No hay sesiones activas en el host local.'),
      );
    }

    final viewData = ScanDocumentActiveSessionsViewDataResolver.resolve(
      sessions: widget.sessions,
      filter: _filter,
      statusFilter: _statusFilter,
      pageVolumeFilter: _pageVolumeFilter,
      activityFilter: _activityFilter,
      sort: _sort,
      selectedPreset: _selectedPreset,
      selectedScanner: _selectedScanner,
      query: _query,
      showAllSessions: _showAllSessions,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Sesiones activas'),
        ),
        const SizedBox(height: 8),
        ScanDocumentActiveSessionsFiltersPanel(
          isBusy: widget.isBusy,
          query: _query,
          onQueryChanged: (value) {
            _clearPresetSelection();
            setState(() => _query = value);
          },
          presetAvailabilities: viewData.presetAvailabilities,
          recommendedPreset: viewData.recommendedPreset,
          selectedPreset: _selectedPreset,
          isCustomState: !_isDefaultView,
          onResetRequested: _resetFiltersToDefault,
          onPresetSelected: _applyPreset,
          filter: _filter,
          onFilterChanged: (value) {
            _clearPresetSelection();
            setState(() => _filter = value);
          },
          statusFilter: _statusFilter,
          onStatusFilterChanged: (value) {
            _clearPresetSelection();
            setState(() => _statusFilter = value);
          },
          pageVolumeFilter: _pageVolumeFilter,
          onPageVolumeFilterChanged: (value) {
            _clearPresetSelection();
            setState(() => _pageVolumeFilter = value);
          },
          activityFilter: _activityFilter,
          onActivityFilterChanged: (value) {
            _clearPresetSelection();
            setState(() => _activityFilter = value);
          },
          scannerOptions: viewData.scannerOptions,
          selectedScanner: _selectedScanner,
          onScannerChanged: (value) {
            _clearPresetSelection();
            setState(() => _selectedScanner = value);
          },
          sort: _sort,
          onSortChanged: (value) {
            _clearPresetSelection();
            setState(() => _sort = value);
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ScanDocumentActiveSessionsActiveFiltersSummary(
            filters: viewData.activeFilterLabels,
            activePresetLabel: viewData.activePreset?.label,
            activePresetDescription: viewData.activePreset?.description,
            onFilterRemoved: widget.isBusy ? null : _removeActiveFilterLabel,
            onActivePresetRemoved: widget.isBusy ? null : _clearActivePreset,
            onClearAll: widget.isBusy ||
                    (viewData.activeFilterLabels.isEmpty &&
                        viewData.activePreset == null)
                ? null
                : _resetFiltersToDefault,
          ),
        ),
        if (viewData.activeFilterLabels.isNotEmpty) const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mostrando ${viewData.filteredSessions.length} de ${widget.sessions.length} sesiones${_selectedScanner.isEmpty ? '' : ' en $_selectedScanner'}.',
          ),
        ),
        const SizedBox(height: 8),
        ScanDocumentActiveSessionsActions(
          visibleCount: viewData.filteredSessions.length,
            attentionCount: viewData.attentionSessions.length,
            finishedCount: viewData.filteredSessions.where((session) => session.isFinished).length,
            errorCount: viewData.errorSessions.length,
            staleCount: viewData.filteredSessions.where((session) => session.isStale).length,
            runningCount: viewData.runningSessions.length,
            hasAttentionVisible: viewData.firstAttentionSessionId != null,
            hasFinishedVisible: viewData.filteredSessions.any(
              (session) => session.isFinished,
            ),
            hasErrorVisible: viewData.errorSessions.isNotEmpty,
            hasStaleVisible: viewData.filteredSessions.any((session) => session.isStale),
            hasRunningVisible: viewData.runningSessions.isNotEmpty,
            isBusy: widget.isBusy,
          onCopyAttentionIdsRequested: () => copyActiveSessionIds(context, viewData.attentionSessions, message: 'Se copiaron {count} sessionId con atencion al portapapeles.'),
          onCopyVisibleIdsRequested: () =>
              copyActiveSessionIds(context, viewData.filteredSessions),
          onExportAttentionRequested: () =>
              widget.onExportVisibleRequested(viewData.attentionSessions),
            onExportVisibleRequested: () =>
                widget.onExportVisibleRequested(viewData.filteredSessions),
            onOpenAttentionRequested: () => _showSessionDetails(viewData.prioritySession!),
            onOpenErrorRequested: () => _showSessionDetails(viewData.errorSessions.first),
            onResumeAttentionRequested: () =>
                widget.onResumeRequested(viewData.firstAttentionSessionId!),
            onDiscardAttentionRequested: () =>
                widget.onDiscardManyRequested(viewData.attentionSessions.map((session) => session.sessionId).toList(growable: false)),
            onResumeFirstRequested: () => widget.onResumeRequested(
              viewData.runningSessions.isNotEmpty
                  ? viewData.runningSessions.first.sessionId
                  : viewData.filteredSessions.first.sessionId,
            ),
          onDiscardVisibleRequested: () => widget.onDiscardManyRequested(
            viewData.filteredSessions
                .map((session) => session.sessionId)
                .toList(growable: false),
          ),
          onDiscardFinishedVisibleRequested: () => widget.onDiscardManyRequested(viewData.filteredSessions.where((session) => session.isFinished).map((session) => session.sessionId).toList(growable: false)),
          onDiscardErrorVisibleRequested: () => widget.onDiscardManyRequested(viewData.filteredSessions.where((session) => session.status.trim().toLowerCase() == 'error').map((session) => session.sessionId).toList(growable: false)),
          onDiscardStaleVisibleRequested: () => widget.onDiscardManyRequested(viewData.filteredSessions.where((session) => session.isStale).map((session) => session.sessionId).toList(growable: false)),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ScanDocumentActiveSessionsSummary(summary: viewData.summary),
        ),
        const SizedBox(height: 8),
        if (viewData.filteredSessions.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('No hay sesiones que coincidan con el filtro actual.'),
          )
        else
          ...viewData.visibleSessions.map(
            (session) => ScanDocumentActiveSessionCard(
              session: session,
              isBusy: widget.isBusy,
              isCurrent: widget.currentSessionId == session.sessionId,
              isPriority: session.sessionId == viewData.prioritySessionId,
              onDetailsRequested: () => _showSessionDetails(session),
              onResumeRequested: widget.onResumeRequested,
              onDiscardRequested: widget.onDiscardRequested,
            ),
          ),
        ScanDocumentActiveSessionsVisibilityToggle(
          totalCount: viewData.filteredSessions.length,
          isExpanded: _showAllSessions,
          onToggleRequested: () =>
              setState(() => _showAllSessions = !_showAllSessions),
        ),
      ],
    );
  }
}
