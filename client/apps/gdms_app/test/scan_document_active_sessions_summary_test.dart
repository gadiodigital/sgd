import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_summary_widget_test_support.dart';

void main() {
  testWidgets('resume lote limpio sin sesiones afectadas', (tester) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
        totalSessions: 3,
        totalPages: 9,
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

    expectSummaryTexts([
      'Lote visible: limpio',
      'Pulso operativo: 0/3 afectadas · severidad nula · riesgo bajo',
      'ATENCION BAJA',
      'PAGINAS 9',
      'VOLUMEN MEDIO',
      'PROMEDIO 3.0',
      'PRINCIPAL',
      'SCANNERS 1',
      'MONOSCANNER',
      'EJECUCION MEDIA',
      'CIERRE ALTO',
      'FALLA BAJA',
      'REHIDRATACION BAJA',
      'INACTIVIDAD BAJA',
      'ESTABILIDAD ALTA',
      'RECUPERABILIDAD ALTA',
      'CONTINUIDAD CIERRE',
      'PRESION BAJA',
      'BALANCE CIERRE',
      'MADUREZ MEDIA',
      'ADF 3',
      'FLATBED 0',
      'ORIGEN ADF',
      'RUNNING 1',
      'COMPLETED 2',
      'ERROR 0',
      'ATENCION 0',
      'REHIDRATADAS 0',
      'INACTIVAS 0',
      'Sesiones afectadas: 0 de 3',
      'Cobertura afectada: 0% del subconjunto visible',
      'Severidad visible: nula',
      'NULA',
      'Riesgo operativo: bajo',
      'Estado dominante: completed (2)',
      'COMPLETED',
      'Patron dominante: Hay margen para limpieza o exportacion del subconjunto visible.',
      'Siguiente paso: Mantener monitoreo normal sobre el subconjunto visible.',
      'ACCION',
      'OK',
    ]);
    expect(find.byTooltip('Salud del lote visible: limpio'), findsOneWidget);
    expect(
      find.byTooltip(
        'Densidad de atencion: Subconjunto con poca o ninguna presion operativa',
      ),
      findsOneWidget,
    );
    expectSummaryTooltips([
      'Severidad visible: nula',
      'Riesgo operativo: bajo',
      'Estado dominante: completed (2)',
      'Paginas visibles: 9',
      'Volumen documental: Lote medio de 9 paginas',
      'Promedio de paginas por sesion: 3.0',
      'Scanner principal: Scanner A',
      'Scanners visibles: 1',
      'Operacion concentrada en un solo scanner',
    ]);
    expectSummaryTooltips([
      'Nivel de ejecucion: 1 de 3 sesiones mantienen carga activa',
      'Nivel de cierre: 2 de 3 sesiones ya quedaron finalizadas',
      'Nivel de falla: Pocas o ninguna sesion con error en este lote',
      'Nivel de rehidratacion: Pocas o ninguna sesion rehidratada en este lote',
      'Nivel de inactividad: Pocas o ninguna sesion inactiva en este lote',
      'Estabilidad del lote: Lote estable sin señales relevantes de degradacion',
      'Recuperabilidad del lote: 3 sesiones recuperables frente a 0 degradadas',
      'Continuidad del lote: 2 sesiones finalizadas frente a 1 activas',
      'Presion del lote: 1 sesiones con presion puntual sobre 3',
      'Balance del lote: Predomina el cierre sobre la ejecucion',
      'Madurez del lote: 2 de 3 sesiones muestran avance de resolucion',
    ]);
    expectSummaryTooltips([
      'Sesiones ADF: 3',
      'Sesiones cama plana: 0',
      'Mezcla de origen: Solo ADF',
      'Sesiones con atencion: 0',
    ]);
    expect(
      find.byTooltip(
        'Siguiente paso: Mantener monitoreo normal sobre el subconjunto visible.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('resume incidencias con conteo de errores', (tester) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
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

    expectSummaryTexts([
      'Lote visible: con incidencias',
      'Pulso operativo: 2/5 afectadas · severidad media · riesgo alto',
      'ATENCION ALTA',
      'PAGINAS 18',
      'VOLUMEN MEDIO',
      'PROMEDIO 3.6',
      'PRINCIPAL',
      'SCANNERS 2',
      'MULTISCANNER',
      'EJECUCION MEDIA',
      'CIERRE BAJO',
      'FALLA ALTA',
      'REHIDRATACION MEDIA',
      'INACTIVIDAD MEDIA',
      'ESTABILIDAD BAJA',
      'RECUPERABILIDAD MEDIA',
      'CONTINUIDAD ACTIVA',
      'PRESION ALTA',
      'ADF 4',
      'FLATBED 1',
      'ORIGEN MIXTO',
      'RUNNING 2',
      'COMPLETED 1',
      'ERROR 2',
      'ATENCION 3',
      'REHIDRATADAS 1',
      'INACTIVAS 1',
      'Sesiones afectadas: 2 de 5',
      'Cobertura afectada: 40% del subconjunto visible',
      'Severidad visible: media',
      'MEDIA',
      'Riesgo operativo: alto',
      'Estado dominante: equilibrado entre running / error (2)',
      'EQUILIBRADO',
      'Patron dominante: Conviene revisar varios frentes antes de decidir una accion masiva.',
      'Siguiente paso: Revisar el subconjunto afectado antes de seguir cargando trabajo.',
      'ACCION',
      'Foco operativo: 2 con error para revisar primero',
      'FOCO',
      'Atencion alta',
    ]);
  });

  testWidgets('resume seguimiento con foco preventivo', (tester) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
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

    expectSummaryTexts([
      'Lote visible: con seguimiento',
      'Pulso operativo: 2/4 afectadas · severidad alta · riesgo alto',
      'ATENCION ALTA',
      'PAGINAS 11',
      'VOLUMEN MEDIO',
      'PROMEDIO 2.8',
      'PRINCIPAL',
      'SCANNERS 2',
      'MULTISCANNER',
      'EJECUCION ALTA',
      'CIERRE MEDIO',
      'FALLA BAJA',
      'REHIDRATACION MEDIA',
      'INACTIVIDAD MEDIA',
      'ESTABILIDAD BAJA',
      'RECUPERABILIDAD ALTA',
      'CONTINUIDAD MIXTA',
      'PRESION ALTA',
      'ADF 2',
      'FLATBED 2',
      'ORIGEN MIXTO',
      'RUNNING 2',
      'COMPLETED 2',
      'ERROR 0',
      'ATENCION 2',
      'REHIDRATADAS 1',
      'INACTIVAS 1',
      'Sesiones afectadas: 2 de 4',
      'Cobertura afectada: 50% del subconjunto visible',
      'Severidad visible: alta',
      'ALTA',
      'Riesgo operativo: alto',
      'Estado dominante: equilibrado entre running / completed (2)',
      'EQUILIBRADO',
      'Patron dominante: Conviene revisar varios frentes antes de decidir una accion masiva.',
      'Siguiente paso: Priorizar limpieza o reanudacion sobre las sesiones afectadas.',
      'ACCION',
      'Foco operativo: 1 rehidratadas · 1 inactivas',
      'FOCO',
      'Revisar',
    ]);
  });

  testWidgets('muestra marcadores de actividad cuando hay ventana temporal', (
    tester,
  ) async {
    await pumpScanSummary(
      tester,
      summary: buildScanSummary(
        totalSessions: 2,
        totalPages: 6,
        attentionSessions: 1,
        rehydratedSessions: 0,
        staleSessions: 1,
        completedSessions: 1,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner Z',
        adfSessions: 2,
        flatbedSessions: 0,
        mostRecentActivityAtUtc: DateTime(2026, 3, 30, 15, 30),
        oldestActivityAtUtc: DateTime(2026, 3, 30, 14, 0),
      ),
    );

    expectSummaryTexts([
      'ACTIVIDAD',
      'VENTANA',
      'RANGO',
      'ATENCION ALTA',
      'ORIGEN ADF',
      'EJECUCION ALTA',
      'CIERRE MEDIO',
      'FALLA BAJA',
      'REHIDRATACION BAJA',
      'INACTIVIDAD ALTA',
      'ESTABILIDAD BAJA',
      'RECUPERABILIDAD ALTA',
      'CONTINUIDAD MIXTA',
      'PRESION ALTA',
      'VOLUMEN BAJO',
      'PROMEDIO 3.0',
      'MONOSCANNER',
      'Actividad visible: 30/03/2026 15:30 a 30/03/2026 14:00',
    ]);
    expect(
      find.byTooltip('Ultima actividad: 30/03/2026 15:30'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Ventana visible: 30/03/2026 14:00 a 30/03/2026 15:30'),
      findsOneWidget,
    );
    expect(find.byTooltip('Rango de actividad: 1 h 30 min'), findsOneWidget);
    expectSummaryTooltips([
      'Nivel de cierre: 1 de 2 sesiones ya permiten cierre parcial',
      'Nivel de falla: Pocas o ninguna sesion con error en este lote',
      'Nivel de rehidratacion: Pocas o ninguna sesion rehidratada en este lote',
      'Nivel de inactividad: 1 de 2 sesiones quedaron inactivas',
      'Estabilidad del lote: 1 de 2 sesiones muestran degradacion operativa',
      'Recuperabilidad del lote: 2 sesiones recuperables frente a 1 degradadas',
      'Continuidad del lote: Balanceado entre sesiones activas y finalizadas',
    ]);
  });
}
