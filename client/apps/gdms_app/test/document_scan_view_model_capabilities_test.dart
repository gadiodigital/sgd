import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_capabilities.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/domain/windows_twain_service_status.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';

void main() {
  DocumentScanViewModel buildViewModel() {
    return DocumentScanViewModel(WindowsTwainScanRepository());
  }

  ScannerDevice buildScanner() {
    return const ScannerDevice(
      id: 1,
      name: 'Canon DR',
      manufacturer: 'Canon',
      productFamily: 'DR',
      twainVersion: '2.4',
      isOpen: false,
    );
  }

  WindowsTwainServiceStatus buildStatus(List<String> operations) {
    return WindowsTwainServiceStatus(
      application: 'windows-twain',
      version: '1.0.0',
      baseUrl: 'http://127.0.0.1:43127',
      runMode: 'service',
      startupLogPath: '',
      scannerSummary: '',
      activeSessions: 0,
      sessionsRootPath: '',
      lastCleanupAtUtc: null,
      lastCleanupDeletedCount: 0,
      operations: operations,
    );
  }

  test('supportsOperation acepta todo cuando no hay status u operaciones', () {
    final vm = buildViewModel();

    expect(vm.supportsOperation('scan-adf-duplex'), isTrue);

    vm.setServiceStatus(buildStatus(const []));
    expect(vm.supportsOperation('scan-adf-duplex'), isTrue);
  });

  test('canScan depende de servicio scanner source y capacidades publicadas', () {
    final vm = buildViewModel();
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setServiceStatus(
      buildStatus(const ['scan-adf-simplex', 'scan-flatbed-single']),
    );

    vm.setSource(ScanSource.adf, persist: false);
    vm.setDuplex(false, persist: false);
    expect(vm.canScan, isTrue);

    vm.setDuplex(true, persist: false);
    expect(vm.duplex, isFalse);
    expect(vm.canScan, isTrue);

    vm.setSource(ScanSource.flatbed, persist: false);
    expect(vm.canScan, isTrue);
  });

  test('flags de preview y merge responden al estado actual y operaciones', () {
    final vm = buildViewModel();
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setServiceStatus(
      buildStatus(const [
        'scan-adf-simplex',
        'rotate-page',
        'move-page',
        'delete-page',
        'adjust-page',
        'merge-session',
        'get-session',
      ]),
    );
    vm.setSource(ScanSource.adf, persist: false);
    vm.setDuplex(false, persist: false);
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [1, 2, 3],
        pageCount: 3,
        scannerName: 'Canon DR',
      ),
    );
    vm.setCurrentPreviewPage(2);

    expect(vm.canShowPreviousPage, isTrue);
    expect(vm.canShowNextPage, isTrue);
    expect(vm.canDeleteCurrentPage, isTrue);
    expect(vm.canMoveCurrentPageBackward, isTrue);
    expect(vm.canMoveCurrentPageForward, isTrue);
    expect(vm.canRotateCurrentPage, isTrue);
    expect(vm.canAdjustCurrentPage, isTrue);
    expect(vm.canMergeScans, isTrue);
    expect(vm.canRefreshSessionDetails, isTrue);
  });

  test('canResumeLastSession exige host disponible sin scan cargado e id conocido', () {
    final vm = buildViewModel();
    vm.setServiceAvailable(true);
    vm.setLastKnownSessionId('s-9');
    vm.setServiceStatus(buildStatus(const ['get-session']));

    expect(vm.canResumeLastSession, isTrue);

    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-9',
        fileName: 'scan.pdf',
        bytes: [1],
        pageCount: 1,
        scannerName: '',
      ),
    );
    expect(vm.canResumeLastSession, isFalse);
  });
}
