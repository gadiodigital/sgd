import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_filters_panel.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset_support.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

void main() {
  Widget buildWidget({
    bool isBusy = false,
    String query = '',
    List<ScanDocumentActiveSessionsPresetAvailability> presetAvailabilities =
        const [],
    ScanDocumentActiveSessionsPresetRecommendation? recommendedPreset,
    ScanDocumentActiveSessionsPreset? selectedPreset,
    bool isCustomState = false,
    ScanDocumentSessionFilter filter = ScanDocumentSessionFilter.all,
    ScanDocumentSessionStatusFilter statusFilter =
        ScanDocumentSessionStatusFilter.all,
    ScanDocumentSessionPageVolumeFilter pageVolumeFilter =
        ScanDocumentSessionPageVolumeFilter.all,
    ScanDocumentSessionActivityFilter activityFilter =
        ScanDocumentSessionActivityFilter.all,
    List<String> scannerOptions = const [],
    String selectedScanner = '',
    ScanDocumentSessionSort sort = ScanDocumentSessionSort.recentActivity,
    ValueChanged<String>? onQueryChanged,
    VoidCallback? onResetRequested,
    ValueChanged<ScanDocumentActiveSessionsPresetConfig>? onPresetSelected,
    ValueChanged<ScanDocumentSessionFilter>? onFilterChanged,
    ValueChanged<ScanDocumentSessionStatusFilter>? onStatusFilterChanged,
    ValueChanged<ScanDocumentSessionPageVolumeFilter>?
    onPageVolumeFilterChanged,
    ValueChanged<ScanDocumentSessionActivityFilter>? onActivityFilterChanged,
    ValueChanged<String>? onScannerChanged,
    ValueChanged<ScanDocumentSessionSort>? onSortChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScanDocumentActiveSessionsFiltersPanel(
            isBusy: isBusy,
            query: query,
            onQueryChanged: onQueryChanged ?? (_) {},
            presetAvailabilities: presetAvailabilities,
            recommendedPreset: recommendedPreset,
            selectedPreset: selectedPreset,
            isCustomState: isCustomState,
            onResetRequested: onResetRequested ?? () {},
            onPresetSelected: onPresetSelected ?? (_) {},
            filter: filter,
            onFilterChanged: onFilterChanged ?? (_) {},
            statusFilter: statusFilter,
            onStatusFilterChanged: onStatusFilterChanged ?? (_) {},
            pageVolumeFilter: pageVolumeFilter,
            onPageVolumeFilterChanged: onPageVolumeFilterChanged ?? (_) {},
            activityFilter: activityFilter,
            onActivityFilterChanged: onActivityFilterChanged ?? (_) {},
            scannerOptions: scannerOptions,
            selectedScanner: selectedScanner,
            onScannerChanged: onScannerChanged ?? (_) {},
            sort: sort,
            onSortChanged: onSortChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  ChoiceChip findChoiceChip(WidgetTester tester, String label) {
    return tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .firstWhere((chip) => (chip.label as Text).data == label);
  }

  testWidgets('renderiza preset activo y permite volver a vista general', (
    tester,
  ) async {
    var resetRequested = false;

    await tester.pumpWidget(
      buildWidget(
        selectedPreset: ScanDocumentActiveSessionsPreset.oldErrors,
        presetAvailabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values[1],
            matchCount: 2,
          ),
        ],
        onResetRequested: () => resetRequested = true,
      ),
    );

    expect(find.text('Preset: Errores viejos'), findsOneWidget);
    expect(find.text('Sesiones con error de hace mas de 1 hora'), findsOneWidget);
    await tester.tap(find.text('Vista general'));
    await tester.pump();

    expect(resetRequested, isTrue);
  });

  testWidgets('renderiza vista personalizada y reinicio cuando hay query', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        query: 'canon',
        isCustomState: true,
      ),
    );

    expect(find.text('Vista personalizada'), findsOneWidget);
    expect(find.text('Combinacion manual de filtros'), findsOneWidget);
    expect(find.text('Vista general'), findsOneWidget);
  });

  testWidgets('dispara callbacks de busqueda y filtros manuales', (
    tester,
  ) async {
    String? queryValue;
    ScanDocumentSessionFilter? selectedFilter;
    ScanDocumentSessionStatusFilter? selectedStatus;
    ScanDocumentSessionPageVolumeFilter? selectedVolume;
    ScanDocumentSessionActivityFilter? selectedActivity;

    await tester.pumpWidget(
      buildWidget(
        onQueryChanged: (value) => queryValue = value,
        onFilterChanged: (value) => selectedFilter = value,
        onStatusFilterChanged: (value) => selectedStatus = value,
        onPageVolumeFilterChanged: (value) => selectedVolume = value,
        onActivityFilterChanged: (value) => selectedActivity = value,
      ),
    );

    await tester.enterText(find.byType(TextField), 'epson');
    await tester.pump();
    await tester.tap(find.text('Requieren atencion'));
    await tester.pump();
    await tester.tap(find.text('Completed'));
    await tester.pump();
    await tester.tap(find.text('6+ paginas'));
    await tester.pump();
    await tester.tap(find.text('Ultima hora'));
    await tester.pump();

    expect(queryValue, 'epson');
    expect(selectedFilter, ScanDocumentSessionFilter.attention);
    expect(selectedStatus, ScanDocumentSessionStatusFilter.completed);
    expect(selectedVolume, ScanDocumentSessionPageVolumeFilter.largeBatch);
    expect(selectedActivity, ScanDocumentSessionActivityFilter.lastHour);
  });

  testWidgets('dispara callbacks de preset y dropdowns', (tester) async {
    ScanDocumentActiveSessionsPreset? selectedPreset;
    String? selectedScanner;
    ScanDocumentSessionSort? selectedSort;

    await tester.pumpWidget(
      buildWidget(
        presetAvailabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values.first,
            matchCount: 3,
          ),
        ],
        scannerOptions: const ['Canon', 'Epson'],
        onPresetSelected: (value) => selectedPreset = value.id,
        onScannerChanged: (value) => selectedScanner = value,
        onSortChanged: (value) => selectedSort = value,
      ),
    );

    await tester.tap(find.text('Atencion (3)'));
    await tester.pump();

    final scannerField = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    ).first;
    scannerField.onChanged!.call('Canon');

    final sortField = tester.widgetList<
      DropdownButtonFormField<ScanDocumentSessionSort>
    >(find.byType(DropdownButtonFormField<ScanDocumentSessionSort>)).single;
    sortField.onChanged!.call(ScanDocumentSessionSort.largest);

    expect(selectedPreset, ScanDocumentActiveSessionsPreset.attention);
    expect(selectedScanner, 'Canon');
    expect(selectedSort, ScanDocumentSessionSort.largest);
  });

  testWidgets('en busy bloquea busqueda, reset, chips y dropdowns', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        isBusy: true,
        query: 'canon',
        isCustomState: true,
        presetAvailabilities: [
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values.first,
            matchCount: 3,
          ),
        ],
        scannerOptions: const ['Canon'],
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    final resetButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Vista general'),
    );
    final attentionChip = findChoiceChip(tester, 'Atencion (3)');
    final filterChip = findChoiceChip(tester, 'Requieren atencion');
    final statusChip = findChoiceChip(tester, 'Completed');
    final volumeChip = findChoiceChip(tester, '6+ paginas');
    final activityChip = findChoiceChip(tester, 'Ultima hora');
    final dropdowns = tester.widgetList<DropdownButtonFormField<dynamic>>(
      find.byType(DropdownButtonFormField<dynamic>),
    );

    expect(textField.enabled, isFalse);
    expect(resetButton.onPressed, isNull);
    expect(attentionChip.onSelected, isNull);
    expect(filterChip.onSelected, isNull);
    expect(statusChip.onSelected, isNull);
    expect(volumeChip.onSelected, isNull);
    expect(activityChip.onSelected, isNull);
    expect(dropdowns.every((field) => field.onChanged == null), isTrue);
  });
}
