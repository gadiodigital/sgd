import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/document_scan_preset.dart';
import '../domain/active_scan_session.dart';
import '../domain/scan_source.dart';
import '../domain/scanner_device.dart';
import '../domain/windows_twain_service_status.dart';
import 'scan_document_configuration_fields.dart';
import 'scan_document_effective_summary.dart';
import 'scan_document_preset_chips.dart';
import 'scan_document_quick_fixes.dart';
import 'scan_document_readiness_checklist.dart';
import 'scan_document_settings_actions.dart';
import 'scan_document_settings_section_support.dart';
import 'scan_document_service_status.dart';

class ScanDocumentSettingsSection extends StatelessWidget {
  const ScanDocumentSettingsSection({
    required this.serviceAvailable,
    required this.serviceStatus,
    required this.serviceBaseUrl,
    required this.isBusy,
    required this.activeSessions,
    required this.canScan,
    required this.canResumeLastSession,
    required this.currentSessionId,
    required this.lastHostSyncAtUtc,
    required this.nextHostRefreshAtUtc,
    required this.currentTimeUtc,
    required this.source,
    required this.canUseAdf,
    required this.canScanFlatbed,
    required this.canScanSimplex,
    required this.canScanDuplex,
    required this.scanners,
    required this.selectedScanner,
    required this.presets,
    required this.activePresetId,
    required this.duplex,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
    required this.onRefreshRequested,
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
    required this.onResetRequested,
    required this.onForgetScannerRequested,
    required this.onPresetSelected,
    required this.onSourceChanged,
    required this.onScannerChanged,
    required this.onDuplexChanged,
    required this.onDpiChanged,
    required this.onPixelTypeChanged,
    required this.onDiscardBlankPagesChanged,
    super.key,
  });

