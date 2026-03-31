import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_visuals.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_visuals_support.dart';

void main() {
  group('summaryChip', () {
    testWidgets('usa tooltip explicito y estilo compacto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: summaryChip(
              ThemeData(),
              label: 'RIESGO',
              tooltip: 'Riesgo operativo alto',
              backgroundColor: Colors.red,
              foregroundColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('RIESGO'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Riesgo operativo alto');

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.visualDensity, VisualDensity.compact);
      expect(chip.backgroundColor, Colors.red.withValues(alpha: 0.14));
      expect((chip.side as BorderSide).color, Colors.red.withValues(alpha: 0.3));
    });

    testWidgets('usa el label como tooltip por default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: summaryChip(
              ThemeData(),
              label: 'SEVERIDAD',
              backgroundColor: Colors.orange,
              foregroundColor: Colors.orange,
            ),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'SEVERIDAD');
    });
  });

  group('summarySignalRow', () {
    testWidgets('renderiza texto y chip dentro de un wrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: summarySignalRow(
              ThemeData(),
              text: 'Estado dominante: error (2)',
              chipLabel: 'ERROR',
              tooltip: 'Estado dominante del lote',
              backgroundColor: Colors.red,
              foregroundColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Estado dominante: error (2)'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, 8);
      expect(wrap.runSpacing, 8);
      expect(wrap.crossAxisAlignment, WrapCrossAlignment.center);
    });
  });

  group('operationalPulseBanner', () {
    testWidgets('renderiza el pulso operativo con estilo resaltado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: operationalPulseBanner(
              ThemeData(),
              affectedSessions: 2,
              totalSessions: 5,
              severityLabel: 'media',
              operationalRiskLabel: 'alto',
              backgroundColor: Colors.orange,
              foregroundColor: Colors.deepOrange,
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Pulso operativo: 2/5 afectadas · severidad media · riesgo alto',
        ),
        findsOneWidget,
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, Colors.orange.withValues(alpha: 0.08));
      expect(decoration.border, isA<Border>());
    });
  });

  group('operationalMarkers', () {
    testWidgets('renderiza chips base del lote visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: operationalMarkers(
              ThemeData(),
              totalSessions: 3,
              totalPages: 9,
              primaryScannerLabel: 'Scanner A',
              uniqueScanners: 1,
              adfSessions: 3,
              flatbedSessions: 0,
              completedSessions: 2,
              runningSessions: 1,
              errorSessions: 0,
              attentionSessions: 0,
              rehydratedSessions: 0,
              staleSessions: 0,
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('ATENCION BAJA'), findsOneWidget);
      expect(find.text('PAGINAS 9'), findsOneWidget);
      expect(find.text('PROMEDIO 3.0'), findsOneWidget);
      expect(find.text('MONOSCANNER'), findsOneWidget);
      expect(find.text('ORIGEN ADF'), findsOneWidget);
      expect(find.text('COMPLETED 2'), findsOneWidget);
      expect(find.byTooltip('Volumen documental: Lote medio de 9 paginas'), findsOneWidget);
      expect(find.byTooltip('Operacion concentrada en un solo scanner'), findsOneWidget);
    });

    testWidgets('renderiza chips temporales cuando hay ventana de actividad', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: operationalMarkers(
              ThemeData(),
              totalSessions: 2,
              totalPages: 6,
              mostRecentActivityAtUtc: DateTime(2026, 3, 30, 15, 30),
              oldestActivityAtUtc: DateTime(2026, 3, 30, 14, 0),
              primaryScannerLabel: 'Scanner Z',
              uniqueScanners: 2,
              adfSessions: 1,
              flatbedSessions: 1,
              completedSessions: 1,
              runningSessions: 1,
              errorSessions: 0,
              attentionSessions: 1,
              rehydratedSessions: 1,
              staleSessions: 1,
            ),
          ),
        ),
      );

      expect(find.text('ACTIVIDAD'), findsOneWidget);
      expect(find.text('VENTANA'), findsOneWidget);
      expect(find.text('RANGO'), findsOneWidget);
      expect(find.text('MULTISCANNER'), findsOneWidget);
      expect(find.text('ORIGEN MIXTO'), findsOneWidget);
      expect(find.byTooltip('Ultima actividad: 30/03/2026 15:30'), findsOneWidget);
      expect(
        find.byTooltip('Ventana visible: 30/03/2026 14:00 a 30/03/2026 15:30'),
        findsOneWidget,
      );
      expect(find.byTooltip('Rango de actividad: 1 h 30 min'), findsOneWidget);
      expect(find.byTooltip('Capacidad paralela en 2 scanners'), findsOneWidget);
    });

  });
}
