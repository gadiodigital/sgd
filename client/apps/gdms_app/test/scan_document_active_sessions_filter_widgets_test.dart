import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_activity_filters.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_page_volume_filters.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_status_filters.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

void main() {
  Widget buildStatusWidget({
    required ScanDocumentSessionStatusFilter selectedFilter,
    bool isBusy = false,
    ValueChanged<ScanDocumentSessionStatusFilter>? onFilterChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentActiveSessionsStatusFilters(
          selectedFilter: selectedFilter,
          isBusy: isBusy,
          onFilterChanged: onFilterChanged ?? (_) {},
        ),
      ),
    );
  }

  Widget buildPageVolumeWidget({
    required ScanDocumentSessionPageVolumeFilter selectedFilter,
    bool isBusy = false,
    ValueChanged<ScanDocumentSessionPageVolumeFilter>? onFilterChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentActiveSessionsPageVolumeFilters(
          selectedFilter: selectedFilter,
          isBusy: isBusy,
          onFilterChanged: onFilterChanged ?? (_) {},
        ),
      ),
    );
  }

  Widget buildActivityWidget({
    required ScanDocumentSessionActivityFilter selectedFilter,
    bool isBusy = false,
    ValueChanged<ScanDocumentSessionActivityFilter>? onFilterChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentActiveSessionsActivityFilters(
          selectedFilter: selectedFilter,
          isBusy: isBusy,
          onFilterChanged: onFilterChanged ?? (_) {},
        ),
      ),
    );
  }

  ChoiceChip findChoiceChip(WidgetTester tester, String label) {
    return tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .firstWhere((chip) => (chip.label as Text).data == label);
  }

  testWidgets('status filters renderizan labels y callback correcto', (
    tester,
  ) async {
    ScanDocumentSessionStatusFilter? selected;

    await tester.pumpWidget(
      buildStatusWidget(
        selectedFilter: ScanDocumentSessionStatusFilter.completed,
        onFilterChanged: (value) => selected = value,
      ),
    );

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(findChoiceChip(tester, 'Completed').selected, isTrue);

    await tester.tap(find.text('Error'));
    await tester.pump();

    expect(selected, ScanDocumentSessionStatusFilter.error);
  });

  testWidgets('status filters en busy deshabilitan todos los chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStatusWidget(
        selectedFilter: ScanDocumentSessionStatusFilter.all,
        isBusy: true,
      ),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.every((chip) => chip.onSelected == null), isTrue);
  });

  testWidgets('page volume filters renderizan labels y callback correcto', (
    tester,
  ) async {
    ScanDocumentSessionPageVolumeFilter? selected;

    await tester.pumpWidget(
      buildPageVolumeWidget(
        selectedFilter: ScanDocumentSessionPageVolumeFilter.smallBatch,
        onFilterChanged: (value) => selected = value,
      ),
    );

    expect(find.text('Todas las paginas'), findsOneWidget);
    expect(find.text('1 pagina'), findsOneWidget);
    expect(find.text('2 a 5 paginas'), findsOneWidget);
    expect(find.text('6+ paginas'), findsOneWidget);
    expect(findChoiceChip(tester, '2 a 5 paginas').selected, isTrue);

    await tester.tap(find.text('6+ paginas'));
    await tester.pump();

    expect(selected, ScanDocumentSessionPageVolumeFilter.largeBatch);
  });

  testWidgets('page volume filters en busy deshabilitan todos los chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPageVolumeWidget(
        selectedFilter: ScanDocumentSessionPageVolumeFilter.all,
        isBusy: true,
      ),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.every((chip) => chip.onSelected == null), isTrue);
  });

  testWidgets('activity filters renderizan labels y callback correcto', (
    tester,
  ) async {
    ScanDocumentSessionActivityFilter? selected;

    await tester.pumpWidget(
      buildActivityWidget(
        selectedFilter: ScanDocumentSessionActivityFilter.lastHour,
        onFilterChanged: (value) => selected = value,
      ),
    );

    expect(find.text('Toda actividad'), findsOneWidget);
    expect(find.text('Ultimos 15 min'), findsOneWidget);
    expect(find.text('Ultima hora'), findsOneWidget);
    expect(find.text('Mas de 1 hora'), findsOneWidget);
    expect(findChoiceChip(tester, 'Ultima hora').selected, isTrue);

    await tester.tap(find.text('Mas de 1 hora'));
    await tester.pump();

    expect(selected, ScanDocumentSessionActivityFilter.olderThanHour);
  });

  testWidgets('activity filters en busy deshabilitan todos los chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildActivityWidget(
        selectedFilter: ScanDocumentSessionActivityFilter.all,
        isBusy: true,
      ),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.every((chip) => chip.onSelected == null), isTrue);
  });
}
