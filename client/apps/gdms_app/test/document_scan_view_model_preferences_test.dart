import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_preferences.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
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

  test('restore aplica preferencias persistidas al view model', () {
    DocumentScanPreferences.save(
      const DocumentScanPreferences(
        scannerName: 'Canon DR',
        lastSessionId: 's-5',
        source: ScanSource.flatbed,
        duplex: false,
        dpi: 200,
        pixelType: 'gray',
        discardBlankPages: 'off',
      ),
    );

    final vm = buildViewModel();

    expect(vm.preferredScannerName, 'Canon DR');
    expect(vm.lastKnownSessionId, 's-5');
    expect(vm.source, ScanSource.flatbed);
    expect(vm.duplex, isFalse);
    expect(vm.dpi, 200);
    expect(vm.pixelType, 'gray');
    expect(vm.discardBlankPages, 'off');
  });

  test('persist guarda scanner source y sessionId actuales', () {
    final vm = buildViewModel();
    vm.setSelectedScanner(buildScanner('Fujitsu fi-8170'));
    vm.setLastKnownSessionId('s-8');
    vm.setSource(ScanSource.flatbed, persist: false);
    vm.setDuplex(false, persist: false);
    vm.setDpi(150, persist: false);
    vm.setPixelType('bw', persist: false);
    vm.setDiscardBlankPages('off', persist: false);

    DocumentScanViewModelPreferences.persist(vm);

    final saved = DocumentScanPreferences.current;
    expect(saved.scannerName, 'Fujitsu fi-8170');
    expect(saved.lastSessionId, 's-8');
    expect(saved.source, ScanSource.flatbed);
    expect(saved.duplex, isFalse);
    expect(saved.dpi, 150);
    expect(saved.pixelType, 'bw');
    expect(saved.discardBlankPages, 'off');
  });

  test('resolveSelectedScanner prioriza preferred luego current y luego primero', () {
    final vm = buildViewModel();
    final first = buildScanner('Canon');
    final second = buildScanner('Fujitsu');
    final scanners = [first, second];

    vm.setPreferredScannerName('Fujitsu');
    expect(
      DocumentScanViewModelPreferences.resolveSelectedScanner(vm, scanners)?.name,
      'Fujitsu',
    );

    vm.setPreferredScannerName(null);
    vm.setSelectedScanner(second);
    expect(
      DocumentScanViewModelPreferences.resolveSelectedScanner(vm, scanners)?.name,
      'Fujitsu',
    );

    vm.setSelectedScanner(null);
    expect(
      DocumentScanViewModelPreferences.resolveSelectedScanner(vm, scanners)?.name,
      'Canon',
    );
  });

  test('reset vuelve a defaults persistidos', () {
    final vm = buildViewModel();
    vm.setSelectedScanner(buildScanner('Canon'));
    vm.setLastKnownSessionId('s-1');
    vm.setSource(ScanSource.flatbed, persist: false);
    vm.setDuplex(false, persist: false);

    DocumentScanViewModelPreferences.reset(vm);

    expect(DocumentScanPreferences.current.source, ScanSource.adf);
    expect(DocumentScanPreferences.current.duplex, isTrue);
    expect(vm.source, ScanSource.adf);
    expect(vm.duplex, isTrue);
  });
}
