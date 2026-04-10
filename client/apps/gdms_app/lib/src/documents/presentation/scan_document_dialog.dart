import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/repositories/windows_twain_scan_repository.dart';
import '../application/document_scan_view_model.dart';
import '../application/document_scan_view_model_capabilities.dart';
import '../application/document_scan_view_model_export.dart';
import 'scan_document_settings_section.dart';
import 'scan_preview_section.dart';
class ScanDocumentDialog extends StatefulWidget {
  const ScanDocumentDialog({
    super.key,
    this.viewModel,
    this.autoStart = true,
    this.hostRefreshInterval = const Duration(seconds: 15),
  });

  final DocumentScanViewModel? viewModel;
  final bool autoStart;
  final Duration hostRefreshInterval;

  @override
  State<ScanDocumentDialog> createState() => _ScanDocumentDialogState();
}

class _ScanDocumentDialogState extends State<ScanDocumentDialog> {
  late final DocumentScanViewModel _viewModel;
  late final bool _ownsViewModel;
  Timer? _hostRefreshTimer;
  Timer? _clockTimer;
  DateTime _nowUtc = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ?? DocumentScanViewModel(WindowsTwainScanRepository());
    if (!widget.autoStart) {
      return;
    }
    unawaited(_viewModel.loadScanners());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _nowUtc = DateTime.now().toUtc();
      });
    });
    _hostRefreshTimer = Timer.periodic(widget.hostRefreshInterval, (_) {
      if (!mounted || _viewModel.isBusy) {
        return;
      }
      unawaited(_viewModel.refreshHostSnapshot());
    });
  }

  @override
  void dispose() {
    _hostRefreshTimer?.cancel();
    _clockTimer?.cancel();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GdmsPageHeader(
                      title: 'Escanear documento',
                      subtitle:
                          'Usa el servicio local windows-twain para capturar un '
                          'PDF desde el alimentador ADF y subirlo luego al backend.',
                    ),
                    const SizedBox(height: 18),
                    ScanDocumentSettingsSection(
                      serviceAvailable: _viewModel.serviceAvailable,
                      serviceStatus: _viewModel.serviceStatus,
                      serviceBaseUrl: _viewModel.serviceBaseUrl,
                      isBusy: _viewModel.isBusy,
                      activeSessions: _viewModel.activeSessions.toList(
                        growable: false,
                      ),
                      canScan: _viewModel.canScan,
                      canResumeLastSession: _viewModel.canResumeLastSession,
                      currentSessionId: _viewModel.lastScannedFile?.sessionId,
                      lastHostSyncAtUtc: _viewModel.lastHostSyncAtUtc,
                      nextHostRefreshAtUtc: _viewModel.lastHostSyncAtUtc
                          ?.add(widget.hostRefreshInterval),
                      currentTimeUtc: _nowUtc,
                      source: _viewModel.source,
                      canUseAdf: _viewModel.canUseAdf,
                      canScanFlatbed: _viewModel.canScanFlatbed,
                      canScanSimplex: _viewModel.canScanSimplex,
                      canScanDuplex: _viewModel.canScanDuplex,
                      scanners: _viewModel.scanners.toList(growable: false),
                      selectedScanner: _viewModel.selectedScanner,
                      presets: _viewModel.presets,
                      activePresetId: _viewModel.activePresetId,
                      duplex: _viewModel.duplex,
                      dpi: _viewModel.dpi,
                      pixelType: _viewModel.pixelType,
                      discardBlankPages: _viewModel.discardBlankPages,
                      onRefreshRequested: () =>
                          unawaited(_viewModel.refreshScanners()),
                      onCleanupRequested: () =>
                          unawaited(_viewModel.cleanupSessions()),
                      onClearActiveSessionsRequested: () =>
                          unawaited(_viewModel.clearActiveSessions()),
                      onClearFinishedSessionsRequested: () =>
                          unawaited(_viewModel.discardFinishedSessions()),
                      onClearAdfSessionsRequested: () =>
                          unawaited(_viewModel.discardAdfSessions()),
                      onClearFlatbedSessionsRequested: () =>
                          unawaited(_viewModel.discardFlatbedSessions()),
                      onClearStaleSessionsRequested: () =>
                          unawaited(_viewModel.clearStaleSessions()),
                      onClearRehydratedSessionsRequested: () =>
                          unawaited(_viewModel.clearRehydratedSessions()),
                      onResumeLastSessionRequested: () =>
                          unawaited(_viewModel.resumeLastSession()),
                      onResumeSessionRequested: (sessionId) =>
                          unawaited(_viewModel.resumeSessionById(sessionId)),
                      onDiscardSessionRequested: (sessionId) =>
                          unawaited(_viewModel.discardSessionById(sessionId)),
                      onDiscardSessionsRequested: (sessionIds) => unawaited(
                        _viewModel.discardSessionsByIds(
                          sessionIds,
                          successMessage:
                              'Se descartaron las sesiones visibles del host local.',
                        ),
                      ),
                      onExportSessionsRequested: (sessions) => unawaited(
                        DocumentScanViewModelExport.exportSessionsSummary(
                          _viewModel,
                          sessions,
                        ),
                      ),
                      onResetRequested: _viewModel.resetPreferences,
                      onForgetScannerRequested:
                          _viewModel.forgetPreferredScanner,
                      onPresetSelected: _viewModel.applyPreset,
                      onSourceChanged: _viewModel.setSource,
                      onScannerChanged: _viewModel.selectScanner,
                      onDuplexChanged: _viewModel.setDuplex,
                      onDpiChanged: _viewModel.setDpi,
                      onPixelTypeChanged: _viewModel.setPixelType,
                      onDiscardBlankPagesChanged:
                          _viewModel.setDiscardBlankPages,
                    ),
                    if (_viewModel.message != null) ...[
                      const SizedBox(height: 14),
                      GdmsStatusBadge(
                        label: _viewModel.message!,
                        tone: _viewModel.state == ViewState.error
                            ? GdmsStatusTone.critical
                            : GdmsStatusTone.info,
                      ),
                    ],
                    if (_viewModel.lastScannedFile != null) ...[
                      const SizedBox(height: 18),
                      ScanPreviewSection(
                        scannedFile: _viewModel.lastScannedFile!,
                        previewBytes: _viewModel.previewBytes,
                        serviceAvailable: _viewModel.serviceAvailable,
                        currentPage: _viewModel.currentPreviewPage,
                        sessionDetails: _viewModel.sessionDetails,
                        canShowPreviousPage: _viewModel.canShowPreviousPage,
                        canShowNextPage: _viewModel.canShowNextPage,
                        canDeleteCurrentPage: _viewModel.canDeleteCurrentPage,
                        canRotateCurrentPage: _viewModel.canRotateCurrentPage,
                        canMoveCurrentPageBackward:
                            _viewModel.canMoveCurrentPageBackward,
                        canMoveCurrentPageForward:
                            _viewModel.canMoveCurrentPageForward,
                        onPreviousPageRequested: _viewModel.showPreviousPage,
                        onNextPageRequested: _viewModel.showNextPage,
                        onRotateRequested: _viewModel.rotateCurrentPage,
                        onDeleteRequested: _viewModel.deleteCurrentPage,
                        onMoveBackwardRequested:
                            _viewModel.moveCurrentPageBackward,
                        onMoveForwardRequested:
                            _viewModel.moveCurrentPageForward,
                        onAppendScanRequested: _viewModel.appendAnotherScan,
                        onInsertBeforeScanRequested:
                            _viewModel.insertAnotherScanBeforeCurrentPage,
                        onInsertScanRequested:
                            _viewModel.insertAnotherScanAfterCurrentPage,
                        canAppendScan: _viewModel.canMergeScans,
                        canAdjustCurrentPage: _viewModel.canAdjustCurrentPage,
                        onBrightenRequested: _viewModel.brightenCurrentPage,
                        onDarkenRequested: _viewModel.darkenCurrentPage,
                        onIncreaseContrastRequested:
                            _viewModel.increaseContrastCurrentPage,
                        onDecreaseContrastRequested:
                            _viewModel.decreaseContrastCurrentPage,
                        canRefreshSession: _viewModel.canRefreshSessionDetails,
                        onRefreshSessionRequested: _viewModel.refreshSession,
                        onDiscardSessionRequested: _discardSessionAndStay,
                        onExportPdfRequested: _viewModel.exportPdf,
                        isBusy: _viewModel.isBusy,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        TextButton(
                          onPressed: _viewModel.isBusy ? null : _closeDialog,
                          child: const Text('Cancelar'),
                        ),
                        if (_viewModel.lastScannedFile != null)
                          OutlinedButton.icon(
                            onPressed: _viewModel.isBusy ? null : _scan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Escanear de nuevo'),
                          ),
                        FilledButton.icon(
                          onPressed: _viewModel.lastScannedFile != null
                              ? _useScannedDocument
                              : (_viewModel.canScan ? _scan : null),
                          icon: _viewModel.isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _viewModel.lastScannedFile != null
                                      ? Icons.check_circle_outline
                                      : Icons.document_scanner,
                                ),
                          label: Text(
                            _viewModel.lastScannedFile != null
                                ? 'Usar escaneo'
                                : 'Escanear',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _scan() async {
    final scannedFile = await _viewModel.scan();
    if (!mounted || scannedFile == null) return;
  }
  Future<void> _discardSessionAndStay() async => _viewModel.discardSession();

  Future<void> _closeDialog() async {
    await _viewModel.discardSession(silent: true);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _useScannedDocument() async {
    final scannedFile = _viewModel.lastScannedFile;
    if (scannedFile == null) return;
    await _viewModel.discardSession(silent: true);
    if (!mounted) return;
    Navigator.of(context).pop(scannedFile);
  }
}
