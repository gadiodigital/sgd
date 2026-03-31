import 'scan_document_active_sessions_support.dart';
import 'scan_document_active_sessions_summary_marker_support.dart';
import 'scan_document_active_sessions_summary_operational_support.dart';
import 'scan_document_active_sessions_summary_visuals_support.dart';
import 'package:flutter/material.dart';

Widget operationalPulseBanner(
  ThemeData theme, {
  required int affectedSessions,
  required int totalSessions,
  required String severityLabel,
  required String operationalRiskLabel,
  required Color backgroundColor,
  required Color foregroundColor,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: backgroundColor.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: backgroundColor.withValues(alpha: 0.2)),
  ),
  child: Text(
    'Pulso operativo: $affectedSessions/$totalSessions afectadas · severidad $severityLabel · riesgo $operationalRiskLabel',
    style: theme.textTheme.bodyMedium?.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w600,
    ),
  ),
);

Widget operationalMarkers(
  ThemeData theme, {
  required int totalSessions,
  DateTime? mostRecentActivityAtUtc,
  DateTime? oldestActivityAtUtc,
  required int totalPages,
  required String primaryScannerLabel,
  required int uniqueScanners,
  required int adfSessions,
  required int flatbedSessions,
  required int completedSessions,
  required int runningSessions,
  required int errorSessions,
  required int attentionSessions,
  required int rehydratedSessions,
  required int staleSessions,
}) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    summaryChip(
      theme,
      label: attentionDensityLabel(attentionSessions, totalSessions),
      tooltip:
          'Densidad de atencion: ${attentionDensityTooltip(attentionSessions, totalSessions)}',
      backgroundColor: Colors.orange,
      foregroundColor: Colors.orange,
    ),
    if (mostRecentActivityAtUtc != null)
      summaryChip(
        theme,
        label: 'ACTIVIDAD',
        tooltip:
            'Ultima actividad: ${ScanDocumentActiveSessionsSupport.formatDateTime(mostRecentActivityAtUtc)}',
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.deepOrange,
      ),
    if (mostRecentActivityAtUtc != null && oldestActivityAtUtc != null)
      summaryChip(
        theme,
        label: 'VENTANA',
        tooltip:
            'Ventana visible: ${ScanDocumentActiveSessionsSupport.formatDateTime(oldestActivityAtUtc)} a ${ScanDocumentActiveSessionsSupport.formatDateTime(mostRecentActivityAtUtc)}',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.deepPurple,
      ),
    if (mostRecentActivityAtUtc != null && oldestActivityAtUtc != null)
      summaryChip(
        theme,
        label: 'RANGO',
        tooltip:
            'Rango de actividad: ${formatActivityRange(mostRecentActivityAtUtc.difference(oldestActivityAtUtc))}',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.deepPurple,
      ),
    summaryChip(
      theme,
      label: 'PAGINAS $totalPages',
      tooltip: 'Paginas visibles: $totalPages',
      backgroundColor: Colors.purple,
      foregroundColor: Colors.purple,
    ),
    summaryChip(
      theme,
      label: volumeLabel(totalPages),
      tooltip: 'Volumen documental: ${volumeTooltip(totalPages)}',
      backgroundColor: Colors.purple,
      foregroundColor: Colors.purple,
    ),
    summaryChip(
      theme,
      label: 'PROMEDIO ${formatAveragePages(totalPages, totalSessions)}',
      tooltip:
          'Promedio de paginas por sesion: ${formatAveragePages(totalPages, totalSessions)}',
      backgroundColor: Colors.purple,
      foregroundColor: Colors.purple,
    ),
    summaryChip(
      theme,
      label: 'PRINCIPAL',
      tooltip: 'Scanner principal: $primaryScannerLabel',
      backgroundColor: Colors.teal,
      foregroundColor: Colors.teal,
    ),
    summaryChip(
      theme,
      label: 'SCANNERS $uniqueScanners',
      tooltip: 'Scanners visibles: $uniqueScanners',
      backgroundColor: Colors.teal,
      foregroundColor: Colors.teal,
    ),
    summaryChip(
      theme,
      label: uniqueScanners > 1 ? 'MULTISCANNER' : 'MONOSCANNER',
      tooltip: uniqueScanners > 1
          ? 'Capacidad paralela en $uniqueScanners scanners'
          : 'Operacion concentrada en un solo scanner',
      backgroundColor: Colors.teal,
      foregroundColor: Colors.teal,
    ),
    summaryChip(
      theme,
      label: runningDensityLabel(runningSessions, totalSessions),
      tooltip:
          'Nivel de ejecucion: ${runningDensityTooltip(runningSessions, totalSessions)}',
      backgroundColor: Colors.blue,
      foregroundColor: Colors.blue,
    ),
    summaryChip(
      theme,
      label: completionDensityLabel(completedSessions, totalSessions),
      tooltip:
          'Nivel de cierre: ${completionDensityTooltip(completedSessions, totalSessions)}',
      backgroundColor: Colors.green,
      foregroundColor: Colors.green,
    ),
    summaryChip(
      theme,
      label: errorDensityLabel(errorSessions, totalSessions),
      tooltip:
          'Nivel de falla: ${errorDensityTooltip(errorSessions, totalSessions)}',
      backgroundColor: Colors.red,
      foregroundColor: Colors.red,
    ),
    summaryChip(
      theme,
      label: rehydrationDensityLabel(rehydratedSessions, totalSessions),
      tooltip:
          'Nivel de rehidratacion: ${rehydrationDensityTooltip(rehydratedSessions, totalSessions)}',
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.indigo,
    ),
    summaryChip(
      theme,
      label: staleDensityLabel(staleSessions, totalSessions),
      tooltip:
          'Nivel de inactividad: ${staleDensityTooltip(staleSessions, totalSessions)}',
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.blueGrey,
    ),
    summaryChip(
      theme,
      label: stabilityLabel(
        errorSessions,
        rehydratedSessions,
        staleSessions,
        totalSessions,
      ),
      tooltip:
          'Estabilidad del lote: ${stabilityTooltip(errorSessions, rehydratedSessions, staleSessions, totalSessions)}',
      backgroundColor: Colors.teal,
      foregroundColor: Colors.teal,
    ),
    summaryChip(
      theme,
      label: recoverabilityLabel(
        errorSessions,
        staleSessions,
        completedSessions,
        runningSessions,
      ),
      tooltip:
          'Recuperabilidad del lote: ${recoverabilityTooltip(errorSessions, staleSessions, completedSessions, runningSessions)}',
      backgroundColor: Colors.lightGreen,
      foregroundColor: Colors.green,
    ),
    summaryChip(
      theme,
      label: continuityLabel(runningSessions, completedSessions),
      tooltip:
          'Continuidad del lote: ${continuityTooltip(runningSessions, completedSessions)}',
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.blue,
    ),
    summaryChip(
      theme,
      label: pressureLabel(attentionSessions, runningSessions, totalSessions),
      tooltip:
          'Presion del lote: ${pressureTooltip(attentionSessions, runningSessions, totalSessions)}',
      backgroundColor: Colors.deepOrange,
      foregroundColor: Colors.deepOrange,
    ),
    summaryChip(
      theme,
      label: balanceLabel(runningSessions, completedSessions),
      tooltip:
          'Balance del lote: ${balanceTooltip(runningSessions, completedSessions)}',
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.blueAccent,
    ),
    summaryChip(
      theme,
      label: maturityLabel(completedSessions, errorSessions, totalSessions),
      tooltip:
          'Madurez del lote: ${maturityTooltip(completedSessions, errorSessions, totalSessions)}',
      backgroundColor: Colors.lime,
      foregroundColor: Colors.green,
    ),
    summaryChip(
      theme,
      label: 'ADF $adfSessions',
      tooltip: 'Sesiones ADF: $adfSessions',
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.cyan,
    ),
    summaryChip(
      theme,
      label: 'FLATBED $flatbedSessions',
      tooltip: 'Sesiones cama plana: $flatbedSessions',
      backgroundColor: Colors.brown,
      foregroundColor: Colors.brown,
    ),
    summaryChip(
      theme,
      label: sourceMixLabel(adfSessions, flatbedSessions),
      tooltip:
          'Mezcla de origen: ${sourceMixTooltip(adfSessions, flatbedSessions)}',
      backgroundColor: Colors.brown,
      foregroundColor: Colors.brown,
    ),
    summaryChip(
      theme,
      label: 'RUNNING $runningSessions',
      tooltip: 'Sesiones running: $runningSessions',
      backgroundColor: Colors.blue,
      foregroundColor: Colors.blue,
    ),
    summaryChip(
      theme,
      label: 'COMPLETED $completedSessions',
      tooltip: 'Sesiones completed: $completedSessions',
      backgroundColor: Colors.green,
      foregroundColor: Colors.green,
    ),
    summaryChip(
      theme,
      label: 'ERROR $errorSessions',
      tooltip: 'Sesiones con error: $errorSessions',
      backgroundColor: Colors.red,
      foregroundColor: Colors.red,
    ),
    summaryChip(
      theme,
      label: 'ATENCION $attentionSessions',
      tooltip: 'Sesiones con atencion: $attentionSessions',
      backgroundColor: Colors.orange,
      foregroundColor: Colors.orange,
    ),
    summaryChip(
      theme,
      label: 'REHIDRATADAS $rehydratedSessions',
      tooltip: 'Sesiones rehidratadas: $rehydratedSessions',
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.indigo,
    ),
    summaryChip(
      theme,
      label: 'INACTIVAS $staleSessions',
      tooltip: 'Sesiones inactivas: $staleSessions',
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.blueGrey,
    ),
  ],
);
