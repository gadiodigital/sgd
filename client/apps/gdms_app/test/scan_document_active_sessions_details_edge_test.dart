import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_test_support.dart';

void main() {
  testWidgets(
    'detalle usa titulo fallback cuando el scanner no tiene nombre',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget([
          buildActiveScanSession(
            sessionId: 's-n1',
            scannerName: '',
            mode: 'adf-simplex',
            status: 'running',
            pageCount: 1,
            touchedAgo: const Duration(minutes: 5),
          ),
        ]),
      );

      await tester.ensureVisible(find.text('Detalle'));
      await tester.tap(find.text('Detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de sesion'), findsOneWidget);
      expect(find.text('Sesion: s-n1'), findsOneWidget);
    },
  );

  testWidgets(
    'detalle muestra estado sin dato y modo custom cuando el payload no viene normalizado',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget([
          buildActiveScanSession(
            sessionId: 's-c1',
            scannerName: 'Broker',
            mode: 'custom-source',
            status: '',
            pageCount: 5,
            touchedAgo: const Duration(minutes: 10),
          ),
        ]),
      );

      await tester.ensureVisible(find.text('Detalle'));
      await tester.tap(find.text('Detalle'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sin estado'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('custom-source'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fuente: custom-source'), findsOneWidget);
    },
  );

  testWidgets(
    'detalle usa el nombre real del scanner como titulo cuando esta disponible',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget([
          buildActiveScanSession(
            sessionId: 's-t1',
            scannerName: 'Fujitsu fi-7160',
            mode: 'adf-duplex',
            status: 'error',
            pageCount: 9,
            touchedAgo: const Duration(minutes: 30),
          ),
        ]),
      );

      await tester.ensureVisible(find.text('Abrir primera con error (1)'));
      await tester.tap(find.text('Abrir primera con error (1)'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Fujitsu fi-7160'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sesion: s-t1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'detalle muestra etiquetas empty y canceled segun el estado terminal real',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget([
          buildActiveScanSession(
            sessionId: 's-e1',
            scannerName: 'Kodak',
            mode: 'flatbed-single',
            status: 'empty',
            pageCount: 0,
            touchedAgo: const Duration(minutes: 8),
          ),
          buildActiveScanSession(
            sessionId: 's-x1',
            scannerName: 'Brother',
            mode: 'adf-simplex',
            status: 'canceled',
            pageCount: 0,
            touchedAgo: const Duration(minutes: 9),
          ),
        ]),
      );

      final detailButtons = find.widgetWithText(OutlinedButton, 'Detalle');

      await tester.ensureVisible(detailButtons.first);
      await tester.tap(detailButtons.first);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Empty'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(detailButtons.last);
      await tester.tap(detailButtons.last);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Canceled'),
        ),
        findsOneWidget,
      );
    },
  );
}
