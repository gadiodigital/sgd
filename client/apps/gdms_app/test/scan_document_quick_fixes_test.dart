import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_quick_fixes.dart';

void main() {
  Widget buildWidget({
    bool showRefresh = false,
    bool showSelectFirstScanner = false,
    bool showSwitchToSimplex = false,
    bool showSwitchToAdf = false,
    bool showSwitchToFlatbed = false,
    bool isBusy = false,
    VoidCallback? onRefreshRequested,
    VoidCallback? onSelectFirstScannerRequested,
    VoidCallback? onSwitchToSimplexRequested,
    VoidCallback? onSwitchToAdfRequested,
    VoidCallback? onSwitchToFlatbedRequested,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentQuickFixes(
          showRefresh: showRefresh,
          showSelectFirstScanner: showSelectFirstScanner,
          showSwitchToSimplex: showSwitchToSimplex,
          showSwitchToAdf: showSwitchToAdf,
          showSwitchToFlatbed: showSwitchToFlatbed,
          isBusy: isBusy,
          onRefreshRequested: onRefreshRequested ?? () {},
          onSelectFirstScannerRequested:
              onSelectFirstScannerRequested ?? () {},
          onSwitchToSimplexRequested: onSwitchToSimplexRequested ?? () {},
          onSwitchToAdfRequested: onSwitchToAdfRequested ?? () {},
          onSwitchToFlatbedRequested: onSwitchToFlatbedRequested ?? () {},
        ),
      ),
    );
  }

  testWidgets('no renderiza nada cuando no hay quick fixes', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('renderiza solo los quick fixes habilitados', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        showRefresh: true,
        showSwitchToSimplex: true,
        showSwitchToFlatbed: true,
      ),
    );

    expect(find.text('Redescubrir'), findsOneWidget);
    expect(find.text('Pasar a simplex'), findsOneWidget);
    expect(find.text('Usar flatbed'), findsOneWidget);
    expect(find.text('Usar primero'), findsNothing);
    expect(find.text('Usar ADF'), findsNothing);
  });

  testWidgets('dispara callbacks correctos para cada accion visible', (
    tester,
  ) async {
    var refreshed = false;
    var selectedFirst = false;
    var switchedSimplex = false;
    var switchedAdf = false;
    var switchedFlatbed = false;

    await tester.pumpWidget(
      buildWidget(
        showRefresh: true,
        showSelectFirstScanner: true,
        showSwitchToSimplex: true,
        showSwitchToAdf: true,
        showSwitchToFlatbed: true,
        onRefreshRequested: () => refreshed = true,
        onSelectFirstScannerRequested: () => selectedFirst = true,
        onSwitchToSimplexRequested: () => switchedSimplex = true,
        onSwitchToAdfRequested: () => switchedAdf = true,
        onSwitchToFlatbedRequested: () => switchedFlatbed = true,
      ),
    );

    await tester.tap(find.text('Redescubrir'));
    await tester.pump();
    await tester.tap(find.text('Usar primero'));
    await tester.pump();
    await tester.tap(find.text('Pasar a simplex'));
    await tester.pump();
    await tester.tap(find.text('Usar ADF'));
    await tester.pump();
    await tester.tap(find.text('Usar flatbed'));
    await tester.pump();

    expect(refreshed, isTrue);
    expect(selectedFirst, isTrue);
    expect(switchedSimplex, isTrue);
    expect(switchedAdf, isTrue);
    expect(switchedFlatbed, isTrue);
  });

  testWidgets('en busy deshabilita todos los quick fixes visibles', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        showRefresh: true,
        showSelectFirstScanner: true,
        showSwitchToSimplex: true,
        showSwitchToAdf: true,
        showSwitchToFlatbed: true,
        isBusy: true,
      ),
    );

    final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });
}
