import 'document_scan_preferences.dart';
import 'document_scan_view_model.dart';
import '../domain/scanner_device.dart';

final class DocumentScanViewModelPreferences {
  static void restore(DocumentScanViewModel vm) {
    final preferences = DocumentScanPreferences.current;
    vm.setPreferredScannerName(preferences.scannerName);
    vm.setLastKnownSessionId(preferences.lastSessionId);
    vm.setSource(preferences.source, persist: false);
    vm.setDuplex(preferences.duplex, persist: false);
    vm.setDpi(preferences.dpi, persist: false);
    vm.setPixelType(preferences.pixelType, persist: false);
    vm.setDiscardBlankPages(preferences.discardBlankPages, persist: false);
  }

  static void persist(DocumentScanViewModel vm) {
    DocumentScanPreferences.save(
      DocumentScanPreferences.current.copyWith(
        scannerName: vm.selectedScanner?.name,
        clearScannerName: vm.selectedScanner == null,
        lastSessionId: vm.lastKnownSessionId,
        clearLastSessionId: vm.lastKnownSessionId == null,
        source: vm.source,
        duplex: vm.duplex,
        dpi: vm.dpi,
        pixelType: vm.pixelType,
        discardBlankPages: vm.discardBlankPages,
      ),
    );
  }

  static void reset(DocumentScanViewModel vm) {
    DocumentScanPreferences.save(DocumentScanPreferences.defaults);
    restore(vm);
  }

  static ScannerDevice? resolveSelectedScanner(
    DocumentScanViewModel vm,
    List<ScannerDevice> scanners,
  ) {
    if (scanners.isEmpty) return null;
    final preferredName = vm.preferredScannerName?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      for (final scanner in scanners) {
        if (scanner.name == preferredName) {
          return scanner;
        }
      }
    }
    final current = vm.selectedScanner;
    if (current != null) {
      for (final scanner in scanners) {
        if (scanner.name == current.name) {
          return scanner;
        }
      }
    }
    return scanners.first;
  }
}
