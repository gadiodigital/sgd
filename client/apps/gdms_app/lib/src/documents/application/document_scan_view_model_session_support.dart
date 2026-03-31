import 'document_scan_view_model_preferences.dart';
import '../domain/active_scan_session.dart';
import '../domain/scan_session_details.dart';
import '../domain/scan_source.dart';
import '../domain/scanned_document_file.dart';
import 'document_scan_view_model.dart';
import 'document_scan_view_model_support.dart';

final class DocumentScanViewModelSessionSupport {
  static Future<void> refreshServiceStatus(DocumentScanViewModel vm) async {
    try {
      vm.setServiceStatus(await vm.repository.getStatus());
      vm.setActiveSessions(await vm.repository.listSessions());
      vm.setServiceAvailable(true);
      vm.syncScanSourceWithCapabilities();
      vm.syncScanModeWithCapabilities();
    } catch (_) {
      vm.setServiceAvailable(false);
      vm.setServiceStatus(null);
      vm.setActiveSessions(const []);
    }
  }

  static Future<void> refreshScannedPdf(DocumentScanViewModel vm) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) return;
    final refreshedBytes = await vm.repository.downloadPdf(
      scannedFile.sessionId,
    );
    vm.setLastScannedFile(scannedFile.copyWith(bytes: refreshedBytes));
  }

  static Future<void> refreshSession(DocumentScanViewModel vm) async {
    try {
      await vm.run(() async {
        final details = await syncSessionDetails(vm);
        await DocumentScanViewModelSupport.loadPreview(vm);
        if (details == null) {
          vm.setMessage('No hay una sesion de escaneo activa para refrescar.');
          return;
        }
        vm.setMessage(
          'Sesion ${details.sessionId} refrescada: ${details.pageCount} pagina(s), '
          'estado ${details.status.isEmpty ? 'sin dato' : details.status}.',
        );
      });
    } catch (error) {
      vm.setMessage(
        DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
      );
    }
  }

  static Future<void> discardSession(
    DocumentScanViewModel vm, {
    bool silent = false,
  }) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) return;

    try {
      await vm.repository.deleteSession(scannedFile.sessionId);
      await refreshServiceStatus(vm);
      vm.setLastKnownSessionId(null);
      DocumentScanViewModelPreferences.persist(vm);
      vm.clearScannedState();
      if (!silent) {
        vm.setMessage('Sesion local descartada.');
      }
    } catch (error) {
      if (!silent) {
        vm.setMessage(
          DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
        );
      }
    }
  }

  static Future<void> discardSessionById(
    DocumentScanViewModel vm,
    String sessionId, {
    bool silent = false,
  }) async {
    final trimmedSessionId = sessionId.trim();
    if (trimmedSessionId.isEmpty) return;

    try {
      await vm.repository.deleteSession(trimmedSessionId);
      await refreshServiceStatus(vm);
      if (vm.lastKnownSessionId == trimmedSessionId) {
        vm.setLastKnownSessionId(null);
      }
      if (vm.lastScannedFile?.sessionId == trimmedSessionId) {
        vm.clearScannedState();
      }
      DocumentScanViewModelPreferences.persist(vm);
      if (!silent) {
        vm.setMessage('Sesion $trimmedSessionId descartada del host local.');
      }
    } catch (error) {
      if (!silent) {
        vm.setMessage(
          DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
        );
      }
    }
  }

  static Future<void> discardSessionsByIds(
    DocumentScanViewModel vm,
    List<String> sessionIds, {
    required String successMessage,
  }) async {
    final normalizedSessionIds = sessionIds
        .map((sessionId) => sessionId.trim())
        .where((sessionId) => sessionId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedSessionIds.isEmpty) {
      return;
    }

    try {
      await vm.run(() async {
        for (final sessionId in normalizedSessionIds) {
          await vm.repository.deleteSession(sessionId);
          if (vm.lastKnownSessionId == sessionId) {
            vm.setLastKnownSessionId(null);
          }
          if (vm.lastScannedFile?.sessionId == sessionId) {
            vm.clearScannedState();
          }
        }
        await refreshServiceStatus(vm);
        DocumentScanViewModelPreferences.persist(vm);
        vm.setMessage(successMessage);
      });
    } catch (error) {
      vm.setMessage(
        DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
      );
    }
  }

  static Future<void> discardSessionsWhere(
    DocumentScanViewModel vm,
    bool Function(ActiveScanSession session) predicate, {
    required String successMessage,
  }) => discardSessionsByIds(
    vm,
    vm.activeSessions
        .where(predicate)
        .map((session) => session.sessionId)
        .toList(growable: false),
    successMessage: successMessage,
  );

  static Future<void> resumeLastSession(DocumentScanViewModel vm) async {
    final sessionId = vm.lastKnownSessionId?.trim();
    if (sessionId == null || sessionId.isEmpty) {
      vm.setMessage('No hay una sesion local reciente para reanudar.');
      return;
    }

    try {
      await vm.run(() async {
        final details = await vm.repository.getSession(sessionId);
        final pdfBytes = await vm.repository.downloadPdf(sessionId);
        vm.setSessionDetails(details);
        vm.setCurrentPreviewPage(1);
        vm.setLastScannedFile(
          ScannedDocumentFile(
            sessionId: details.sessionId,
            fileName: '${details.sessionId}.pdf',
            bytes: pdfBytes,
            pageCount: details.pageCount,
            scannerName: details.scannerName,
          ),
        );
        vm.setLastKnownSessionId(details.sessionId);
        _applySessionSettings(vm, details);
        for (final scanner in vm.scanners) {
          if (scanner.name == details.scannerName) {
            vm.setSelectedScanner(scanner);
            vm.setPreferredScannerName(scanner.name);
            break;
          }
        }
        await refreshServiceStatus(vm);
        await DocumentScanViewModelSupport.loadPreview(vm);
        DocumentScanViewModelPreferences.persist(vm);
        vm.setMessage(
          'Sesion ${details.sessionId} reanudada con ${details.pageCount} pagina(s).',
        );
      });
    } catch (_) {
      vm.setLastKnownSessionId(null);
      DocumentScanViewModelPreferences.persist(vm);
      vm.setMessage(
        'La ultima sesion local ya no esta disponible. Se limpio la referencia.',
      );
      await refreshServiceStatus(vm);
    }
  }

  static Future<void> resumeSessionById(
    DocumentScanViewModel vm,
    String sessionId,
  ) async {
    vm.setLastKnownSessionId(sessionId.trim());
    await resumeLastSession(vm);
  }

  static Future<ScanSessionDetails?> syncSessionDetails(
    DocumentScanViewModel vm,
  ) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) {
      vm.setSessionDetails(null);
      return null;
    }
    final details = await vm.repository.getSession(scannedFile.sessionId);
    vm.setSessionDetails(details);
    vm.setLastKnownSessionId(details.sessionId);
    vm.setLastScannedFile(
      scannedFile.copyWith(
        pageCount: details.pageCount,
        scannerName: details.scannerName.isEmpty
            ? scannedFile.scannerName
            : details.scannerName,
      ),
    );
    if (details.pageCount <= 0) {
      vm.clearScannedState();
      return details;
    }
    if (vm.currentPreviewPage > details.pageCount) {
      vm.setCurrentPreviewPage(details.pageCount);
    }
    if (vm.currentPreviewPage < 1) {
      vm.setCurrentPreviewPage(1);
    }
    DocumentScanViewModelPreferences.persist(vm);
    return details;
  }

  static void _applySessionSettings(
    DocumentScanViewModel vm,
    ScanSessionDetails details,
  ) {
    vm.setSource(details.isFlatbed ? ScanSource.flatbed : ScanSource.adf);
    if (details.isAdf) {
      vm.setDuplex(details.mode.toLowerCase().contains('duplex'));
    }
    if (details.dpi != null) {
      vm.setDpi(details.dpi!);
    }
    if (details.pixelType.isNotEmpty) {
      vm.setPixelType(details.pixelType);
    }
    if (details.discardBlankPages.isNotEmpty) {
      vm.setDiscardBlankPages(details.discardBlankPages);
    }
  }
}
