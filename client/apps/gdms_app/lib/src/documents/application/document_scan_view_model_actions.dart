import 'document_scan_preset.dart';
import 'document_scan_view_model.dart';
import 'document_scan_view_model_capabilities.dart';
import 'document_scan_view_model_preferences.dart';
import '../domain/scan_source.dart';

final class DocumentScanViewModelActions {
  static void forgetPreferredScanner(DocumentScanViewModel vm) {
    vm.setSelectedScanner(vm.scanners.isEmpty ? null : vm.scanners.first);
    vm.setPreferredScannerName(vm.selectedScanner?.name);
    DocumentScanViewModelPreferences.persist(vm);
    vm.refreshView();
  }

  static void resetPreferences(DocumentScanViewModel vm) {
    DocumentScanViewModelPreferences.reset(vm);
    vm.syncScanSourceWithCapabilities();
    vm.syncScanModeWithCapabilities();
    vm.setSelectedScanner(
      DocumentScanViewModelPreferences.resolveSelectedScanner(
        vm,
        vm.scanners.toList(growable: false),
      ),
    );
    vm.setPreferredScannerName(vm.selectedScanner?.name);
    DocumentScanViewModelPreferences.persist(vm);
    vm.setMessage('Se restauro la configuracion recomendada del escaneo.');
    vm.refreshView();
  }

  static void applyPreset(DocumentScanViewModel vm, DocumentScanPreset preset) {
    vm.setSource(ScanSource.adf, persist: false);
    final duplex = preset.duplex && vm.canScanDuplex
        ? true
        : (vm.canScanSimplex ? false : preset.duplex);
    vm.setDuplex(duplex, persist: false);
    vm.setDpi(preset.dpi, persist: false);
    vm.setPixelType(preset.pixelType, persist: false);
    vm.setDiscardBlankPages(preset.discardBlankPages, persist: false);
    DocumentScanViewModelPreferences.persist(vm);
    vm.setMessage('Preset aplicado: ${preset.label}.');
    vm.refreshView();
  }

  static String? resolveActivePresetId(DocumentScanViewModel vm) {
    for (final preset in DocumentScanPreset.values) {
      if (preset.duplex == vm.duplex &&
          preset.dpi == vm.dpi &&
          preset.pixelType == vm.pixelType &&
          preset.discardBlankPages == vm.discardBlankPages) {
        return preset.id;
      }
    }
    return null;
  }
}
