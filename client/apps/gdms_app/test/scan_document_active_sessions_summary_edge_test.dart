import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_summary_widget_test_support.dart';

void main() {
  testWidgets('resume estado sin sesiones visibles', (tester) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
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

    expectSummaryTexts([
      'Lote visible: sin sesiones',
      'Sin datos',
      'No hay sesiones visibles para resumir.',
      'Paginas: 0 · Atencion: 0 · Rehidratadas: 0 · Inactivas: 0',
    ]);
  });

  testWidgets('resume estado dominante equilibrado cuando hay empate', (
    tester,
  ) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
        totalSessions: 6,
        totalPages: 14,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 3,
        errorSessions: 0,
        runningSessions: 3,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner D',
        adfSessions: 6,
        flatbedSessions: 0,
      ),
    );

    expectSummaryTexts([
      'Estado dominante: equilibrado entre running / completed (3)',
      'EQUILIBRADO',
      'Riesgo operativo: bajo',
      'Patron dominante: Conviene revisar varios frentes antes de decidir una accion masiva.',
    ]);
  });

  testWidgets('resume seguimiento con severidad baja', (tester) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
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

    expectSummaryTexts([
      'Lote visible: con seguimiento',
      'Sesiones afectadas: 1 de 10',
      'Cobertura afectada: 10% del subconjunto visible',
      'Severidad visible: baja',
      'BAJA',
      'Riesgo operativo: medio',
      'Estado dominante: completed (6)',
      'COMPLETED',
      'Patron dominante: Hay margen para limpieza o exportacion del subconjunto visible.',
      'Siguiente paso: Resolver las sesiones afectadas sin interrumpir la operacion general.',
      'Foco operativo: 1 rehidratadas · 0 inactivas',
    ]);
  });

  testWidgets('resume seguimiento sin estado dominante', (tester) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
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

    expectSummaryTexts([
      'Lote visible: con seguimiento',
      'Sesiones afectadas: 1 de 3',
      'Cobertura afectada: 33% del subconjunto visible',
      'Severidad visible: media',
      'MEDIA',
      'Riesgo operativo: medio',
      'Estado dominante: sin estado dominante',
      'SIN ESTADO',
      'Patron dominante: No hay estados operativos con volumen relevante.',
      'Siguiente paso: Revisar el subconjunto afectado antes de seguir cargando trabajo.',
      'Foco operativo: 0 rehidratadas · 1 inactivas',
    ]);
  });
}
