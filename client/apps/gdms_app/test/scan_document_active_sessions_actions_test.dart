import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_document_active_sessions_test_support.dart';

void main() {
  testWidgets('exportar visibles usa el subconjunto filtrado actual', (
    tester,
  ) async {
    List<String>? exportedIds;
    await tester.pumpWidget(
      buildActiveSessionsWidget(
        buildActiveSessionsFixture(),
        onExportVisibleRequested: (sessions) {
          exportedIds = sessions.map((session) => session.sessionId).toList();
        },
      ),
    );

    findScannerField(tester).onChanged!('Canon');
    await tester.pump();

    await tester.ensureVisible(find.text('Exportar visibles'));
    await tester.tap(find.text('Exportar visibles'));
    await tester.pump();

    expect(exportedIds, ['s-1', 's-3']);
  });

  testWidgets(
    'reanudar primera con atencion usa la primera sesion prioritaria visible',
    (tester) async {
      String? resumedSessionId;
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          onResumeRequested: (sessionId) => resumedSessionId = sessionId,
        ),
      );

      await tester.ensureVisible(find.text('Reanudar primera con atencion'));
      await tester.tap(find.text('Reanudar primera con atencion'));
      await tester.pump();

      expect(resumedSessionId, 's-2');
    },
  );

  testWidgets(
    'abrir primera con atencion muestra el detalle de la sesion prioritaria visible',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      await tester.ensureVisible(find.text('Abrir primera con atencion'));
      await tester.tap(find.text('Abrir primera con atencion'));
      await tester.pumpAndSettle();

      expect(find.text('Sesion: s-2'), findsOneWidget);
      expect(find.text('Paginas: 1'), findsOneWidget);
      expect(find.text('Fuente: Cama plana'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reanudar'), findsOneWidget);
    },
  );

  testWidgets(
    'reanudar desde el detalle abierto por atencion dispara callback y cierra el dialogo',
    (tester) async {
      String? resumedSessionId;
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          onResumeRequested: (sessionId) => resumedSessionId = sessionId,
        ),
      );

      await tester.ensureVisible(find.text('Abrir primera con atencion'));
      await tester.tap(find.text('Abrir primera con atencion'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Reanudar'));
      await tester.pumpAndSettle();

      expect(resumedSessionId, 's-2');
      expect(find.text('Sesion: s-2'), findsNothing);
    },
  );

  testWidgets(
    'reanudar primera visible prioriza la primera sesion running del lote visible',
    (tester) async {
      String? resumedSessionId;
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          onResumeRequested: (sessionId) => resumedSessionId = sessionId,
        ),
      );

      await tester.ensureVisible(find.text('Reanudar primera visible'));
      await tester.tap(find.text('Reanudar primera visible'));
      await tester.pump();

      expect(resumedSessionId, 's-1');
    },
  );

  testWidgets(
    'abrir primera con atencion respeta la prioridad del subconjunto filtrado',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      findScannerField(tester).onChanged!('Canon');
      await tester.pump();

      await tester.ensureVisible(find.text('Abrir primera con atencion'));
      await tester.tap(find.text('Abrir primera con atencion'));
      await tester.pumpAndSettle();

      expect(find.text('Sesion: s-3'), findsOneWidget);
      expect(find.text('Paginas: 8'), findsOneWidget);
      expect(find.text('Fuente: ADF'), findsOneWidget);
    },
  );

  testWidgets(
    'reanudar primera visible cae al primer elemento filtrado si no hay running visibles',
    (tester) async {
      String? resumedSessionId;
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          onResumeRequested: (sessionId) => resumedSessionId = sessionId,
        ),
      );

      findChoiceChip(tester, 'Completed').onSelected!(true);
      await tester.pump();

      await tester.ensureVisible(find.text('Reanudar primera visible'));
      await tester.tap(find.text('Reanudar primera visible'));
      await tester.pump();

      expect(resumedSessionId, 's-2');
    },
  );

  testWidgets('descartar visibles usa los ids del subconjunto filtrado actual', (
    tester,
  ) async {
    List<String>? discardedIds;
    await tester.pumpWidget(
      buildActiveSessionsWidget(
        buildActiveSessionsFixture(),
        onDiscardManyRequested: (ids) => discardedIds = ids,
      ),
    );

    findScannerField(tester).onChanged!('Canon');
    await tester.pump();

    await tester.ensureVisible(find.text('Descartar visibles (2)'));
    await tester.tap(find.text('Descartar visibles (2)'));
    await tester.pump();

    expect(discardedIds, ['s-1', 's-3']);
  });

  testWidgets('descartar con atencion usa solo el subconjunto con seguimiento', (
    tester,
  ) async {
    List<String>? discardedIds;
    await tester.pumpWidget(
      buildActiveSessionsWidget(
        buildActiveSessionsFixture(),
        onDiscardManyRequested: (ids) => discardedIds = ids,
      ),
    );

    await tester.ensureVisible(find.text('Descartar con atencion (2)'));
    await tester.tap(find.text('Descartar con atencion (2)'));
    await tester.pump();

    expect(discardedIds, ['s-2', 's-3']);
  });

  testWidgets(
    'abrir primera con error muestra el detalle de la sesion visible en error',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      await tester.ensureVisible(find.text('Abrir primera con error (1)'));
      await tester.tap(find.text('Abrir primera con error (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Sesion: s-3'), findsOneWidget);
      expect(find.text('Paginas: 8'), findsOneWidget);
      expect(find.text('Fuente: ADF'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reanudar'), findsOneWidget);
    },
  );

  testWidgets(
    'descartar desde el detalle abierto por error dispara callback y cierra el dialogo',
    (tester) async {
      String? discardedSessionId;
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          onDiscardRequested: (sessionId) => discardedSessionId = sessionId,
        ),
      );

      await tester.ensureVisible(find.text('Abrir primera con error (1)'));
      await tester.tap(find.text('Abrir primera con error (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Descartar'));
      await tester.pumpAndSettle();

      expect(discardedSessionId, 's-3');
      expect(find.text('Sesion: s-3'), findsNothing);
    },
  );

  testWidgets(
    'acciones de detalle del panel quedan bloqueadas en modo busy',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(
          buildActiveSessionsFixture(),
          isBusy: true,
        ),
      );

      final openAttentionButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Abrir primera con atencion'),
      );
      final openErrorButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Abrir primera con error (1)'),
      );

      expect(openAttentionButton.onPressed, isNull);
      expect(openErrorButton.onPressed, isNull);

      expect(find.text('Sesion: s-3'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
