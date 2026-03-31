import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/active_scan_session.dart';
import '../domain/windows_twain_service_status.dart';
import 'scan_document_active_sessions.dart';

class ScanDocumentServiceStatus extends StatelessWidget {
  const ScanDocumentServiceStatus({
    required this.serviceStatus,
    required this.activeSessions,
    required this.canScan,
    required this.canResumeLastSession,
    required this.currentSessionId,
    required this.lastHostSyncAtUtc,
    required this.nextHostRefreshAtUtc,
    required this.currentTimeUtc,
    required this.isBusy,
    required this.onCleanupRequested,
    required this.onClearActiveSessionsRequested,
    required this.onClearFinishedSessionsRequested,
    required this.onClearAdfSessionsRequested,
    required this.onClearFlatbedSessionsRequested,
    required this.onClearStaleSessionsRequested,
    required this.onClearRehydratedSessionsRequested,
    required this.onResumeLastSessionRequested,
    required this.onResumeSessionRequested,
    required this.onDiscardSessionRequested,
    required this.onDiscardSessionsRequested,
    required this.onExportSessionsRequested,
    super.key,
  });

  final WindowsTwainServiceStatus serviceStatus;
  final List<ActiveScanSession> activeSessions;
  final bool canScan;
  final bool canResumeLastSession;
  final String? currentSessionId;
  final DateTime? lastHostSyncAtUtc;
  final DateTime? nextHostRefreshAtUtc;
  final DateTime currentTimeUtc;
  final bool isBusy;
  final VoidCallback onCleanupRequested;
  final VoidCallback onClearActiveSessionsRequested;
  final VoidCallback onClearFinishedSessionsRequested;
  final VoidCallback onClearAdfSessionsRequested;
  final VoidCallback onClearFlatbedSessionsRequested;
  final VoidCallback onClearStaleSessionsRequested;
  final VoidCallback onClearRehydratedSessionsRequested;
  final VoidCallback onResumeLastSessionRequested;
  final ValueChanged<String> onResumeSessionRequested;
  final ValueChanged<String> onDiscardSessionRequested;
  final ValueChanged<List<String>> onDiscardSessionsRequested;
  final ValueChanged<List<ActiveScanSession>> onExportSessionsRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Host: ${serviceStatus.application.isEmpty ? 'windows-twain' : serviceStatus.application} '
            '${serviceStatus.version.isEmpty ? '' : 'v${serviceStatus.version}'}',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Modo: ${serviceStatus.runMode.isEmpty ? 'sin dato' : serviceStatus.runMode} · '
            'Operaciones: ${serviceStatus.operations.length} · '
            'Sesiones activas: ${serviceStatus.activeSessions}',
          ),
        ),
        if (lastHostSyncAtUtc != null) ...[
          const SizedBox(height: 8),
          GdmsStatusBadge(
            label: _syncStatusLabel(lastHostSyncAtUtc!),
            tone: _syncStatusTone(lastHostSyncAtUtc!),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ultima sincronizacion: ${_formatDateTime(lastHostSyncAtUtc!)}',
            ),
          ),
        ],
        if (nextHostRefreshAtUtc != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Proximo refresh automatico: ${_nextRefreshLabel(nextHostRefreshAtUtc!)}',
            ),
          ),
        ],
        if (serviceStatus.sessionsRootPath.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Sesiones locales: ${serviceStatus.sessionsRootPath}'),
          ),
        ],
        if (serviceStatus.lastCleanupAtUtc != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ultima limpieza: ${_formatDateTime(serviceStatus.lastCleanupAtUtc!)}',
            ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onCleanupRequested,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(
            serviceStatus.lastCleanupDeletedCount > 0
                ? 'Limpiar sesiones (${serviceStatus.lastCleanupDeletedCount})'
                : 'Limpiar sesiones',
            ),
        ),
        if (activeSessions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rehidratadas: ${activeSessions.where((session) => session.isRehydrated).length} · '
              'Inactivas: ${activeSessions.where((session) => session.isStale).length}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onClearActiveSessionsRequested,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text('Vaciar sesiones activas (${activeSessions.length})'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (activeSessions.any((session) => session.isFinished))
                OutlinedButton(
                  onPressed: isBusy ? null : onClearFinishedSessionsRequested,
                  child: const Text('Vaciar finalizadas'),
                ),
              if (activeSessions.any((session) => session.isAdf))
                OutlinedButton(
                  onPressed: isBusy ? null : onClearAdfSessionsRequested,
                  child: const Text('Vaciar ADF'),
                ),
              if (activeSessions.any((session) => session.isFlatbed))
                OutlinedButton(
                  onPressed: isBusy ? null : onClearFlatbedSessionsRequested,
                  child: const Text('Vaciar cama plana'),
                ),
              if (activeSessions.any((session) => session.isStale))
                OutlinedButton(
                  onPressed: isBusy ? null : onClearStaleSessionsRequested,
                  child: const Text('Vaciar inactivas'),
                ),
              if (activeSessions.any((session) => session.isRehydrated))
                OutlinedButton(
                  onPressed: isBusy ? null : onClearRehydratedSessionsRequested,
                  child: const Text('Vaciar rehidratadas'),
                ),
            ],
          ),
        ],
        if (canResumeLastSession) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onResumeLastSessionRequested,
            icon: const Icon(Icons.restore_page_outlined),
            label: const Text('Reanudar ultima sesion'),
          ),
        ],
        if (serviceStatus.scannerSummary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('TWAIN: ${serviceStatus.scannerSummary}'),
          ),
        ],
        if (serviceStatus.startupLogPath.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Log de arranque: ${serviceStatus.startupLogPath}'),
          ),
        ],
        if (serviceStatus.operations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: serviceStatus.operations
                .take(6)
                .map(
                  (operation) => GdmsStatusBadge(
                    label: operation,
                    tone: GdmsStatusTone.info,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 8),
        ScanDocumentActiveSessions(
          sessions: activeSessions,
          isBusy: isBusy,
          currentSessionId: currentSessionId,
          onResumeRequested: onResumeSessionRequested,
          onDiscardRequested: onDiscardSessionRequested,
          onDiscardManyRequested: onDiscardSessionsRequested,
          onExportVisibleRequested: onExportSessionsRequested,
        ),
        if (!canScan) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'La configuracion elegida no coincide con las operaciones publicadas por el servicio.',
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    final localValue = value.toLocal();
    final day = localValue.day.toString().padLeft(2, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');
    return '$day/$month/${localValue.year} $hour:$minute';
  }

  String _syncStatusLabel(DateTime value) {
    final age = DateTime.now().toUtc().difference(value.toUtc());
    if (age.inSeconds < 30) {
      return 'Snapshot reciente';
    }
    if (age.inMinutes < 2) {
      return 'Sincronizacion estable';
    }
    return 'Snapshot desactualizado';
  }

  GdmsStatusTone _syncStatusTone(DateTime value) {
    final age = DateTime.now().toUtc().difference(value.toUtc());
    if (age.inSeconds < 30) {
      return GdmsStatusTone.info;
    }
    if (age.inMinutes < 2) {
      return GdmsStatusTone.warning;
    }
    return GdmsStatusTone.critical;
  }

  String _nextRefreshLabel(DateTime value) {
    final remaining = value.toUtc().difference(currentTimeUtc.toUtc());
    if (remaining.inSeconds <= 0) {
      return 'ahora';
    }
    return 'en ${remaining.inSeconds}s';
  }
}
