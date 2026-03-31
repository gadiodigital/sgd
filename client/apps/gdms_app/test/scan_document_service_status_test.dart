import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/domain/windows_twain_service_status.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_service_status.dart';

void main() {
  Widget buildWidget({
    required WindowsTwainServiceStatus serviceStatus,
    List<ActiveScanSession> activeSessions = const [],
    bool canScan = true,
    bool canResumeLastSession = false,
    String? currentSessionId,
    DateTime? lastHostSyncAtUtc,
    DateTime? nextHostRefreshAtUtc,
    DateTime? currentTimeUtc,
    bool isBusy = false,
    VoidCallback? onCleanupRequested,
    VoidCallback? onClearActiveSessionsRequested,
    VoidCallback? onClearFinishedSessionsRequested,
    VoidCallback? onClearAdfSessionsRequested,
    VoidCallback? onClearFlatbedSessionsRequested,
    VoidCallback? onClearStaleSessionsRequested,
    VoidCallback? onClearRehydratedSessionsRequested,
    VoidCallback? onResumeLastSessionRequested,
    ValueChanged<String>? onResumeSessionRequested,
    ValueChanged<String>? onDiscardSessionRequested,
    ValueChanged<List<String>>? onDiscardSessionsRequested,
    ValueChanged<List<ActiveScanSession>>? onExportSessionsRequested,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScanDocumentServiceStatus(
            serviceStatus: serviceStatus,
            activeSessions: activeSessions,
            canScan: canScan,
            canResumeLastSession: canResumeLastSession,
            currentSessionId: currentSessionId,
            lastHostSyncAtUtc: lastHostSyncAtUtc,
            nextHostRefreshAtUtc: nextHostRefreshAtUtc,
            currentTimeUtc: currentTimeUtc ?? DateTime.now().toUtc(),
            isBusy: isBusy,
            onCleanupRequested: onCleanupRequested ?? () {},
            onClearActiveSessionsRequested:
                onClearActiveSessionsRequested ?? () {},
            onClearFinishedSessionsRequested:
                onClearFinishedSessionsRequested ?? () {},
            onClearAdfSessionsRequested: onClearAdfSessionsRequested ?? () {},
            onClearFlatbedSessionsRequested:
                onClearFlatbedSessionsRequested ?? () {},
            onClearStaleSessionsRequested:
                onClearStaleSessionsRequested ?? () {},
            onClearRehydratedSessionsRequested:
                onClearRehydratedSessionsRequested ?? () {},
            onResumeLastSessionRequested:
                onResumeLastSessionRequested ?? () {},
            onResumeSessionRequested: onResumeSessionRequested ?? (_) {},
            onDiscardSessionRequested: onDiscardSessionRequested ?? (_) {},
            onDiscardSessionsRequested: onDiscardSessionsRequested ?? (_) {},
            onExportSessionsRequested: onExportSessionsRequested ?? (_) {},
          ),
        ),
      ),
    );
  }

  WindowsTwainServiceStatus buildServiceStatus({
    String application = 'windows-twain',
    String version = '1.2.3',
    String runMode = 'service',
    String startupLogPath = r'C:\logs\startup.log',
    String scannerSummary = '2 scanners ready',
    int activeSessions = 3,
    String sessionsRootPath = r'C:\twain\sessions',
    DateTime? lastCleanupAtUtc,
    int lastCleanupDeletedCount = 4,
    List<String> operations = const [
      'scan-adf-duplex',
      'get-session',
      'delete-session',
    ],
  }) {
    return WindowsTwainServiceStatus(
      application: application,
      version: version,
      baseUrl: 'http://127.0.0.1:43127',
      runMode: runMode,
      startupLogPath: startupLogPath,
      scannerSummary: scannerSummary,
      activeSessions: activeSessions,
      sessionsRootPath: sessionsRootPath,
      lastCleanupAtUtc: lastCleanupAtUtc,
      lastCleanupDeletedCount: lastCleanupDeletedCount,
      operations: operations,
    );
  }

  ActiveScanSession buildSession({
    required String sessionId,
    required String mode,
    required String status,
    required Duration touchedAgo,
    bool isRehydrated = false,
  }) {
    final now = DateTime.now().toUtc();
    return ActiveScanSession(
      sessionId: sessionId,
      createdAtUtc: now.subtract(touchedAgo + const Duration(minutes: 5)),
      lastTouchedAtUtc: now.subtract(touchedAgo),
      scannerName: 'Canon',
      mode: mode,
      status: status,
      pageCount: 3,
      isRehydrated: isRehydrated,
    );
  }

  testWidgets('renderiza metadata del host y senales temporales', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    await tester.pumpWidget(
      buildWidget(
        serviceStatus: buildServiceStatus(
          lastCleanupAtUtc: now.subtract(const Duration(minutes: 10)),
        ),
        lastHostSyncAtUtc: now.subtract(const Duration(seconds: 10)),
        nextHostRefreshAtUtc: now.add(const Duration(seconds: 12)),
        currentTimeUtc: now,
      ),
    );

    expect(find.text('Host: windows-twain v1.2.3'), findsOneWidget);
    expect(
      find.text('Modo: service · Operaciones: 3 · Sesiones activas: 3'),
      findsOneWidget,
    );
    expect(find.text('Snapshot reciente'), findsOneWidget);
    expect(find.textContaining('Ultima sincronizacion:'), findsOneWidget);
    expect(find.text('Proximo refresh automatico: en 12s'), findsOneWidget);
    expect(find.text(r'Sesiones locales: C:\twain\sessions'), findsOneWidget);
    expect(find.textContaining('Ultima limpieza:'), findsOneWidget);
    expect(find.text('TWAIN: 2 scanners ready'), findsOneWidget);
    expect(find.text(r'Log de arranque: C:\logs\startup.log'), findsOneWidget);
    expect(find.text('scan-adf-duplex'), findsOneWidget);
    expect(find.text('get-session'), findsOneWidget);
    expect(find.text('delete-session'), findsOneWidget);
    expect(find.text('Limpiar sesiones (4)'), findsOneWidget);
  });

  testWidgets('renderiza acciones de mantenimiento y callbacks', (
    tester,
  ) async {
    var cleaned = false;
    var clearedActive = false;
    var clearedFinished = false;
    var clearedAdf = false;
    var clearedFlatbed = false;
    var clearedStale = false;
    var clearedRehydrated = false;
    var resumedLast = false;

    final sessions = [
      buildSession(
        sessionId: 's-1',
        mode: 'adf-simplex',
        status: 'running',
        touchedAgo: const Duration(minutes: 5),
      ),
      buildSession(
        sessionId: 's-2',
        mode: 'flatbed-single',
        status: 'completed',
        touchedAgo: const Duration(hours: 3),
        isRehydrated: true,
      ),
    ];

    await tester.pumpWidget(
      buildWidget(
        serviceStatus: buildServiceStatus(activeSessions: 2),
        activeSessions: sessions,
        canResumeLastSession: true,
        onCleanupRequested: () => cleaned = true,
        onClearActiveSessionsRequested: () => clearedActive = true,
        onClearFinishedSessionsRequested: () => clearedFinished = true,
        onClearAdfSessionsRequested: () => clearedAdf = true,
        onClearFlatbedSessionsRequested: () => clearedFlatbed = true,
        onClearStaleSessionsRequested: () => clearedStale = true,
        onClearRehydratedSessionsRequested: () => clearedRehydrated = true,
        onResumeLastSessionRequested: () => resumedLast = true,
      ),
    );

    expect(find.text('Rehidratadas: 1 · Inactivas: 1'), findsOneWidget);
    expect(find.text('Vaciar sesiones activas (2)'), findsOneWidget);
    expect(find.text('Vaciar finalizadas'), findsOneWidget);
    expect(find.text('Vaciar ADF'), findsOneWidget);
    expect(find.text('Vaciar cama plana'), findsOneWidget);
    expect(find.text('Vaciar inactivas'), findsOneWidget);
    expect(find.text('Vaciar rehidratadas'), findsOneWidget);
    expect(find.text('Reanudar ultima sesion'), findsOneWidget);

    await tester.tap(find.text('Limpiar sesiones (4)'));
    await tester.pump();
    await tester.tap(find.text('Vaciar sesiones activas (2)'));
    await tester.pump();
    await tester.tap(find.text('Vaciar finalizadas'));
    await tester.pump();
    await tester.tap(find.text('Vaciar ADF'));
    await tester.pump();
    await tester.tap(find.text('Vaciar cama plana'));
    await tester.pump();
    await tester.tap(find.text('Vaciar inactivas'));
    await tester.pump();
    await tester.tap(find.text('Vaciar rehidratadas'));
    await tester.pump();
    await tester.tap(find.text('Reanudar ultima sesion'));
    await tester.pump();

    expect(cleaned, isTrue);
    expect(clearedActive, isTrue);
    expect(clearedFinished, isTrue);
    expect(clearedAdf, isTrue);
    expect(clearedFlatbed, isTrue);
    expect(clearedStale, isTrue);
    expect(clearedRehydrated, isTrue);
    expect(resumedLast, isTrue);
  });

  testWidgets('en busy deshabilita todas las acciones del host', (
    tester,
  ) async {
    final sessions = [
      buildSession(
        sessionId: 's-1',
        mode: 'adf-simplex',
        status: 'completed',
        touchedAgo: const Duration(hours: 3),
        isRehydrated: true,
      ),
    ];

    await tester.pumpWidget(
      buildWidget(
        serviceStatus: buildServiceStatus(activeSessions: 1),
        activeSessions: sessions,
        canResumeLastSession: true,
        isBusy: true,
      ),
    );

    final hostButtons = <String>[
      'Limpiar sesiones (4)',
      'Vaciar sesiones activas (1)',
      'Vaciar finalizadas',
      'Vaciar ADF',
      'Vaciar inactivas',
      'Vaciar rehidratadas',
      'Reanudar ultima sesion',
    ];

    for (final label in hostButtons) {
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, label),
      );
      expect(button.onPressed, isNull, reason: 'El boton "$label" deberia quedar deshabilitado.');
    }
  });

  testWidgets('muestra advertencia cuando la configuracion no permite escanear', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        serviceStatus: buildServiceStatus(
          activeSessions: 0,
          startupLogPath: '',
          scannerSummary: '',
          sessionsRootPath: '',
          operations: const [],
          lastCleanupDeletedCount: 0,
        ),
        canScan: false,
      ),
    );

    expect(
      find.text(
        'La configuracion elegida no coincide con las operaciones publicadas por el servicio.',
      ),
      findsOneWidget,
    );
    expect(find.text('Limpiar sesiones'), findsOneWidget);
  });
}
