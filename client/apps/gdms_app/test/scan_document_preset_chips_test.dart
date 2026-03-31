import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preset.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_preset_chips.dart';

void main() {
  Widget buildWidget({
    List<DocumentScanPreset> presets = DocumentScanPreset.values,
    String? selectedPresetId,
    DocumentScanPreset? selectedPreset,
    bool duplex = true,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    bool isBusy = false,
    bool Function(DocumentScanPreset preset)? canApplyPreset,
    String? Function(DocumentScanPreset preset)? unavailableReason,
    ValueChanged<DocumentScanPreset>? onPresetSelected,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentPresetChips(
          presets: presets,
          selectedPresetId: selectedPresetId,
          selectedPreset: selectedPreset,
          duplex: duplex,
          dpi: dpi,
          pixelType: pixelType,
          discardBlankPages: discardBlankPages,
          isBusy: isBusy,
          canApplyPreset: canApplyPreset ?? (_) => true,
          unavailableReason: unavailableReason ?? (_) => null,
          onPresetSelected: onPresetSelected ?? (_) {},
        ),
      ),
    );
  }

  ChoiceChip findChoiceChip(WidgetTester tester, String label) {
    return tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .firstWhere((chip) => (chip.label as Text).data == label);
  }

  testWidgets('renderiza chips y descripcion del preset seleccionado', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        selectedPresetId: DocumentScanPreset.contractsGray.id,
        selectedPreset: DocumentScanPreset.contractsGray,
      ),
    );

    expect(find.text('Archivo color'), findsOneWidget);
    expect(find.text('Contratos'), findsOneWidget);
    expect(find.text('B/N rapido'), findsOneWidget);
    expect(findChoiceChip(tester, 'Contratos').selected, isTrue);
    expect(
      find.text(
        'Duplex gris 300 dpi conservando todas las paginas.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Perfil personalizado:'), findsNothing);
    expect(find.text('Usar sugerido'), findsNothing);
  });

  testWidgets('muestra perfil personalizado y preset sugerido cuando no hay uno activo', (
    tester,
  ) async {
    DocumentScanPreset? selected;

    await tester.pumpWidget(
      buildWidget(
        selectedPresetId: null,
        selectedPreset: null,
        duplex: false,
        dpi: 200,
        pixelType: 'bw',
        discardBlankPages: 'off',
        onPresetSelected: (preset) => selected = preset,
      ),
    );

    expect(
      find.text(
        'Perfil personalizado: simplex · 200 dpi · B/N · conserva blancas',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Sugerido para este host: Archivo color.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Usar sugerido'));
    await tester.pump();

    expect(selected, DocumentScanPreset.libraryColor);
  });

  testWidgets('renderiza razones de presets no disponibles', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        selectedPresetId: null,
        selectedPreset: null,
        canApplyPreset: (preset) => preset.id != DocumentScanPreset.libraryColor.id,
        unavailableReason: (preset) {
          if (preset.id == DocumentScanPreset.libraryColor.id) {
            return 'requiere duplex';
          }
          return null;
        },
      ),
    );

    expect(find.text('Archivo color: requiere duplex'), findsOneWidget);
  });

  testWidgets('deshabilita chips no aplicables y tambien en busy', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        isBusy: true,
        selectedPresetId: null,
        selectedPreset: null,
        canApplyPreset: (preset) => preset.id != DocumentScanPreset.quickBw.id,
      ),
    );

    final colorChip = findChoiceChip(tester, 'Archivo color');
    final quickBwChip = findChoiceChip(tester, 'B/N rapido');
    final suggestButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Usar sugerido'),
    );

    expect(colorChip.onSelected, isNull);
    expect(quickBwChip.onSelected, isNull);
    expect(suggestButton.onPressed, isNull);
  });

  testWidgets('dispara callback al tocar un chip aplicable', (tester) async {
    DocumentScanPreset? selected;

    await tester.pumpWidget(
      buildWidget(
        selectedPresetId: null,
        selectedPreset: null,
        canApplyPreset: (preset) => preset.id != DocumentScanPreset.quickBw.id,
        onPresetSelected: (preset) => selected = preset,
      ),
    );

    await tester.tap(find.text('Contratos'));
    await tester.pump();

    expect(selected, DocumentScanPreset.contractsGray);
  });
}
