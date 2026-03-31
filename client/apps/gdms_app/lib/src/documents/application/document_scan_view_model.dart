import 'dart:collection';

import 'package:core/core.dart';

import '../../infrastructure/repositories/windows_twain_scan_repository.dart';
import 'document_scan_preset.dart';
import 'document_scan_view_model_actions.dart';
import 'document_scan_view_model_capabilities.dart';
import 'document_scan_view_model_export.dart';
import 'document_scan_view_model_host_support.dart';
import 'document_scan_view_model_preferences.dart';
import 'document_scan_view_model_scan.dart';
import 'document_scan_view_model_session_support.dart';
import 'document_scan_view_model_support.dart';
import '../domain/active_scan_session.dart';
import '../domain/scanned_document_file.dart';
import '../domain/scan_source.dart';
import '../domain/scan_session_details.dart';
import '../domain/scanner_device.dart';
import '../domain/windows_twain_service_status.dart';

final class DocumentScanViewModel extends ViewModel {
  DocumentScanViewModel(this._repository) {
    DocumentScanViewModelPreferences.restore(this);
  }

  final WindowsTwainScanRepository _repository;

  List<ScannerDevice> _scanners = const [];
  ScannerDevice? _selectedScanner;
  ScanSource _source = ScanSource.adf;
  bool _duplex = true;
  int _dpi = 300;
  String _pixelType = 'color';
  String _discardBlankPages = 'auto';
  bool _serviceAvailable = false;
  WindowsTwainServiceStatus? _serviceStatus;
  ScanSessionDetails? _sessionDetails;
  List<ActiveScanSession> _activeSessions = const [];
  ScannedDocumentFile? _lastScannedFile;
  List<int>? _previewBytes;
  int _currentPreviewPage = 1;
  String? _preferredScannerName;
  String? _lastKnownSessionId;
  DateTime? _lastHostSyncAtUtc;

  UnmodifiableListView<ScannerDevice> get scanners =>
      UnmodifiableListView(_scanners);
  ScannerDevice? get selectedScanner => _selectedScanner;
  ScanSource get source => _source;
  bool get duplex => _duplex;
  int get dpi => _dpi;
  String get pixelType => _pixelType;
  String get discardBlankPages => _discardBlankPages;
  bool get serviceAvailable => _serviceAvailable;
  WindowsTwainServiceStatus? get serviceStatus => _serviceStatus;
  ScanSessionDetails? get sessionDetails => _sessionDetails;
  UnmodifiableListView<ActiveScanSession> get activeSessions =>
      UnmodifiableListView(_activeSessions);
  String? get preferredScannerName => _preferredScannerName;
  String? get lastKnownSessionId => _lastKnownSessionId;
  DateTime? get lastHostSyncAtUtc => _lastHostSyncAtUtc;
  String get serviceBaseUrl => _repository.baseUrl;
  ScannedDocumentFile? get lastScannedFile => _lastScannedFile;
  List<int>? get previewBytes => _previewBytes;
  int get currentPreviewPage => _currentPreviewPage;
  List<DocumentScanPreset> get presets => DocumentScanPreset.values;
  String? get activePresetId =>
      DocumentScanViewModelActions.resolveActivePresetId(this);

  Future<void> loadScanners({bool forceDiscover = false}) =>
      DocumentScanViewModelHostSupport.loadScanners(
        this,
        forceDiscover: forceDiscover,
      );

  Future<void> refreshScanners() => loadScanners(forceDiscover: true);
  Future<void> refreshHostSnapshot({bool preserveMessage = true}) =>
      DocumentScanViewModelHostSupport.refreshHostSnapshot(
        this,
        forceDiscover: false,
        preserveMessage: preserveMessage,
      );
  Future<void> cleanupSessions() =>
      DocumentScanViewModelHostSupport.cleanupSessions(this);
  Future<void> clearActiveSessions() =>
      DocumentScanViewModelHostSupport.clearActiveSessions(this);
  Future<void> clearStaleSessions() =>
      DocumentScanViewModelHostSupport.clearStaleSessions(this);
  Future<void> clearRehydratedSessions() =>
      DocumentScanViewModelHostSupport.clearRehydratedSessions(this);

