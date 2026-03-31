import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_support.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_summary_widget_test_support.dart';

void main() {
  test('resuelve estado sin datos cuando no hay sesiones visibles', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 0,
        totalPages: 0,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 0,
        errorSessions: 0,
        runningSessions: 0,
        uniqueScanners: 0,
        primaryScannerLabel: 'sin dato',
        adfSessions: 0,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'sin sesiones',
      healthBadgeLabel: 'Sin datos',
      affectedSessions: 0,
      affectedRatioLabel: 'sin datos',
      severityLabel: 'nula',
      operationalRiskLabel: 'bajo',
      dominantStateLabel: 'sin datos',
      dominantPatternRecommendation:
          'No hay suficiente informacion para priorizar por estado.',
      focus: isNull,
    );
  });

  test('resuelve resumen limpio con riesgo bajo', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 7,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 2,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner A',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'limpio',
      affectedSessions: 0,
      affectedRatioLabel: '0% del subconjunto visible',
      severityLabel: 'nula',
      operationalRiskLabel: 'bajo',
      dominantStateLabel: 'completed (2)',
      dominantPatternRecommendation:
          'Hay margen para limpieza o exportacion del subconjunto visible.',
      nextStepRecommendation:
          'Mantener monitoreo normal sobre el subconjunto visible.',
      focus: isNull,
    );
  });

  test('resuelve incidencias con riesgo alto cuando media y empate', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 5,
        totalPages: 18,
        attentionSessions: 3,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 1,
        errorSessions: 2,
        runningSessions: 2,
        uniqueScanners: 2,
        primaryScannerLabel: 'Scanner B',
        adfSessions: 4,
        flatbedSessions: 1,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con incidencias',
      affectedSessions: 2,
      severityLabel: 'media',
      operationalRiskLabel: 'alto',
      dominantStateLabel: 'equilibrado entre running / error (2)',
      dominantPatternRecommendation:
          'Conviene revisar varios frentes antes de decidir una accion masiva.',
      focus: '2 con error para revisar primero',
    );
  });

  test('resuelve seguimiento con riesgo alto y foco preventivo', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 4,
        totalPages: 11,
        attentionSessions: 2,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 2,
        errorSessions: 0,
        runningSessions: 2,
        uniqueScanners: 2,
        primaryScannerLabel: 'Scanner C',
        adfSessions: 2,
        flatbedSessions: 2,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con seguimiento',
      affectedSessions: 2,
      affectedRatioLabel: '50% del subconjunto visible',
      severityLabel: 'alta',
      operationalRiskLabel: 'alto',
      dominantStateLabel: 'equilibrado entre running / completed (2)',
      focus: '1 rehidratadas · 1 inactivas',
    );
  });

  test('resuelve patron dominante especifico para running', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 5,
        totalPages: 12,
        attentionSessions: 1,
        rehydratedSessions: 1,
        staleSessions: 0,
        completedSessions: 1,
        errorSessions: 0,
        runningSessions: 4,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner D',
        adfSessions: 5,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      dominantStateLabel: 'running (4)',
      dominantPatternRecommendation:
          'La mayor carga sigue activa; evitar descartes amplios.',
      operationalRiskLabel: 'medio',
    );
  });

  test('resuelve severidad baja con riesgo medio', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 10,
        totalPages: 20,
        attentionSessions: 1,
        rehydratedSessions: 1,
        staleSessions: 0,
        completedSessions: 6,
        errorSessions: 0,
        runningSessions: 4,
        uniqueScanners: 2,
        primaryScannerLabel: 'Scanner F',
        adfSessions: 8,
        flatbedSessions: 2,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con seguimiento',
      affectedSessions: 1,
      affectedRatioLabel: '10% del subconjunto visible',
      severityLabel: 'baja',
      operationalRiskLabel: 'medio',
      dominantStateLabel: 'completed (6)',
      nextStepRecommendation:
          'Resolver las sesiones afectadas sin interrumpir la operacion general.',
      focus: '1 rehidratadas · 0 inactivas',
    );
  });

  test('resuelve sin estado dominante cuando no hay estados operativos', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 5,
        attentionSessions: 1,
        rehydratedSessions: 0,
        staleSessions: 1,
        completedSessions: 0,
        errorSessions: 0,
        runningSessions: 0,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner G',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con seguimiento',
      affectedSessions: 1,
      severityLabel: 'media',
      operationalRiskLabel: 'medio',
      dominantStateLabel: 'sin estado dominante',
      dominantPatternRecommendation:
          'No hay estados operativos con volumen relevante.',
      focus: '0 rehidratadas · 1 inactivas',
    );
  });

  test('resuelve patron dominante especifico para error', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 6,
        totalPages: 10,
        attentionSessions: 3,
        rehydratedSessions: 1,
        staleSessions: 0,
        completedSessions: 1,
        errorSessions: 4,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner E',
        adfSessions: 6,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con incidencias',
      affectedSessions: 4,
      severityLabel: 'alta',
      operationalRiskLabel: 'alto',
      dominantStateLabel: 'error (4)',
      dominantPatternRecommendation:
          'Conviene abrir o descartar errores antes de seguir operando.',
      focus: '4 con error para revisar primero',
    );
  });
}
