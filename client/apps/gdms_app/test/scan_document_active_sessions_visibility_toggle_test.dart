import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_visibility_toggle.dart';

Widget buildVisibilityToggleHarness(Widget child) {
  return MaterialApp(
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('no renderiza nada cuando hay 6 sesiones o menos', (tester) async {
    await tester.pumpWidget(
      buildVisibilityToggleHarness(
        const ScanDocumentActiveSessionsVisibilityToggle(
          totalCount: 6,
          isExpanded: false,
          onToggleRequested: _noop,
        ),
      ),
    );

    expect(find.textContaining('sesiones filtradas'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Ver todas'), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('renderiza estado colapsado con texto y accion ver todas', (
    tester,
  ) async {
    var toggled = false;

    await tester.pumpWidget(
      buildVisibilityToggleHarness(
        ScanDocumentActiveSessionsVisibilityToggle(
          totalCount: 9,
          isExpanded: false,
          onToggleRequested: () => toggled = true,
        ),
      ),
    );

    expect(find.text('Se muestran 6 de 9 sesiones filtradas.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Ver todas'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Ver todas'));
    await tester.pump();

    expect(toggled, isTrue);
  });

  testWidgets('renderiza estado expandido con texto y accion ver menos', (
    tester,
  ) async {
    var toggled = false;

    await tester.pumpWidget(
      buildVisibilityToggleHarness(
        ScanDocumentActiveSessionsVisibilityToggle(
          totalCount: 9,
          isExpanded: true,
          onToggleRequested: () => toggled = true,
        ),
      ),
    );

    expect(find.text('Se muestran 9 sesiones filtradas.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Ver menos'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Ver menos'));
    await tester.pump();

    expect(toggled, isTrue);
  });
}

void _noop() {}