  void selectScanner(ScannerDevice? value) {
    _selectedScanner = value;
    _preferredScannerName = value?.name;
    DocumentScanViewModelPreferences.persist(this);
    notifyListeners();
  }

  void setSource(ScanSource value, {bool persist = true}) {
    if (value == ScanSource.flatbed && !canScanFlatbed) return;
    if (value == ScanSource.adf && !canUseAdf) return;
    _source = value;
    if (persist) {
      DocumentScanViewModelPreferences.persist(this);
    }
    notifyListeners();
  }

  void setDuplex(bool value, {bool persist = true}) {
    if (value && !canScanDuplex) return;
    if (!value && !canScanSimplex) return;
    _duplex = value;
    if (persist) {
      DocumentScanViewModelPreferences.persist(this);
    }
    notifyListeners();
  }

  void _syncScanModeWithCapabilities() {
    if (_duplex && !canScanDuplex && canScanSimplex) {
      _duplex = false;
      return;
    }
    if (!_duplex && !canScanSimplex && canScanDuplex) {
      _duplex = true;
    }
  }

  void _syncScanSourceWithCapabilities() {
    if (_source == ScanSource.flatbed && !canScanFlatbed && canUseAdf) {
      _source = ScanSource.adf;
      return;
    }
    if (_source == ScanSource.adf && !canUseAdf && canScanFlatbed) {
      _source = ScanSource.flatbed;
    }
  }

  void setDpi(int value, {bool persist = true}) {
    _dpi = value;
    if (persist) {
      DocumentScanViewModelPreferences.persist(this);
    }
    notifyListeners();
  }

  void setPixelType(String value, {bool persist = true}) {
    _pixelType = value;
    if (persist) {
      DocumentScanViewModelPreferences.persist(this);
    }
    notifyListeners();
  }

  void setDiscardBlankPages(String value, {bool persist = true}) {
    _discardBlankPages = value;
    if (persist) {
      DocumentScanViewModelPreferences.persist(this);
    }
    notifyListeners();
  }

  Future<ScannedDocumentFile?> scan() => DocumentScanViewModelScan.run(this);

  Future<void> showPreviousPage() async {
    if (!canShowPreviousPage) {
      return;
    }

    _currentPreviewPage -= 1;
    notifyListeners();
    await DocumentScanViewModelSupport.reloadPreview(this);
  }

  Future<void> showNextPage() async {
    if (!canShowNextPage) {
      return;
    }

    _currentPreviewPage += 1;
    notifyListeners();
    await DocumentScanViewModelSupport.reloadPreview(this);
  }

  Future<void> rotateCurrentPage() async {
    final scannedFile = _lastScannedFile;
    if (scannedFile == null) {
      return;
    }

    try {
      await run(() async {
        await _repository.rotatePage(
          scannedFile.sessionId,
          _currentPreviewPage,
        );
        await DocumentScanViewModelSessionSupport.refreshScannedPdf(this);
        await DocumentScanViewModelSupport.loadPreview(this);
        setMessage('Pagina $_currentPreviewPage rotada 90 grados.');
      });
    } catch (error) {
      setMessage(DocumentScanViewModelSupport.mapError(serviceBaseUrl, error));
    }
  }

