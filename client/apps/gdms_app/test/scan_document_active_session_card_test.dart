import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_session_card.dart';

import 'scan_document_active_sessions_test_support.dart';

Widget buildCardHarness(
  Widget child,
) {
  return MaterialApp(
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets(
    'tarjeta renderiza señales de contexto y usa fallback de sessionId sin scanner',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-card-1',
        scannerName: '',
        mode: 'adf-duplex',
        status: 'completed',
        pageCount: 7,
        touchedAgo: const Duration(hours: 3),
        isRehydrated: true,
      );

      await tester.pumpWidget(
        buildCardHarness(
          ScanDocumentActiveSessionCard(
            session: session,
            isBusy: false,
            isCurrent: true,
            isPriority: true,
            onDetailsRequested: () {},
            onResumeRequested: (_) {},
            onDiscardRequested: (_) {},
          ),
        ),
      );

      expect(find.text('s-card-1'), findsOneWidget);
      expect(find.text('Abierta aqui'), findsOneWidget);
      expect(find.text('Prioridad'), findsOneWidget);
      expect(find.text('Rehidratada'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Inactiva'), findsOneWidget);
      expect(find.text('Sesion abierta en este dialogo'), findsOneWidget);
      expect(find.text('ADF duplex · 7 pag.'), findsOneWidget);
      expect(find.textContaining('Sesion s-card-1'), findsOneWidget);
      expect(find.textContaining('Ultima actividad:'), findsOneWidget);
    },
  );

  testWidgets(
    'tarjeta muestra dormida sin marcar inactiva para sesiones recientes',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-card-2',
        scannerName: 'Canon',
        mode: 'flatbed-single',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 20),
      );

      await tester.pumpWidget(
        buildCardHarness(
          ScanDocumentActiveSessionCard(
            session: session,
            isBusy: false,
            isCurrent: false,
            isPriority: false,
            onDetailsRequested: () {},
            onResumeRequested: (_) {},
            onDiscardRequested: (_) {},
          ),
        ),
      );

      expect(find.text('Canon'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Dormida'), findsOneWidget);
      expect(find.text('Inactiva'), findsNothing);
      expect(find.text('Cama plana · 2 pag.'), findsOneWidget);
    },
  );

  testWidgets(
    'tarjeta dispara callbacks de detalle reanudar y descartar con el sessionId correcto',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-card-3',
        scannerName: 'Epson',
        mode: 'adf-simplex',
        status: 'error',
        pageCount: 5,
        touchedAgo: const Duration(hours: 1),
      );
      var detailsOpened = false;
      String? resumedSessionId;
      String? discardedSessionId;

      await tester.pumpWidget(
        buildCardHarness(
          ScanDocumentActiveSessionCard(
            session: session,
            isBusy: false,
            isCurrent: false,
            isPriority: false,
            onDetailsRequested: () => detailsOpened = true,
            onResumeRequested: (sessionId) => resumedSessionId = sessionId,
            onDiscardRequested: (sessionId) => discardedSessionId = sessionId,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Detalle'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reanudar'));
      await tester.pump();
      await tester.tap(find.byTooltip('Descartar sesion'));
      await tester.pump();

      expect(detailsOpened, isTrue);
      expect(resumedSessionId, 's-card-3');
      expect(discardedSessionId, 's-card-3');
    },
  );

  testWidgets(
    'tarjeta en busy deja detalle habilitado y bloquea reanudar y descartar',
    (tester) async {
      final session = buildActiveScanSession(
        sessionId: 's-card-4',
        scannerName: 'Brother',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 4,
        touchedAgo: const Duration(minutes: 3),
      );
      var detailsOpened = false;

      await tester.pumpWidget(
        buildCardHarness(
          ScanDocumentActiveSessionCard(
            session: session,
            isBusy: true,
            isCurrent: false,
            isPriority: false,
            onDetailsRequested: () => detailsOpened = true,
            onResumeRequested: (_) {},
            onDiscardRequested: (_) {},
          ),
        ),
      );

      final detailButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Detalle'),
      );
      final resumeButton = tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      ).last;
      final discardButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      expect(detailButton.onPressed, isNotNull);
      expect(resumeButton.onPressed, isNull);
      expect(discardButton.onPressed, isNull);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Detalle'));
      await tester.pump();

      expect(detailsOpened, isTrue);
    },
  );
}
