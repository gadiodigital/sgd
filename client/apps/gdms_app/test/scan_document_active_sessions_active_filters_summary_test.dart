import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_active_filters_summary.dart';

void main() {
  Widget buildWidget({
    required List<String> filters,
    String? activePresetLabel,
    String? activePresetDescription,
    ValueChanged<String>? onFilterRemoved,
    VoidCallback? onActivePresetRemoved,
    VoidCallback? onClearAll,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentActiveSessionsActiveFiltersSummary(
          filters: filters,
          activePresetLabel: activePresetLabel,
          activePresetDescription: activePresetDescription,
          onFilterRemoved: onFilterRemoved,
          onActivePresetRemoved: onActivePresetRemoved,
          onClearAll: onClearAll,
        ),
      ),
    );
  }

  testWidgets('no renderiza nada si no hay filtros activos', (tester) async {
    await tester.pumpWidget(buildWidget(filters: const []));

    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('renderiza chips removibles cuando recibe callback', (
    tester,
  ) async {
    String? removed;
    await tester.pumpWidget(
      buildWidget(
        filters: const ['Running', 'Scanner: Canon'],
        onFilterRemoved: (value) => removed = value,
      ),
    );

    expect(find.byType(InputChip), findsNWidgets(2));
    tester.widget<InputChip>(find.byType(InputChip).first).onDeleted!.call();
    await tester.pump();

    expect(removed, 'Running');
  });

  testWidgets('renderiza accion limpiar todo cuando recibe callback', (
    tester,
  ) async {
    var cleared = false;
    await tester.pumpWidget(
      buildWidget(
        filters: const ['Running'],
        onClearAll: () => cleared = true,
      ),
    );

    expect(find.text('Limpiar todo'), findsOneWidget);
    await tester.tap(find.text('Limpiar todo'));
    await tester.pump();

    expect(cleared, isTrue);
  });

  testWidgets('renderiza preset activo aunque no haya filtros manuales', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        filters: const [],
        activePresetLabel: 'ADF recientes',
      ),
    );

    expect(find.text('Preset: ADF recientes'), findsOneWidget);
  });

  testWidgets('permite quitar el preset activo desde su chip', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      buildWidget(
        filters: const [],
        activePresetLabel: 'ADF recientes',
        onActivePresetRemoved: () => removed = true,
      ),
    );

    tester.widget<InputChip>(find.byType(InputChip).first).onDeleted!.call();
    await tester.pump();

    expect(removed, isTrue);
  });

  testWidgets('muestra tooltip descriptivo para el preset activo', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        filters: const [],
        activePresetLabel: 'Atencion',
        activePresetDescription: 'Errores, rehidratadas o inactivas',
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: tester.getCenter(find.text('Preset: Atencion')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Preset: Atencion')));
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Preset activo: Errores, rehidratadas o inactivas'),
      findsOneWidget,
    );
  });
}
