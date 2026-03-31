import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_visuals.dart';

void main() {
  group('operationalMarkers advanced', () {
    testWidgets('renderiza chips avanzados de estabilidad y operacion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: operationalMarkers(
              ThemeData(),
              totalSessions: 5,
              totalPages: 18,
              primaryScannerLabel: 'Scanner B',
              uniqueScanners: 2,
              adfSessions: 4,
              flatbedSessions: 1,
              completedSessions: 1,
              runningSessions: 2,
              errorSessions: 2,
              attentionSessions: 3,
              rehydratedSessions: 1,
              staleSessions: 1,
            ),
          ),
        ),
      );

      expect(find.text('ESTABILIDAD BAJA'), findsOneWidget);
      expect(find.text('RECUPERABILIDAD MEDIA'), findsOneWidget);
      expect(find.text('CONTINUIDAD ACTIVA'), findsOneWidget);
      expect(find.text('PRESION ALTA'), findsOneWidget);
      expect(find.text('BALANCE EJECUCION'), findsOneWidget);
      expect(find.text('MADUREZ MEDIA'), findsOneWidget);
      expect(
        find.byTooltip(
          'Estabilidad del lote: 4 de 5 sesiones muestran degradacion operativa',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Recuperabilidad del lote: Balanceado entre sesiones degradadas y recuperables',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Continuidad del lote: 2 sesiones activas frente a 1 finalizadas',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Presion del lote: 5 señales activas o con seguimiento sobre 5 sesiones',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Madurez del lote: 3 de 5 sesiones muestran avance de resolucion',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renderiza chips de origen, volumen y capacidad del lote', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: operationalMarkers(
              ThemeData(),
              totalSessions: 4,
              totalPages: 24,
              primaryScannerLabel: 'Scanner C',
              uniqueScanners: 3,
              adfSessions: 2,
              flatbedSessions: 2,
              completedSessions: 2,
              runningSessions: 1,
              errorSessions: 1,
              attentionSessions: 2,
              rehydratedSessions: 1,
              staleSessions: 0,
            ),
          ),
        ),
      );

      expect(find.text('VOLUMEN ALTO'), findsOneWidget);
      expect(find.text('PROMEDIO 6.0'), findsOneWidget);
      expect(find.text('SCANNERS 3'), findsOneWidget);
      expect(find.text('MULTISCANNER'), findsOneWidget);
      expect(find.text('ADF 2'), findsOneWidget);
      expect(find.text('FLATBED 2'), findsOneWidget);
      expect(find.text('ORIGEN MIXTO'), findsOneWidget);
      expect(
        find.byTooltip('Volumen documental: Lote pesado de 24 paginas'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Promedio de paginas por sesion: 6.0'),
        findsOneWidget,
      );
      expect(find.byTooltip('Scanners visibles: 3'), findsOneWidget);
      expect(
        find.byTooltip('Capacidad paralela en 3 scanners'),
        findsOneWidget,
      );
      expect(find.byTooltip('Sesiones ADF: 2'), findsOneWidget);
      expect(find.byTooltip('Sesiones cama plana: 2'), findsOneWidget);
      expect(
        find.byTooltip('Mezcla de origen: 2 ADF y 2 cama plana'),
        findsOneWidget,
      );
    });
  });
}
