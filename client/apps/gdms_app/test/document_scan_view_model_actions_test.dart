import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_preset.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_actions.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/domain/windows_twain_service_status.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';

void main() {
  setUp(() {
    DocumentScanPreferences.save(DocumentScanPreferences.defaults);
  });

  DocumentScanViewModel buildViewModel() {
    return DocumentScanViewModel(WindowsTwainScanRepository());
  }

  ScannerDevice buildScanner(String name) {
    return ScannerDevice(
      id: 1,
      name: name,
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

  test('forgetPreferredScanner cae al primer scanner disponible y persiste', () {
    final vm = buildViewModel();
    final first = buildScanner('Canon');
    final second = buildScanner('Fujitsu');
    vm.setScanners([first, second]);
    vm.setSelectedScanner(second);
    vm.setPreferredScannerName('Fujitsu');

    DocumentScanViewModelActions.forgetPreferredScanner(vm);

    expect(vm.selectedScanner?.name, 'Canon');
    expect(vm.preferredScannerName, 'Canon');
    expect(DocumentScanPreferences.current.scannerName, 'Canon');
  });

  test('resetPreferences sincroniza defaults con capacidades y deja mensaje', () {
    final vm = buildViewModel();
    vm.setScanners([buildScanner('Canon')]);
    vm.setSelectedScanner(buildScanner('Canon'));
    vm.setServiceStatus(buildStatus(const ['scan-adf-simplex']));
    vm.setSource(ScanSource.flatbed, persist: false);
    vm.setDuplex(true, persist: false);

    DocumentScanViewModelActions.resetPreferences(vm);

    expect(vm.source, ScanSource.adf);
    expect(vm.duplex, isFalse);
    expect(vm.selectedScanner?.name, 'Canon');
    expect(vm.message, 'Se restauro la configuracion recomendada del escaneo.');
  });

  test('applyPreset ajusta duplex segun capacidades y persiste mensaje', () {
    final vm = buildViewModel();
    vm.setServiceStatus(buildStatus(const ['scan-adf-simplex']));

    DocumentScanViewModelActions.applyPreset(vm, DocumentScanPreset.libraryColor);

    expect(vm.source.name, 'adf');
    expect(vm.duplex, isFalse);
    expect(vm.dpi, 300);
    expect(vm.pixelType, 'color');
    expect(vm.discardBlankPages, 'auto');
    expect(vm.message, 'Preset aplicado: Archivo color.');
    expect(DocumentScanPreferences.current.pixelType, 'color');
  });

  test('resolveActivePresetId detecta preset activo o null si es personalizado', () {
    final vm = buildViewModel();

    DocumentScanViewModelActions.applyPreset(vm, DocumentScanPreset.quickBw);
    expect(
      DocumentScanViewModelActions.resolveActivePresetId(vm),
      DocumentScanPreset.quickBw.id,
    );

    vm.setDpi(250, persist: false);
    expect(DocumentScanViewModelActions.resolveActivePresetId(vm), isNull);
  });
}
