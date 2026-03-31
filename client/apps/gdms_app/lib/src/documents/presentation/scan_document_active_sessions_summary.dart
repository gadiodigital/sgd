import 'package:flutter/material.dart';

import 'scan_document_active_sessions_summary_support.dart';
import 'scan_document_active_sessions_summary_visuals.dart';
import 'scan_document_active_sessions_summary_visuals_support.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionsSummary extends StatelessWidget {
  const ScanDocumentActiveSessionsSummary({required this.summary, super.key});

  final ScanDocumentSessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(summary);
    final severityColorsValue = severityColors(viewData.severityLabel);
    final dominantStateColorsValue = dominantStateColors(
      viewData.dominantStateLabel,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Lote visible: ${viewData.healthLabel}'),
              summaryChip(
                theme,
                label: viewData.healthBadgeLabel,
                tooltip: 'Salud del lote visible: ${viewData.healthLabel}',
                backgroundColor: viewData.healthBackgroundColor,
                foregroundColor: viewData.healthForegroundColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(viewData.healthDescription),
          if (summary.totalSessions > 0) ...[
            const SizedBox(height: 8),
            operationalPulseBanner(
              theme,
              affectedSessions: viewData.affectedSessions,
              totalSessions: summary.totalSessions,
              severityLabel: viewData.severityLabel,
              operationalRiskLabel: viewData.operationalRiskLabel,
              backgroundColor: viewData.healthBackgroundColor,
              foregroundColor: viewData.healthForegroundColor,
            ),
            const SizedBox(height: 8),
            operationalMarkers(
              theme,
              totalSessions: summary.totalSessions,
              attentionSessions: summary.attentionSessions,
              mostRecentActivityAtUtc: summary.mostRecentActivityAtUtc,
              oldestActivityAtUtc: summary.oldestActivityAtUtc,
              totalPages: summary.totalPages,
              primaryScannerLabel: summary.primaryScannerLabel,
              uniqueScanners: summary.uniqueScanners,
              adfSessions: summary.adfSessions,
              flatbedSessions: summary.flatbedSessions,
              completedSessions: summary.completedSessions,
              runningSessions: summary.runningSessions,
              errorSessions: summary.errorSessions,
              rehydratedSessions: summary.rehydratedSessions,
              staleSessions: summary.staleSessions,
            ),
            const SizedBox(height: 4),
            Text(
              'Sesiones afectadas: ${viewData.affectedSessions} de ${summary.totalSessions}',
            ),
            const SizedBox(height: 4),
            Text('Cobertura afectada: ${viewData.affectedRatioLabel}'),
            const SizedBox(height: 4),
            summarySignalRow(
              theme,
              text: 'Severidad visible: ${viewData.severityLabel}',
              chipLabel: viewData.severityLabel.toUpperCase(),
              tooltip: 'Severidad visible: ${viewData.severityLabel}',
              backgroundColor: severityColorsValue.background,
              foregroundColor: severityColorsValue.foreground,
            ),
            const SizedBox(height: 4),
            summarySignalRow(
              theme,
              text: 'Riesgo operativo: ${viewData.operationalRiskLabel}',
              chipLabel: viewData.operationalRiskLabel.toUpperCase(),
              tooltip: 'Riesgo operativo: ${viewData.operationalRiskLabel}',
              backgroundColor: viewData.operationalRiskBackgroundColor,
              foregroundColor: viewData.operationalRiskForegroundColor,
            ),
            const SizedBox(height: 4),
            summarySignalRow(
              theme,
              text: 'Estado dominante: ${viewData.dominantStateLabel}',
              chipLabel: dominantStateChipLabel(viewData.dominantStateLabel),
              tooltip: 'Estado dominante: ${viewData.dominantStateLabel}',
              backgroundColor: dominantStateColorsValue.background,
              foregroundColor: dominantStateColorsValue.foreground,
            ),
            const SizedBox(height: 4),
            Text('Patron dominante: ${viewData.dominantPatternRecommendation}'),
            const SizedBox(height: 4),
            summarySignalRow(
              theme,
              text: 'Siguiente paso: ${viewData.nextStepRecommendation}',
              chipLabel: 'ACCION',
              tooltip: 'Siguiente paso: ${viewData.nextStepRecommendation}',
              backgroundColor: viewData.operationalRiskBackgroundColor,
              foregroundColor: viewData.operationalRiskForegroundColor,
            ),
            if (viewData.focus != null) ...[
              const SizedBox(height: 4),
              summarySignalRow(
                theme,
                text: 'Foco operativo: ${viewData.focus}',
                chipLabel: 'FOCO',
                tooltip: 'Foco operativo: ${viewData.focus}',
                backgroundColor: viewData.healthBackgroundColor,
                foregroundColor: viewData.healthForegroundColor,
              ),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            'Paginas: ${summary.totalPages} · Atencion: ${summary.attentionSessions} · Rehidratadas: ${summary.rehydratedSessions} · Inactivas: ${summary.staleSessions}',
          ),
          const SizedBox(height: 8),
          Text(
            'Completed: ${summary.completedSessions} · Error: ${summary.errorSessions} · Running: ${summary.runningSessions}',
          ),
          const SizedBox(height: 8),
          Text(
            'Scanners: ${summary.uniqueScanners} · Principal: ${summary.primaryScannerLabel}',
          ),
          const SizedBox(height: 8),
          Text(
            'ADF: ${summary.adfSessions} · Cama plana: ${summary.flatbedSessions}',
          ),
          if (summary.mostRecentActivityAtUtc != null &&
              summary.oldestActivityAtUtc != null) ...[
            const SizedBox(height: 8),
            Text(
              'Actividad visible: ${ScanDocumentActiveSessionsSupport.formatDateTime(summary.mostRecentActivityAtUtc!)} a ${ScanDocumentActiveSessionsSupport.formatDateTime(summary.oldestActivityAtUtc!)}',
            ),
          ],
        ],
      ),
    );
  }
}
