import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_support.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_summary_widget_test_support.dart';

void main() {
  test('resuelve severidad media con riesgo medio cuando no hay empate', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 8,
        totalPages: 16,
        attentionSessions: 2,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 5,
        errorSessions: 0,
        runningSessions: 3,
        uniqueScanners: 2,
        primaryScannerLabel: 'Scanner H',
        adfSessions: 6,
        flatbedSessions: 2,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con seguimiento',
      affectedSessions: 2,
      affectedRatioLabel: '25% del subconjunto visible',
      severityLabel: 'media',
      operationalRiskLabel: 'medio',
      dominantStateLabel: 'completed (5)',
      dominantPatternRecommendation:
          'Hay margen para limpieza o exportacion del subconjunto visible.',
      nextStepRecommendation:
          'Revisar el subconjunto afectado antes de seguir cargando trabajo.',
      focus: '1 rehidratadas · 1 inactivas',
    );
  });

  test('mantiene riesgo bajo con severidad nula aunque domine running', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 4,
        totalPages: 8,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 1,
        errorSessions: 0,
        runningSessions: 3,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner I',
        adfSessions: 4,
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
      dominantStateLabel: 'running (3)',
      dominantPatternRecommendation:
          'La mayor carga sigue activa; evitar descartes amplios.',
      nextStepRecommendation:
          'Mantener monitoreo normal sobre el subconjunto visible.',
      focus: isNull,
    );
  });

  test('prioriza incidencias cuando hay errores y seguimiento al mismo tiempo', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 7,
        totalPages: 14,
        attentionSessions: 3,
        rehydratedSessions: 2,
        staleSessions: 1,
        completedSessions: 2,
        errorSessions: 2,
        runningSessions: 3,
        uniqueScanners: 2,
        primaryScannerLabel: 'Scanner J',
        adfSessions: 5,
        flatbedSessions: 2,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con incidencias',
      healthBadgeLabel: 'Atencion alta',
      affectedSessions: 2,
      affectedRatioLabel: '29% del subconjunto visible',
      severityLabel: 'media',
      operationalRiskLabel: 'medio',
      dominantStateLabel: 'running (3)',
      dominantPatternRecommendation:
          'La mayor carga sigue activa; evitar descartes amplios.',
      nextStepRecommendation:
          'Revisar el subconjunto afectado antes de seguir cargando trabajo.',
      focus: '2 con error para revisar primero',
    );
  });

  test('mantiene foco preventivo consistente aunque no haya detalle visible', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 5,
        totalPages: 9,
        attentionSessions: 1,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 4,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner K',
        adfSessions: 5,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con seguimiento',
      healthBadgeLabel: 'Revisar',
      affectedSessions: 1,
      affectedRatioLabel: '20% del subconjunto visible',
      severityLabel: 'baja',
      operationalRiskLabel: 'medio',
      dominantStateLabel: 'completed (4)',
      dominantPatternRecommendation:
          'Hay margen para limpieza o exportacion del subconjunto visible.',
      nextStepRecommendation:
          'Resolver las sesiones afectadas sin interrumpir la operacion general.',
      focus: '0 rehidratadas · 0 inactivas',
    );
  });

  test('expone descripcion limpia y badge OK', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 2,
        totalPages: 4,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 1,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner L',
        adfSessions: 2,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'limpio',
      healthBadgeLabel: 'OK',
      healthDescription:
          'El subconjunto visible no muestra sesiones con atencion.',
    );
  });

  test('expone descripcion de seguimiento y badge revisar', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 6,
        attentionSessions: 1,
        rehydratedSessions: 1,
        staleSessions: 0,
        completedSessions: 2,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner M',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con seguimiento',
      healthBadgeLabel: 'Revisar',
      healthDescription:
          'No hay errores, pero si sesiones rehidratadas o inactivas.',
    );
  });

  test('expone descripcion de incidencias y badge atencion alta', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 7,
        attentionSessions: 2,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 1,
        errorSessions: 1,
        runningSessions: 2,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner N',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expectSummaryViewData(
      viewData,
      healthLabel: 'con incidencias',
      healthBadgeLabel: 'Atencion alta',
      healthDescription:
          'Hay sesiones con error dentro del subconjunto visible.',
    );
  });

}