  Future<void> deleteCurrentPage() =>
      DocumentScanViewModelSupport.deleteCurrentPage(this);
  Future<void> brightenCurrentPage() =>
      DocumentScanViewModelSupport.brightenCurrentPage(this);
  Future<void> darkenCurrentPage() =>
      DocumentScanViewModelSupport.darkenCurrentPage(this);
  Future<void> increaseContrastCurrentPage() =>
      DocumentScanViewModelSupport.increaseContrastCurrentPage(this);
  Future<void> decreaseContrastCurrentPage() =>
      DocumentScanViewModelSupport.decreaseContrastCurrentPage(this);
  Future<void> moveCurrentPageBackward() =>
      DocumentScanViewModelSupport.moveCurrentPageBackward(this);
  Future<void> moveCurrentPageForward() =>
      DocumentScanViewModelSupport.moveCurrentPageForward(this);
  Future<void> appendAnotherScan() =>
      DocumentScanViewModelSupport.appendAnotherScan(this);
  Future<void> insertAnotherScanAfterCurrentPage() =>
      DocumentScanViewModelSupport.insertAnotherScanAfterCurrentPage(this);
  Future<void> insertAnotherScanBeforeCurrentPage() =>
      DocumentScanViewModelSupport.insertAnotherScanBeforeCurrentPage(this);
  Future<void> refreshSession() =>
      DocumentScanViewModelSessionSupport.refreshSession(this);
  Future<void> discardSession({bool silent = false}) =>
      DocumentScanViewModelSessionSupport.discardSession(this, silent: silent);
  Future<void> discardSessionById(String sessionId, {bool silent = false}) =>
      DocumentScanViewModelSessionSupport.discardSessionById(
        this,
        sessionId,
        silent: silent,
      );
  Future<void> discardSessionsByIds(
    List<String> sessionIds, {
    required String successMessage,
  }) => DocumentScanViewModelSessionSupport.discardSessionsByIds(
    this,
    sessionIds,
    successMessage: successMessage,
  );
  Future<void> discardFinishedSessions() =>
      DocumentScanViewModelSessionSupport.discardSessionsWhere(
        this,
        (session) => session.isFinished,
        successMessage: 'Se descartaron las sesiones finalizadas del host local.',
      );
  Future<void> discardAdfSessions() =>
      DocumentScanViewModelSessionSupport.discardSessionsWhere(
        this,
        (session) => session.isAdf,
        successMessage: 'Se descartaron las sesiones ADF del host local.',
      );
  Future<void> discardFlatbedSessions() =>
      DocumentScanViewModelSessionSupport.discardSessionsWhere(
        this,
        (session) => session.isFlatbed,
        successMessage:
            'Se descartaron las sesiones de cama plana del host local.',
      );
  Future<void> resumeLastSession() =>
      DocumentScanViewModelSessionSupport.resumeLastSession(this);
  Future<void> resumeSessionById(String sessionId) =>
      DocumentScanViewModelSessionSupport.resumeSessionById(this, sessionId);
  Future<bool> exportPdf() => DocumentScanViewModelExport.exportPdf(this);
  void forgetPreferredScanner() =>
      DocumentScanViewModelActions.forgetPreferredScanner(this);
  void resetPreferences() =>
      DocumentScanViewModelActions.resetPreferences(this);
  void applyPreset(DocumentScanPreset preset) =>
      DocumentScanViewModelActions.applyPreset(this, preset);

  WindowsTwainScanRepository get repository => _repository;
  void setSelectedScanner(ScannerDevice? value) => _selectedScanner = value;
  void setScanners(List<ScannerDevice> value) => _scanners = value;
  void setLastScannedFile(ScannedDocumentFile? value) =>
      _lastScannedFile = value;
  void setSessionDetails(ScanSessionDetails? value) => _sessionDetails = value;
  void setServiceAvailable(bool value) => _serviceAvailable = value;
  void setServiceStatus(WindowsTwainServiceStatus? value) =>
      _serviceStatus = value;
  void setActiveSessions(List<ActiveScanSession> value) => _activeSessions = value;
  void setPreviewBytes(List<int>? value) => _previewBytes = value;
  void setCurrentPreviewPage(int value) => _currentPreviewPage = value;
  void setPreferredScannerName(String? value) => _preferredScannerName = value;
  void setLastKnownSessionId(String? value) => _lastKnownSessionId = value;
  void setLastHostSyncAtUtc(DateTime? value) => _lastHostSyncAtUtc = value;
  void syncScanSourceWithCapabilities() => _syncScanSourceWithCapabilities();
  void syncScanModeWithCapabilities() => _syncScanModeWithCapabilities();
  void refreshView() => notifyListeners();
  void clearScannedState() {
    _lastScannedFile = null;
    _sessionDetails = null;
    _previewBytes = null;
    _currentPreviewPage = 1;
  }
}