  final bool serviceAvailable;
  final WindowsTwainServiceStatus? serviceStatus;
  final String serviceBaseUrl;
  final bool isBusy;
  final List<ActiveScanSession> activeSessions;
  final bool canScan;
  final bool canResumeLastSession;
  final String? currentSessionId;
  final DateTime? lastHostSyncAtUtc;
  final DateTime? nextHostRefreshAtUtc;
  final DateTime currentTimeUtc;
  final ScanSource source;
  final bool canUseAdf;
  final bool canScanFlatbed;
  final bool canScanSimplex;
  final bool canScanDuplex;
  final List<ScannerDevice> scanners;
  final ScannerDevice? selectedScanner;
  final List<DocumentScanPreset> presets;
  final String? activePresetId;
  final bool duplex;
  final int dpi;
  final String pixelType;
  final String discardBlankPages;
  final VoidCallback onRefreshRequested;
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
  final VoidCallback onResetRequested;
  final VoidCallback onForgetScannerRequested;
  final ValueChanged<DocumentScanPreset> onPresetSelected;
  final ValueChanged<ScanSource> onSourceChanged;
  final ValueChanged<ScannerDevice?> onScannerChanged;
  final ValueChanged<bool> onDuplexChanged;
  final ValueChanged<int> onDpiChanged;
  final ValueChanged<String> onPixelTypeChanged;
  final ValueChanged<String> onDiscardBlankPagesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GdmsStatusBadge(
                label: serviceAvailable
                    ? 'Servicio disponible en $serviceBaseUrl'
                    : 'Servicio no disponible en $serviceBaseUrl',
                tone: serviceAvailable
                    ? GdmsStatusTone.info
                    : GdmsStatusTone.critical,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: isBusy ? null : onRefreshRequested,
              tooltip: 'Redescubrir escaneres',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (serviceStatus != null) ...[
          ScanDocumentServiceStatus(
            serviceStatus: serviceStatus!,
            activeSessions: activeSessions,
            canScan: canScan,
            canResumeLastSession: canResumeLastSession,
            currentSessionId: currentSessionId,
            lastHostSyncAtUtc: lastHostSyncAtUtc,
            nextHostRefreshAtUtc: nextHostRefreshAtUtc,
            currentTimeUtc: currentTimeUtc,
            isBusy: isBusy,
            onCleanupRequested: onCleanupRequested,
            onClearActiveSessionsRequested: onClearActiveSessionsRequested,
            onClearFinishedSessionsRequested:
                onClearFinishedSessionsRequested,
            onClearAdfSessionsRequested: onClearAdfSessionsRequested,
            onClearFlatbedSessionsRequested: onClearFlatbedSessionsRequested,
            onClearStaleSessionsRequested: onClearStaleSessionsRequested,
            onClearRehydratedSessionsRequested:
                onClearRehydratedSessionsRequested,
            onResumeLastSessionRequested: onResumeLastSessionRequested,
            onResumeSessionRequested: onResumeSessionRequested,
            onDiscardSessionRequested: onDiscardSessionRequested,
            onDiscardSessionsRequested: onDiscardSessionsRequested,
            onExportSessionsRequested: onExportSessionsRequested,
          ),
          const SizedBox(height: 14),
        ],
        ScanDocumentSettingsActions(
          isBusy: isBusy,
          hasSelectedScanner: selectedScanner != null,
          onResetRequested: onResetRequested,
          onForgetScannerRequested: onForgetScannerRequested,
        ),
        const SizedBox(height: 14),
        if (source == ScanSource.adf)
          ScanDocumentPresetChips(
            presets: presets,
            selectedPresetId: activePresetId,
            selectedPreset: ScanDocumentSettingsSectionSupport.selectedPreset(
              presets,
              activePresetId,
            ),
            duplex: duplex,
            dpi: dpi,
            pixelType: pixelType,
            discardBlankPages: discardBlankPages,
            isBusy: isBusy,
            canApplyPreset: (preset) =>
                preset.duplex ? canScanDuplex : canScanSimplex,
            unavailableReason: (preset) {
              if (preset.duplex && !canScanDuplex) {
                return 'requiere duplex';
              }
              if (!preset.duplex && !canScanSimplex) {
                return 'requiere simplex';
              }
              return null;
            },
            onPresetSelected: onPresetSelected,
          )
        else
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Los presets operativos aplican solo a escaneos ADF.'),
          ),
        const SizedBox(height: 14),
        ScanDocumentEffectiveSummary(
          selectedScanner: selectedScanner,
          source: source,
          duplex: duplex,
          dpi: dpi,
          pixelType: pixelType,
          discardBlankPages: discardBlankPages,
          canScan: canScan,
          readinessReason: ScanDocumentSettingsSectionSupport.readinessReason(
            source: source,
            serviceAvailable: serviceAvailable,
            hasScanners: scanners.isNotEmpty,
            hasSelectedScanner: selectedScanner != null,
            duplex: duplex,
            canScanDuplex: canScanDuplex,
            canScanSimplex: canScanSimplex,
            canScanFlatbed: canScanFlatbed,
            canUseAdf: canUseAdf,
          ),
        ),
        const SizedBox(height: 14),
        ScanDocumentReadinessChecklist(
          sourceLabel: source.label,
          serviceAvailable: serviceAvailable,
          hasScanners: scanners.isNotEmpty,
          hasSelectedScanner: selectedScanner != null,
          modeSupported: source == ScanSource.flatbed
              ? canScanFlatbed
              : (duplex ? canScanDuplex : canScanSimplex),
        ),
        const SizedBox(height: 14),
        ScanDocumentQuickFixes(
          showRefresh: !serviceAvailable || scanners.isEmpty,
          showSelectFirstScanner:
              selectedScanner == null && scanners.isNotEmpty,
          showSwitchToSimplex: duplex && !canScanDuplex && canScanSimplex,
          showSwitchToAdf:
              source == ScanSource.flatbed && !canScanFlatbed && canUseAdf,
          showSwitchToFlatbed:
              source == ScanSource.adf && !canUseAdf && canScanFlatbed,
          isBusy: isBusy,
          onRefreshRequested: onRefreshRequested,
          onSelectFirstScannerRequested: () => onScannerChanged(scanners.first),
          onSwitchToSimplexRequested: () => onDuplexChanged(false),
          onSwitchToAdfRequested: () => onSourceChanged(ScanSource.adf),
          onSwitchToFlatbedRequested: () => onSourceChanged(ScanSource.flatbed),
        ),
        const SizedBox(height: 14),
        ScanDocumentConfigurationFields(
          source: source,
          scanners: scanners,
          selectedScanner: selectedScanner,
          isBusy: isBusy,
          canUseAdf: canUseAdf,
          canScanFlatbed: canScanFlatbed,
          canScanSimplex: canScanSimplex,
          canScanDuplex: canScanDuplex,
          duplex: duplex,
          dpi: dpi,
          pixelType: pixelType,
          discardBlankPages: discardBlankPages,
          serviceStatus: serviceStatus,
          onSourceChanged: onSourceChanged,
          onScannerChanged: onScannerChanged,
          onDuplexChanged: onDuplexChanged,
          onDpiChanged: onDpiChanged,
          onPixelTypeChanged: onPixelTypeChanged,
          onDiscardBlankPagesChanged: onDiscardBlankPagesChanged,
        ),
      ],
    );
  }
}
