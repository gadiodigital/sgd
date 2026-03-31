import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preset.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/domain/windows_twain_service_status.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_settings_section.dart';

void main() {
  Widget buildWidget({
    bool serviceAvailable = true,
    WindowsTwainServiceStatus? serviceStatus,
    String serviceBaseUrl = 'http://127.0.0.1:43127',
    bool isBusy = false,
    List<ActiveScanSession> activeSessions = const [],
    bool canScan = true,
    bool canResumeLastSession = false,
    String? currentSessionId,
    DateTime? lastHostSyncAtUtc,
    DateTime? nextHostRefreshAtUtc,
    DateTime? currentTimeUtc,
    ScanSource source = ScanSource.adf,
    bool canUseAdf = true,
    bool canScanFlatbed = true,
    bool canScanSimplex = true,
    bool canScanDuplex = true,
    List<ScannerDevice> scanners = const [],
    ScannerDevice? selectedScanner,
    List<DocumentScanPreset> presets = DocumentScanPreset.values,
    String? activePresetId,
    bool duplex = false,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    VoidCallback? onRefreshRequested,
    VoidCallback? onResetRequested,
    VoidCallback? onForgetScannerRequested,
    ValueChanged<DocumentScanPreset>? onPresetSelected,
    ValueChanged<ScanSource>? onSourceChanged,
    ValueChanged<ScannerDevice?>? onScannerChanged,
    ValueChanged<bool>? onDuplexChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScanDocumentSettingsSection(
            serviceAvailable: serviceAvailable,
            serviceStatus: serviceStatus,
            serviceBaseUrl: serviceBaseUrl,
            isBusy: isBusy,
            activeSessions: activeSessions,
            canScan: canScan,
            canResumeLastSession: canResumeLastSession,
            currentSessionId: currentSessionId,
            lastHostSyncAtUtc: lastHostSyncAtUtc,
            nextHostRefreshAtUtc: nextHostRefreshAtUtc,
            currentTimeUtc: currentTimeUtc ?? DateTime.now().toUtc(),
            source: source,
            canUseAdf: canUseAdf,
            canScanFlatbed: canScanFlatbed,
            canScanSimplex: canScanSimplex,
            canScanDuplex: canScanDuplex,
            scanners: scanners,
            selectedScanner: selectedScanner,
            presets: presets,
            activePresetId: activePresetId,
            duplex: duplex,
            dpi: dpi,
            pixelType: pixelType,
            discardBlankPages: discardBlankPages,
            onRefreshRequested: onRefreshRequested ?? () {},
            onCleanupRequested: () {},
            onClearActiveSessionsRequested: () {},
            onClearFinishedSessionsRequested: () {},
            onClearAdfSessionsRequested: () {},
            onClearFlatbedSessionsRequested: () {},
            onClearStaleSessionsRequested: () {},
            onClearRehydratedSessionsRequested: () {},
            onResumeLastSessionRequested: () {},
            onResumeSessionRequested: (_) {},
            onDiscardSessionRequested: (_) {},
            onDiscardSessionsRequested: (_) {},
            onExportSessionsRequested: (_) {},
            onResetRequested: onResetRequested ?? () {},
            onForgetScannerRequested: onForgetScannerRequested ?? () {},
            onPresetSelected: onPresetSelected ?? (_) {},
            onSourceChanged: onSourceChanged ?? (_) {},
            onScannerChanged: onScannerChanged ?? (_) {},
            onDuplexChanged: onDuplexChanged ?? (_) {},
            onDpiChanged: (_) {},
            onPixelTypeChanged: (_) {},
            onDiscardBlankPagesChanged: (_) {},
          ),
        ),
      ),
    );
  }

  ScannerDevice buildScanner({String name = 'fi-8170'}) {
    return ScannerDevice(
      id: 7,
      name: name,
      manufacturer: 'Fujitsu',
      productFamily: 'ScanSnap',
      twainVersion: '2.4',
      isOpen: false,
    );
  }

  WindowsTwainServiceStatus buildServiceStatus() {
    return const WindowsTwainServiceStatus(
      application: 'windows-twain',
      version: '1.0.0',
      baseUrl: 'http://127.0.0.1:43127',
      runMode: 'service',
      startupLogPath: '',
      scannerSummary: '1 scanner ready',
      activeSessions: 0,
      sessionsRootPath: '',
      lastCleanupAtUtc: null,
      lastCleanupDeletedCount: 0,
      operations: ['scan-adf-simplex', 'scan-adf-duplex', 'scan-flatbed'],
    );
  }

  testWidgets('renderiza encabezado y dispara refresh del formulario', (
    tester,
  ) async {
    var refreshed = false;

    await tester.pumpWidget(
      buildWidget(
        serviceAvailable: true,
        serviceStatus: null,
        onRefreshRequested: () => refreshed = true,
      ),
    );

    expect(
      find.text('Servicio disponible en http://127.0.0.1:43127'),
      findsOneWidget,
    );
    expect(find.byTooltip('Redescubrir escaneres'), findsOneWidget);

    await tester.tap(find.byTooltip('Redescubrir escaneres'));
    await tester.pump();

    expect(refreshed, isTrue);
  });

  testWidgets('en ADF integra preset activo, resumen y quick fix a simplex', (
    tester,
  ) async {
    final scanner = buildScanner();
    bool? switchedToSimplex;

    await tester.pumpWidget(
      buildWidget(
        serviceStatus: buildServiceStatus(),
        source: ScanSource.adf,
        scanners: [scanner],
        selectedScanner: scanner,
        activePresetId: DocumentScanPreset.libraryColor.id,
        duplex: true,
        canScanDuplex: false,
        canScanSimplex: true,
        onDuplexChanged: (value) => switchedToSimplex = value,
      ),
    );

    expect(find.text('Archivo color'), findsOneWidget);
    expect(find.text('Configuracion efectiva'), findsOneWidget);
    expect(find.text('Checklist previa'), findsOneWidget);
    expect(find.text('Pasar a simplex'), findsOneWidget);

    await tester.ensureVisible(find.text('Pasar a simplex'));
    await tester.tap(find.text('Pasar a simplex'));
    await tester.pump();

    expect(switchedToSimplex, isFalse);
  });

  testWidgets('en flatbed muestra texto alternativo y quick fix para volver a ADF', (
    tester,
  ) async {
    ScanSource? changedSource;

    await tester.pumpWidget(
      buildWidget(
        serviceStatus: buildServiceStatus(),
        source: ScanSource.flatbed,
        scanners: const [],
        selectedScanner: null,
        canUseAdf: true,
        canScanFlatbed: false,
        onSourceChanged: (value) => changedSource = value,
      ),
    );

    expect(
      find.text('Los presets operativos aplican solo a escaneos ADF.'),
      findsOneWidget,
    );
    expect(find.text('Usar ADF'), findsOneWidget);

    await tester.ensureVisible(find.text('Usar ADF'));
    await tester.tap(find.text('Usar ADF'));
    await tester.pump();

    expect(changedSource, ScanSource.adf);
  });
}
