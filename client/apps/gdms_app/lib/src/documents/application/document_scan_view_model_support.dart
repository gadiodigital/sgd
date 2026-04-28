import 'package:http/http.dart';

import '../../infrastructure/api/api_exception.dart';
import '../domain/scan_source.dart';
import 'document_scan_view_model.dart';
import 'document_scan_view_model_preferences.dart';
import 'document_scan_view_model_session_support.dart';

final class DocumentScanViewModelSupport {
  static Future<void> deleteCurrentPage(DocumentScanViewModel vm) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) return;
    try {
      await vm.run(() async {
        final snapshot = await vm.repository.deletePage(
          scannedFile.sessionId,
          vm.currentPreviewPage,
        );
        if (snapshot.isEmpty) {
          await vm.repository.deleteSession(scannedFile.sessionId);
          await DocumentScanViewModelSessionSupport.refreshServiceStatus(vm);
          vm.setLastKnownSessionId(null);
          vm.clearScannedState();
          DocumentScanViewModelPreferences.persist(vm);
          vm.setMessage('La sesion quedo vacia y se descarto del host local.');
          return;
        }
        if (vm.currentPreviewPage > snapshot.pageCount) {
          vm.setCurrentPreviewPage(snapshot.pageCount);
        }
        vm.setLastScannedFile(
          scannedFile.copyWith(pageCount: snapshot.pageCount),
        );
        await DocumentScanViewModelSessionSupport.syncSessionDetails(vm);
        await DocumentScanViewModelSessionSupport.refreshScannedPdf(vm);
        await loadPreview(vm);
        vm.setMessage(
          'Pagina eliminada. Quedan ${snapshot.pageCount} pagina(s).',
        );
      });
    } catch (error) {
      vm.setMessage(mapError(vm.serviceBaseUrl, error));
    }
  }

  static Future<void> brightenCurrentPage(DocumentScanViewModel vm) =>
      adjustCurrentPage(vm, brightness: 10);
  static Future<void> darkenCurrentPage(DocumentScanViewModel vm) =>
      adjustCurrentPage(vm, brightness: -10);
  static Future<void> increaseContrastCurrentPage(DocumentScanViewModel vm) =>
      adjustCurrentPage(vm, contrast: 10);
  static Future<void> decreaseContrastCurrentPage(DocumentScanViewModel vm) =>
      adjustCurrentPage(vm, contrast: -10);
  static Future<void> moveCurrentPageBackward(DocumentScanViewModel vm) =>
      moveCurrentPage(vm, -1);
  static Future<void> moveCurrentPageForward(DocumentScanViewModel vm) =>
      moveCurrentPage(vm, 1);
  static Future<void> appendAnotherScan(DocumentScanViewModel vm) async {
    await mergeAnotherScan(vm);
  }

  static Future<void> insertAnotherScanAfterCurrentPage(
    DocumentScanViewModel vm,
  ) async {
    await mergeAnotherScan(vm, insertAfterPageNumber: vm.currentPreviewPage);
  }

  static Future<void> insertAnotherScanBeforeCurrentPage(
    DocumentScanViewModel vm,
  ) async {
    await mergeAnotherScan(
      vm,
      insertAfterPageNumber: vm.currentPreviewPage - 1,
    );
  }

  static Future<void> mergeAnotherScan(
    DocumentScanViewModel vm, {
    int? insertAfterPageNumber,
  }) async {
    final currentScan = vm.lastScannedFile;
    final scanner = vm.selectedScanner;
    if (currentScan == null || scanner == null) return;
    try {
      await vm.run(() async {
        final appendedScan = await vm.repository.scan(
          source: vm.source,
          duplex: vm.duplex,
          scannerId: scanner.id,
          scannerName: scanner.name,
          dpi: vm.dpi,
          pixelType: vm.pixelType,
          discardBlankPages: vm.discardBlankPages,
        );
        final mergedSnapshot = await vm.repository.mergeSession(
          currentScan.sessionId,
          appendedScan.sessionId,
          insertAfterPageNumber: insertAfterPageNumber,
        );
        await DocumentScanViewModelSessionSupport.refreshServiceStatus(vm);
        vm.setLastScannedFile(
          currentScan.copyWith(pageCount: mergedSnapshot.pageCount),
        );
        await DocumentScanViewModelSessionSupport.syncSessionDetails(vm);
        vm.setCurrentPreviewPage(
          insertAfterPageNumber == null
              ? mergedSnapshot.pageCount
              : (insertAfterPageNumber == 0 ? 1 : insertAfterPageNumber + 1),
        );
        await DocumentScanViewModelSessionSupport.refreshScannedPdf(vm);
        await loadPreview(vm);
        vm.setMessage(
          _mergeMessage(
            sourceLabel: vm.source == ScanSource.flatbed ? 'cama plana' : 'ADF',
            insertedPageCount: appendedScan.pageCount,
            totalPageCount: mergedSnapshot.pageCount,
            insertAfterPageNumber: insertAfterPageNumber,
          ),
        );
      });
    } catch (error) {
      vm.setMessage(mapError(vm.serviceBaseUrl, error));
    }
  }

  static Future<void> reloadPreview(DocumentScanViewModel vm) async {
    try {
      await vm.run(() async {
        await loadPreview(vm);
        vm.setMessage('Mostrando pagina ${vm.currentPreviewPage} del escaneo.');
      });
    } catch (error) {
      vm.setMessage(mapError(vm.serviceBaseUrl, error));
    }
  }

  static Future<void> loadPreview(DocumentScanViewModel vm) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) {
      vm.setPreviewBytes(null);
      return;
    }
    try {
      vm.setPreviewBytes(
        await vm.repository.getPagePreview(
          scannedFile.sessionId,
          vm.currentPreviewPage,
        ),
      );
    } on ApiException {
      vm.setPreviewBytes(null);
    }
  }

  static Future<void> adjustCurrentPage(
    DocumentScanViewModel vm, {
    int brightness = 0,
    int contrast = 0,
  }) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) return;
    try {
      await vm.run(() async {
        await vm.repository.adjustPage(
          scannedFile.sessionId,
          vm.currentPreviewPage,
          brightness: brightness,
          contrast: contrast,
        );
        await DocumentScanViewModelSessionSupport.syncSessionDetails(vm);
        await DocumentScanViewModelSessionSupport.refreshScannedPdf(vm);
        await loadPreview(vm);
        vm.setMessage(
          'Pagina ${vm.currentPreviewPage} ajustada '
          '(brillo ${signed(brightness)}, contraste ${signed(contrast)}).',
        );
      });
    } catch (error) {
      vm.setMessage(mapError(vm.serviceBaseUrl, error));
    }
  }

  static Future<void> moveCurrentPage(
    DocumentScanViewModel vm,
    int offset,
  ) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) return;
    final targetPageNumber = vm.currentPreviewPage + offset;
    if (targetPageNumber < 1 || targetPageNumber > scannedFile.pageCount) {
      return;
    }
    try {
      await vm.run(() async {
        await vm.repository.movePage(
          scannedFile.sessionId,
          vm.currentPreviewPage,
          targetPageNumber: targetPageNumber,
        );
        await DocumentScanViewModelSessionSupport.syncSessionDetails(vm);
        vm.setCurrentPreviewPage(targetPageNumber);
        await DocumentScanViewModelSessionSupport.refreshScannedPdf(vm);
        await loadPreview(vm);
        vm.setMessage('Pagina reubicada a la posicion $targetPageNumber.');
      });
    } catch (error) {
      vm.setMessage(mapError(vm.serviceBaseUrl, error));
    }
  }

  static String signed(int value) => value > 0 ? '+$value' : '$value';

  static String _mergeMessage({
    required String sourceLabel,
    required int insertedPageCount,
    required int totalPageCount,
    required int? insertAfterPageNumber,
  }) {
    final insertedLabel = insertedPageCount == 1 ? 'pagina' : 'paginas';
    if (insertAfterPageNumber == null) {
      return 'Se agregaron $insertedPageCount $insertedLabel desde '
          '$sourceLabel. Total actual: $totalPageCount.';
    }
    if (insertAfterPageNumber == 0) {
      return 'Se insertaron $insertedPageCount $insertedLabel desde '
          '$sourceLabel antes de la pagina actual. '
          'Total actual: $totalPageCount.';
    }
    return 'Se insertaron $insertedPageCount $insertedLabel desde '
        '$sourceLabel despues de la pagina $insertAfterPageNumber. '
        'Total actual: $totalPageCount.';
  }

  static String mapError(String serviceBaseUrl, Object error) {
    if (error is ApiException) return error.message;
    if (error is ClientException) {
      return 'No se pudo conectar con windows-twain en $serviceBaseUrl.';
    }
    return 'No se pudo completar el escaneo con el servicio local.';
  }
}
