import '../domain/scanned_document_file.dart';
import '../domain/scan_source.dart';
import 'document_scan_view_model.dart';
import 'document_scan_view_model_preferences.dart';
import 'document_scan_view_model_session_support.dart';
import 'document_scan_view_model_support.dart';

final class DocumentScanViewModelScan {
  static Future<ScannedDocumentFile?> run(DocumentScanViewModel vm) async {
    final scanner = vm.selectedScanner;
    if (scanner == null) {
      vm.setMessage('Selecciona un escaner antes de iniciar el escaneo.');
      return null;
    }

    try {
      ScannedDocumentFile? scannedFile;
      await vm.run(() async {
        vm.clearScannedState();
        scannedFile = await vm.repository.scan(
          source: vm.source,
          duplex: vm.duplex,
          scannerId: scanner.id,
          scannerName: scanner.name,
          dpi: vm.dpi,
          pixelType: vm.pixelType,
          discardBlankPages: vm.discardBlankPages,
        );
        vm.setLastScannedFile(scannedFile);
        vm.setLastKnownSessionId(scannedFile!.sessionId);
        DocumentScanViewModelPreferences.persist(vm);
        await DocumentScanViewModelSessionSupport.refreshServiceStatus(vm);
        await DocumentScanViewModelSessionSupport.syncSessionDetails(vm);
        await DocumentScanViewModelSupport.loadPreview(vm);
        vm.setMessage(
          'Escaneo ${vm.source == ScanSource.flatbed ? 'flatbed' : 'ADF'} '
          'completado con ${scannedFile!.pageCount} pagina(s).',
        );
      });
      return scannedFile;
    } catch (error) {
      vm.setMessage(
        DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
      );
      return null;
    }
  }
}
