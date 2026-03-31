import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

ActiveScanSession buildActiveScanSession({
  required String sessionId,
  required String scannerName,
  required String mode,
  required String status,
  required int pageCount,
  required Duration touchedAgo,
  bool isRehydrated = false,
}) {
  final now = DateTime.now().toUtc();
  return ActiveScanSession(
    sessionId: sessionId,
    createdAtUtc: now.subtract(touchedAgo + const Duration(minutes: 5)),
    lastTouchedAtUtc: now.subtract(touchedAgo),
    scannerName: scannerName,
    mode: mode,
    status: status,
    pageCount: pageCount,
    isRehydrated: isRehydrated,
  );
}

Widget buildActiveSessionsWidget(
  List<ActiveScanSession> sessions, {
  bool isBusy = false,
  String? currentSessionId,
  ValueChanged<String>? onResumeRequested,
  ValueChanged<String>? onDiscardRequested,
  ValueChanged<List<String>>? onDiscardManyRequested,
  ValueChanged<List<ActiveScanSession>>? onExportVisibleRequested,
}) {
  return MaterialApp(
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: Scaffold(
      body: SingleChildScrollView(
        child: ScanDocumentActiveSessions(
          sessions: sessions,
          isBusy: isBusy,
          currentSessionId: currentSessionId,
          onResumeRequested: onResumeRequested ?? (_) {},
          onDiscardRequested: onDiscardRequested ?? (_) {},
          onDiscardManyRequested: onDiscardManyRequested ?? (_) {},
          onExportVisibleRequested: onExportVisibleRequested ?? (_) {},
        ),
      ),
    ),
  );
}

List<ActiveScanSession> buildActiveSessionsFixture() => [
      buildActiveScanSession(
        sessionId: 's-1',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 3,
        touchedAgo: const Duration(minutes: 5),
      ),
      buildActiveScanSession(
        sessionId: 's-2',
        scannerName: 'Epson',
        mode: 'flatbed-single',
        status: 'completed',
        pageCount: 1,
        touchedAgo: const Duration(hours: 2),
      ),
      buildActiveScanSession(
        sessionId: 's-3',
        scannerName: 'Canon',
        mode: 'adf-duplex',
        status: 'error',
        pageCount: 8,
        touchedAgo: const Duration(hours: 3),
      ),
    ];

ChoiceChip findChoiceChip(WidgetTester tester, String label) {
  return tester
      .widgetList<ChoiceChip>(find.byType(ChoiceChip))
      .firstWhere((chip) => (chip.label as Text).data == label);
}

InputChip findInputChip(WidgetTester tester, String label) {
  return tester
      .widgetList<InputChip>(find.byType(InputChip))
      .firstWhere((chip) => (chip.label as Text).data == label);
}

ActionChip findActionChip(WidgetTester tester, String label) {
  return tester
      .widgetList<ActionChip>(find.byType(ActionChip))
      .firstWhere((chip) => (chip.label as Text).data == label);
}

OutlinedButton findOutlinedButton(WidgetTester tester, String label) {
  return tester
      .widgetList<OutlinedButton>(find.byType(OutlinedButton))
      .firstWhere((button) => ((button.child as Text).data) == label);
}

DropdownButtonFormField<ScanDocumentSessionSort> findSortField(
  WidgetTester tester,
) {
  return tester.widgetList<DropdownButtonFormField<ScanDocumentSessionSort>>(
    find.byType(DropdownButtonFormField<ScanDocumentSessionSort>),
  ).single;
}

DropdownButtonFormField<String> findScannerField(WidgetTester tester) {
  return tester.widgetList<DropdownButtonFormField<String>>(
    find.byType(DropdownButtonFormField<String>),
  ).single;
}
