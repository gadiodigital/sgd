import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset_support.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_presets.dart';

void main() {
  Widget buildWidget({
    required List<ScanDocumentActiveSessionsPresetAvailability> availabilities,
    ScanDocumentActiveSessionsPresetRecommendation? recommendation,
    ScanDocumentActiveSessionsPreset? selectedPreset,
    bool isBusy = false,
    ValueChanged<ScanDocumentActiveSessionsPresetConfig>? onPresetSelected,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentActiveSessionsPresets(
          presetAvailabilities: availabilities,
          recommendedPreset: recommendation,
          selectedPreset: selectedPreset ?? ScanDocumentActiveSessionsPreset.attention,
          isBusy: isBusy,
          onPresetSelected: onPresetSelected ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renderiza labels con conteo y tooltip', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        availabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values.first,
            matchCount: 3,
          ),
        ],
      ),
    );

    expect(find.text('Atencion (3)'), findsOneWidget);
    expect(find.byType(Tooltip), findsOneWidget);
  });

  testWidgets('muestra preset sugerido con razon', (tester) async {
    final preset = ScanDocumentActiveSessionsPresetCatalog.values[1];
    await tester.pumpWidget(
      buildWidget(
        availabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: preset,
            matchCount: 2,
          ),
        ],
        recommendation: ScanDocumentActiveSessionsPresetRecommendation(
          availability: ScanDocumentActiveSessionsPresetAvailability(
            preset: preset,
            matchCount: 2,
          ),
          reason: 'Hay errores viejos acumulados y conviene resolverlos primero.',
        ),
      ),
    );

    expect(find.text('Sugerido'), findsOneWidget);
    expect(find.text('Errores viejos (2)'), findsOneWidget);
    expect(
      find.textContaining(
        'Hay errores viejos acumulados y conviene resolverlos primero.',
      ),
      findsOneWidget,
    );
    expect(find.text('Usar sugerido'), findsOneWidget);
  });

  testWidgets('deshabilita presets sin coincidencias', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        availabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values.first,
            matchCount: 0,
          ),
        ],
      ),
    );

    final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
    expect(chip.onSelected, isNull);
    expect(find.text('Atencion (0)'), findsOneWidget);
  });

  testWidgets('oculta recomendacion cuando el preset sugerido ya esta activo', (
    tester,
  ) async {
    final preset = ScanDocumentActiveSessionsPresetCatalog.values[1];
    await tester.pumpWidget(
      buildWidget(
        availabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: preset,
            matchCount: 2,
          ),
        ],
        recommendation: ScanDocumentActiveSessionsPresetRecommendation(
          availability: ScanDocumentActiveSessionsPresetAvailability(
            preset: preset,
            matchCount: 2,
          ),
          reason: 'Hay errores viejos acumulados y conviene resolverlos primero.',
        ),
        selectedPreset: ScanDocumentActiveSessionsPreset.oldErrors,
      ),
    );

    expect(find.text('Sugerido'), findsNothing);
    expect(find.text('Usar sugerido'), findsNothing);
  });

  testWidgets('dispara callback al elegir un preset disponible o usar sugerido', (
    tester,
  ) async {
    final attention = ScanDocumentActiveSessionsPresetCatalog.values.first;
    final oldErrors = ScanDocumentActiveSessionsPresetCatalog.values[1];
    final selected = <ScanDocumentActiveSessionsPreset>[];

    await tester.pumpWidget(
      buildWidget(
        availabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: attention,
            matchCount: 3,
          ),
          ScanDocumentActiveSessionsPresetAvailability(
            preset: oldErrors,
            matchCount: 2,
          ),
        ],
        recommendation: ScanDocumentActiveSessionsPresetRecommendation(
          availability: ScanDocumentActiveSessionsPresetAvailability(
            preset: oldErrors,
            matchCount: 2,
          ),
          reason: 'Hay errores viejos acumulados y conviene resolverlos primero.',
        ),
        selectedPreset: ScanDocumentActiveSessionsPreset.attention,
        onPresetSelected: (preset) => selected.add(preset.id),
      ),
    );

    await tester.tap(find.text('Errores viejos (2)'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Usar sugerido'));
    await tester.pump();

    expect(
      selected,
      [
        ScanDocumentActiveSessionsPreset.oldErrors,
        ScanDocumentActiveSessionsPreset.oldErrors,
      ],
    );
  });

  testWidgets('en busy bloquea chips y boton usar sugerido', (tester) async {
    final attention = ScanDocumentActiveSessionsPresetCatalog.values.first;
    final oldErrors = ScanDocumentActiveSessionsPresetCatalog.values[1];

    await tester.pumpWidget(
      buildWidget(
        availabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: attention,
            matchCount: 3,
          ),
          ScanDocumentActiveSessionsPresetAvailability(
            preset: oldErrors,
            matchCount: 2,
          ),
        ],
        recommendation: ScanDocumentActiveSessionsPresetRecommendation(
          availability: ScanDocumentActiveSessionsPresetAvailability(
            preset: oldErrors,
            matchCount: 2,
          ),
          reason: 'Hay errores viejos acumulados y conviene resolverlos primero.',
        ),
        isBusy: true,
      ),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    final suggestButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Usar sugerido'),
    );

    expect(chips.every((chip) => chip.onSelected == null), isTrue);
    expect(suggestButton.onPressed, isNull);
  });
}
