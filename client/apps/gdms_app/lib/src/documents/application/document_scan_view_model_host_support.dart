import 'document_scan_view_model.dart';
import 'document_scan_view_model_capabilities.dart';
import 'document_scan_view_model_preferences.dart';
import 'document_scan_view_model_support.dart';
import '../domain/windows_twain_service_status.dart';

final class DocumentScanViewModelHostSupport {
  static Future<void> loadScanners(
    DocumentScanViewModel vm, {
    required bool forceDiscover,
  }) => refreshHostSnapshot(
    vm,
    forceDiscover: forceDiscover,
    preserveMessage: false,
  );

  static Future<void> refreshHostSnapshot(
    DocumentScanViewModel vm, {
    required bool forceDiscover,
    required bool preserveMessage,
  }) async {
    try {
      await vm.run(() async {
        vm.setServiceAvailable(await vm.repository.isAvailable());
        if (!vm.serviceAvailable) {
          vm.setActiveSessions(const []);
          vm.setSelectedScanner(null);
          vm.setServiceStatus(null);
          vm.setSessionDetails(null);
          vm.setLastHostSyncAtUtc(DateTime.now().toUtc());
          if (!preserveMessage) {
            vm.setMessage(
              'El servicio windows-twain no responde en ${vm.serviceBaseUrl}.',
            );
          }
          return;
        }
        vm.setServiceStatus(await vm.repository.getStatus());
        vm.setActiveSessions(await vm.repository.listSessions());
        vm.setLastHostSyncAtUtc(DateTime.now().toUtc());
        vm.syncScanSourceWithCapabilities();
        vm.syncScanModeWithCapabilities();
        vm.setScanners(
          forceDiscover
              ? await vm.repository.discoverScanners()
              : await vm.repository.listScanners(),
        );
        vm.setSelectedScanner(
          DocumentScanViewModelPreferences.resolveSelectedScanner(
            vm,
            vm.scanners.toList(growable: false),
          ),
        );
        vm.setPreferredScannerName(vm.selectedScanner?.name);
        DocumentScanViewModelPreferences.persist(vm);
        if (!preserveMessage) {
          vm.setMessage(_loadMessage(vm));
        }
      });
    } catch (error) {
      if (!preserveMessage) {
        vm.setMessage(
          DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
        );
      }
    }
  }

  static Future<void> cleanupSessions(DocumentScanViewModel vm) async {
    try {
      await vm.run(() async {
        vm.setServiceStatus(await vm.repository.cleanupSessions());
        vm.setActiveSessions(await vm.repository.listSessions());
        vm.setLastHostSyncAtUtc(DateTime.now().toUtc());
        vm.setMessage(
          vm.serviceStatus!.lastCleanupDeletedCount > 0
              ? 'Se limpiaron ${vm.serviceStatus!.lastCleanupDeletedCount} carpeta(s) de sesiones huérfanas.'
              : 'No habia sesiones huérfanas para limpiar.',
        );
      });
    } catch (error) {
      vm.setMessage(
        DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
      );
    }
  }

  static Future<void> clearActiveSessions(DocumentScanViewModel vm) async {
    return _clearSessions(
      vm,
      clearAction: vm.repository.clearActiveSessions,
      successMessage: 'Se vaciaron las sesiones activas del host local.',
      clearAllState: true,
    );
  }

  static Future<void> clearStaleSessions(DocumentScanViewModel vm) async {
    return _clearSessions(
      vm,
      clearAction: vm.repository.clearStaleSessions,
      successMessage: 'Se vaciaron las sesiones inactivas del host local.',
    );
  }

  static Future<void> clearRehydratedSessions(DocumentScanViewModel vm) async {
    return _clearSessions(
      vm,
      clearAction: vm.repository.clearRehydratedSessions,
      successMessage: 'Se vaciaron las sesiones rehidratadas del host local.',
    );
  }

  static Future<void> _clearSessions(
    DocumentScanViewModel vm, {
    required Future<WindowsTwainServiceStatus> Function() clearAction,
    required String successMessage,
    bool clearAllState = false,
  }) async {
    try {
      await vm.run(() async {
        vm.setServiceStatus(await clearAction());
        vm.setActiveSessions(await vm.repository.listSessions());
        vm.setLastHostSyncAtUtc(DateTime.now().toUtc());
        final currentSessionId = vm.lastScannedFile?.sessionId;
        final currentStillExists =
            currentSessionId != null &&
            vm.activeSessions.any((session) => session.sessionId == currentSessionId);
        final knownStillExists =
            vm.lastKnownSessionId != null &&
            vm.activeSessions.any(
              (session) => session.sessionId == vm.lastKnownSessionId,
            );
        if (clearAllState || !currentStillExists) {
          vm.clearScannedState();
        }
        if (clearAllState || !knownStillExists) {
          vm.setLastKnownSessionId(null);
        }
        DocumentScanViewModelPreferences.persist(vm);
        vm.setMessage(successMessage);
      });
    } catch (error) {
      vm.setMessage(
        DocumentScanViewModelSupport.mapError(vm.serviceBaseUrl, error),
      );
    }
  }

  static String _loadMessage(DocumentScanViewModel vm) {
    if (vm.scanners.isEmpty) {
      return 'No se detectaron escaneres TWAIN disponibles.';
    }
    if (!vm.canUseAdf && vm.canScanFlatbed) {
      return 'Selecciona el escaner y dispara el escaneo desde cama plana.';
    }
    if (!vm.canScanDuplex && vm.canScanSimplex && vm.duplex == false) {
      return 'El host actual no publica duplex. Se uso simplex.';
    }
    return 'Selecciona el escaner y dispara el escaneo.';
  }
}
