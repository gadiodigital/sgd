import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_session_details_dialog.dart';

import 'scan_document_active_sessions_test_support.dart';

Widget buildDetailsDialogHarness({
  required ActiveScanSession session,
  required bool isCurrent,
  required bool isBusy,
  required ValueChanged<String> onResumeRequested,
  required ValueChanged<String> onDiscardRequested,
}) {
  return MaterialApp(
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog<void>(
              context: context,
              builder: (_) => ScanDocumentActiveSessionDetailsDialog(
                session: session,
                isCurrent: isCurrent,
                isBusy: isBusy,
                onResumeRequested: onResumeRequested,
                onDiscardRequested: onDiscardRequested,
              ),
            );
          });
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  testWidgets(
    'dialogo renderiza titulo chips y lineas de detalle para una sesion recuperada actual',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-dialog-1',
        scannerName: 'Fujitsu',
        mode: 'flatbed-single',
        status: 'completed',
        pageCount: 6,
        touchedAgo: const Duration(hours: 3),
        isRehydrated: true,
      );

      await tester.pumpWidget(
        buildDetailsDialogHarness(
          session: session,
          isCurrent: true,
          isBusy: false,
          onResumeRequested: (_) {},
          onDiscardRequested: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fujitsu'), findsOneWidget);
      expect(find.text('Abierta aqui'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Rehidratada'), findsOneWidget);
      expect(find.text('Inactiva'), findsOneWidget);
      expect(find.text('Cama plana'), findsAtLeastNWidgets(1));
      expect(find.text('Sesion: s-dialog-1'), findsOneWidget);
      expect(find.text('Paginas: 6'), findsOneWidget);
      expect(find.textContaining('Creada:'), findsOneWidget);
      expect(find.textContaining('Ultima actividad:'), findsOneWidget);
      expect(find.text('Fuente: Cama plana'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cerrar'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Descartar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reanudar'), findsOneWidget);
    },
  );

  testWidgets(
    'dialogo en busy bloquea cerrar descartar y reanudar',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-dialog-2',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 10),
      );

      await tester.pumpWidget(
        buildDetailsDialogHarness(
          session: session,
          isCurrent: false,
          isBusy: true,
          onResumeRequested: (_) {},
          onDiscardRequested: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final closeButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cerrar'),
      );
      final discardButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Descartar'),
      );
      final resumeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Reanudar'),
      );

      expect(closeButton.onPressed, isNull);
      expect(discardButton.onPressed, isNull);
      expect(resumeButton.onPressed, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  testWidgets(
    'dialogo reanuda la sesion correcta y se cierra',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-dialog-3',
        scannerName: 'Epson',
        mode: 'adf-duplex',
        status: 'error',
        pageCount: 9,
        touchedAgo: const Duration(hours: 1),
      );
      String? resumedSessionId;

      await tester.pumpWidget(
        buildDetailsDialogHarness(
          session: session,
          isCurrent: false,
          isBusy: false,
          onResumeRequested: (sessionId) => resumedSessionId = sessionId,
          onDiscardRequested: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Reanudar'));
      await tester.pumpAndSettle();

      expect(resumedSessionId, 's-dialog-3');
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'dialogo descarta la sesion correcta y preserva fuente custom cuando aplica',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-dialog-4',
        scannerName: 'Broker',
        mode: 'custom-source',
        status: '',
        pageCount: 1,
        touchedAgo: const Duration(minutes: 20),
      );
      String? discardedSessionId;

      await tester.pumpWidget(
        buildDetailsDialogHarness(
          session: session,
          isCurrent: false,
          isBusy: false,
          onResumeRequested: (_) {},
          onDiscardRequested: (sessionId) => discardedSessionId = sessionId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin estado'), findsOneWidget);
      expect(find.text('custom-source'), findsAtLeastNWidgets(1));
      expect(find.text('Fuente: custom-source'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Descartar'));
      await tester.pumpAndSettle();

      expect(discardedSessionId, 's-dialog-4');
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
