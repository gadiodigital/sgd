import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_test_support.dart';

void main() {
  testWidgets(
    'cerrar el detalle abierto desde acciones no dispara callbacks y cierra el dialogo',
    (tester) async {
      String? resumedSessionId;
      String? discardedSessionId;
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          onResumeRequested: (sessionId) => resumedSessionId = sessionId,
          onDiscardRequested: (sessionId) => discardedSessionId = sessionId,
        ),
      );

      await tester.ensureVisible(find.text('Abrir primera con error (1)'));
      await tester.tap(find.text('Abrir primera con error (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
      await tester.pumpAndSettle();

      expect(resumedSessionId, isNull);
      expect(discardedSessionId, isNull);
      expect(find.text('Sesion: s-3'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'detalle marca abierta aqui cuando coincide con la sesion actual',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          currentSessionId: 's-3',
        ),
      );

      await tester.ensureVisible(find.text('Abrir primera con error (1)'));
      await tester.tap(find.text('Abrir primera con error (1)'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Abierta aqui'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sesion: s-3'), findsOneWidget);
    },
  );

  testWidgets(
    'detalle muestra chips de rehidratada e inactiva para sesiones recuperadas viejas',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget([
          buildActiveScanSession(
            sessionId: 's-r1',
            scannerName: 'Epson',
            mode: 'flatbed-single',
            status: 'completed',
            pageCount: 4,
            touchedAgo: const Duration(hours: 3),
            isRehydrated: true,
          ),
        ]),
      );

      await tester.ensureVisible(find.text('Abrir primera con atencion'));
      await tester.tap(find.text('Abrir primera con atencion'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rehidratada'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Inactiva'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Completed'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fuente: Cama plana'), findsOneWidget);
    },
  );

  testWidgets(
    'detalle muestra chip dormida sin marcar inactiva para sesiones recientes sin error',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget([
          buildActiveScanSession(
            sessionId: 's-d1',
            scannerName: 'Canon',
            mode: 'adf-simplex',
            status: 'running',
            pageCount: 2,
            touchedAgo: const Duration(minutes: 20),
          ),
        ]),
      );

      await tester.ensureVisible(find.text('Detalle'));
      await tester.tap(find.text('Detalle'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Dormida'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Inactiva'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Running'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fuente: ADF'), findsOneWidget);
    },
  );
}
