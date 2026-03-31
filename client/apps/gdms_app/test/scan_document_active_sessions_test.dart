import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

import 'scan_document_active_sessions_test_support.dart';

void main() {
  testWidgets(
    'quitar el chip del preset activo vuelve la bandeja a vista general',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);

      findChoiceChip(tester, 'ADF recientes (1)').onSelected!(true);
      await tester.pump();

      expect(find.text('Preset: ADF recientes'), findsNWidgets(2));
      expect(find.text('Mostrando 1 de 3 sesiones.'), findsOneWidget);

      findInputChip(tester, 'Preset: ADF recientes').onDeleted!.call();
      await tester.pump();

      expect(find.text('Preset: ADF recientes'), findsNothing);
      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
    },
  );

  testWidgets(
    'quitar un filtro individual desde el resumen no limpia el resto de la vista',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      await tester.enterText(find.byType(TextField), 'Canon');
      await tester.pump();

      findSortField(tester).onChanged!(ScanDocumentSessionSort.largest);
      await tester.pump();

      expect(find.text('Texto: Canon'), findsOneWidget);
      expect(findInputChip(tester, 'Mas paginas'), isNotNull);

      findInputChip(tester, 'Texto: Canon').onDeleted!.call();
      await tester.pump();

      expect(find.text('Texto: Canon'), findsNothing);
      expect(findInputChip(tester, 'Mas paginas'), isNotNull);
      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
    },
  );

  testWidgets(
    'usar el preset sugerido aplica la recomendacion y sincroniza la vista',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      expect(find.textContaining('Errores viejos (1)'), findsWidgets);
      expect(find.text('Usar sugerido'), findsOneWidget);

      await tester.tap(find.text('Usar sugerido'));
      await tester.pump();

      expect(find.text('Preset: Errores viejos'), findsNWidgets(2));
      expect(find.text('Mostrando 1 de 3 sesiones.'), findsOneWidget);
      expect(find.text('Usar sugerido'), findsNothing);
    },
  );

  testWidgets(
    'editar filtros manualmente despues de un preset deja la vista en modo personalizado',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      await tester.tap(find.text('Usar sugerido'));
      await tester.pump();

      expect(find.text('Preset: Errores viejos'), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'Canon');
      await tester.pump();

      expect(find.text('Preset: Errores viejos'), findsNothing);
      expect(find.text('Vista personalizada'), findsOneWidget);
      expect(find.text('Combinacion manual de filtros'), findsOneWidget);
      expect(find.text('Texto: Canon'), findsOneWidget);
      expect(find.text('Usar sugerido'), findsOneWidget);
    },
  );

  testWidgets(
    'aplicar y quitar el filtro por scanner sincroniza contador y resumen',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      findScannerField(tester).onChanged!('Canon');
      await tester.pump();

      expect(find.text('Scanner: Canon'), findsOneWidget);
      expect(find.text('Mostrando 2 de 3 sesiones en Canon.'), findsOneWidget);

      findInputChip(tester, 'Scanner: Canon').onDeleted!.call();
      await tester.pump();

      expect(find.text('Scanner: Canon'), findsNothing);
      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
    },
  );

  testWidgets(
    'aplicar y quitar el filtro de actividad sincroniza contador y resumen',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      findChoiceChip(tester, 'Ultimos 15 min').onSelected!(true);
      await tester.pump();

      expect(find.text('Ultimos 15 min'), findsNWidgets(2));
      expect(find.text('Mostrando 1 de 3 sesiones.'), findsOneWidget);

      findInputChip(tester, 'Ultimos 15 min').onDeleted!.call();
      await tester.pump();

      expect(
        find.byWidgetPredicate((widget) {
          return widget is InputChip &&
              widget.label is Text &&
              (widget.label as Text).data == 'Ultimos 15 min';
        }),
        findsNothing,
      );
      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
    },
  );

  testWidgets(
    'aplicar y quitar el filtro de volumen sincroniza contador y resumen',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      findChoiceChip(tester, '6+ paginas').onSelected!(true);
      await tester.pump();

      expect(find.text('6+ paginas'), findsNWidgets(2));
      expect(find.text('Mostrando 1 de 3 sesiones.'), findsOneWidget);

      findInputChip(tester, '6+ paginas').onDeleted!.call();
      await tester.pump();

      expect(
        find.byWidgetPredicate((widget) {
          return widget is InputChip &&
              widget.label is Text &&
              (widget.label as Text).data == '6+ paginas';
        }),
        findsNothing,
      );
      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
    },
  );

  testWidgets(
    'aplicar y quitar el filtro de estado sincroniza contador y resumen',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      findChoiceChip(tester, 'Error').onSelected!(true);
      await tester.pump();

      expect(findInputChip(tester, 'Error'), isNotNull);
      expect(find.text('Mostrando 1 de 3 sesiones.'), findsOneWidget);

      findInputChip(tester, 'Error').onDeleted!.call();
      await tester.pump();

      expect(
        find.byWidgetPredicate((widget) {
          return widget is InputChip &&
              widget.label is Text &&
              (widget.label as Text).data == 'Error';
        }),
        findsNothing,
      );
      expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
    },
  );

  testWidgets(
    'estado busy deshabilita acciones, limpieza y aplicacion de presets',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture(), isBusy: true),
      );

      expect(find.text('Usar sugerido'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        findChoiceChip(tester, 'ADF recientes (1)').onSelected,
        isNull,
      );
      expect(
        findOutlinedButton(tester, 'Copiar IDs visibles').onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), 'Canon');
      await tester.pump();

      expect(find.text('Texto: Canon'), findsNothing);
    },
  );

  testWidgets('limpiar todo restablece la vista general completa', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildActiveSessionsWidget(buildActiveSessionsFixture()),
    );

    await tester.enterText(find.byType(TextField), 'Canon');
    await tester.pump();
    findSortField(tester).onChanged!(ScanDocumentSessionSort.largest);
    await tester.pump();

    expect(find.text('Texto: Canon'), findsOneWidget);
    expect(find.text('Limpiar todo'), findsOneWidget);

    findActionChip(tester, 'Limpiar todo').onPressed!.call();
    await tester.pump();

    expect(find.text('Texto: Canon'), findsNothing);
    expect(find.text('Limpiar todo'), findsNothing);
    expect(find.text('Mostrando 3 de 3 sesiones.'), findsOneWidget);
  });

  testWidgets(
    'quitar el chip de orden restablece solo el orden activo',
    (tester) async {
      await tester.pumpWidget(
        buildActiveSessionsWidget(buildActiveSessionsFixture()),
      );

      await tester.enterText(find.byType(TextField), 'Canon');
      await tester.pump();
      findSortField(tester).onChanged!(ScanDocumentSessionSort.largest);
      await tester.pump();

      expect(find.text('Texto: Canon'), findsOneWidget);
      expect(findInputChip(tester, 'Mas paginas'), isNotNull);

      findInputChip(tester, 'Mas paginas').onDeleted!.call();
      await tester.pump();

      expect(find.text('Texto: Canon'), findsOneWidget);
      expect(find.byWidgetPredicate((widget) {
        return widget is InputChip &&
            widget.label is Text &&
            (widget.label as Text).data == 'Mas paginas';
      }), findsNothing);
    },
  );
}
