import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../documents/domain/scanned_document_file.dart';
import '../../documents/domain/active_scan_session.dart';
import '../../documents/domain/scan_source.dart';
import '../../documents/domain/scan_session_details.dart';
import '../../documents/domain/scan_session_snapshot.dart';
import '../../documents/domain/scanner_device.dart';
import '../../documents/domain/windows_twain_service_status.dart';
import '../api/api_defaults.dart';
import '../api/api_exception.dart';
import 'windows_twain_scan_repository_sessions_support.dart';
import 'windows_twain_scan_repository_support.dart';

final class WindowsTwainScanRepository {
  WindowsTwainScanRepository({String? baseUrl, http.Client? httpClient})
    : _baseUrl = ApiDefaults.normalizeBaseUrl(baseUrl ?? defaultBaseUrl),
      _httpClient = httpClient ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'WINDOWS_TWAIN_BASE_URL',
    defaultValue: 'http://127.0.0.1:43127',
  );

  final String _baseUrl;
  final http.Client _httpClient;

  String get baseUrl => _baseUrl;

  Future<bool> isAvailable() async {
    final response = await _httpClient.get(_buildUri('/health'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    if (response.body.trim().isEmpty) {
      return true;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final status = (decoded['status'] as String? ?? '').trim().toLowerCase();
      return status.isEmpty || status == 'ok';
    }

    return true;
  }

  Future<List<ScannerDevice>> listScanners() async {
    final response = await _httpClient.get(_buildUri('/api/scanners'));
    return WindowsTwainScanRepositorySupport.parseScannersResponse(
      this,
      response,
    );
  }

  Future<List<ScannerDevice>> discoverScanners() async {
    final response = await _httpClient.post(
      _buildUri('/api/scanners/discover'),
      headers: const {'Accept': 'application/json'},
    );
    return WindowsTwainScanRepositorySupport.parseScannersResponse(
      this,
      response,
    );
  }

  Future<WindowsTwainServiceStatus> getStatus() async =>
      WindowsTwainServiceStatus.fromJson(
        _decodeObject(await _httpClient.get(_buildUri('/api/status'))),
      );

  Future<WindowsTwainServiceStatus> cleanupSessions() async =>
      WindowsTwainServiceStatus.fromJson(
        _decodeObject(
          await _httpClient.post(_buildUri('/api/sessions/cleanup')),
        ),
      );

  Future<WindowsTwainServiceStatus> clearActiveSessions() async =>
      WindowsTwainServiceStatus.fromJson(
        _decodeObject(await _httpClient.delete(_buildUri('/api/sessions'))),
      );
  Future<WindowsTwainServiceStatus> clearStaleSessions() async =>
      _deleteStatus('/api/sessions/stale');
  Future<WindowsTwainServiceStatus> clearRehydratedSessions() async =>
      _deleteStatus('/api/sessions/rehydrated');

  Future<List<ActiveScanSession>> listSessions() async {
    final response = await _httpClient.get(
      _buildUri('/api/sessions'),
      headers: const {'Accept': 'application/json'},
    );
    WindowsTwainScanRepositorySupport.ensureSuccess(this, response);
    return WindowsTwainScanRepositorySessionsSupport.parse(response);
  }

  Future<ScannedDocumentFile> scanAdf({
    required bool duplex,
    int? scannerId,
    String? scannerName,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    int timeoutSeconds = 90,
  }) => WindowsTwainScanRepositorySupport.scanSession(
    this,
    duplex ? '/api/scans/adf/duplex' : '/api/scans/adf/simplex',
    scannerId: scannerId,
    scannerName: scannerName,
    dpi: dpi,
    pixelType: pixelType,
    discardBlankPages: discardBlankPages,
    timeoutSeconds: timeoutSeconds,
  );

  Future<ScannedDocumentFile> scan({
    required ScanSource source,
    required bool duplex,
    int? scannerId,
    String? scannerName,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    int timeoutSeconds = 90,
  }) {
    return switch (source) {
      ScanSource.adf => scanAdf(
        duplex: duplex,
        scannerId: scannerId,
        scannerName: scannerName,
        dpi: dpi,
        pixelType: pixelType,
        discardBlankPages: discardBlankPages,
        timeoutSeconds: timeoutSeconds,
      ),
      ScanSource.flatbed => scanFlatbedSingle(
        scannerId: scannerId,
        scannerName: scannerName,
        dpi: dpi,
        pixelType: pixelType,
        discardBlankPages: discardBlankPages,
        timeoutSeconds: timeoutSeconds,
      ),
    };
  }

  Future<ScannedDocumentFile> scanFlatbedSingle({
    int? scannerId,
    String? scannerName,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    int timeoutSeconds = 90,
  }) => WindowsTwainScanRepositorySupport.scanSession(
    this,
    '/api/scans/flatbed/single',
    scannerId: scannerId,
    scannerName: scannerName,
    dpi: dpi,
    pixelType: pixelType,
    discardBlankPages: discardBlankPages,
    timeoutSeconds: timeoutSeconds,
  );

  Future<List<int>> getPagePreview(
    String sessionId,
    int pageNumber, {
    int width = 720,
    int quality = 82,
  }) => WindowsTwainScanRepositorySupport.getPagePreview(
    this,
    sessionId,
    pageNumber,
    width: width,
    quality: quality,
  );

  Future<void> rotatePage(
    String sessionId,
    int pageNumber, {
    int degrees = 90,
  }) => WindowsTwainScanRepositorySupport.rotatePage(
    this,
    sessionId,
    pageNumber,
    degrees: degrees,
  );

  Future<void> adjustPage(
    String sessionId,
    int pageNumber, {
    int brightness = 0,
    int contrast = 0,
  }) => WindowsTwainScanRepositorySupport.adjustPage(
    this,
    sessionId,
    pageNumber,
    brightness: brightness,
    contrast: contrast,
  );

  Future<void> movePage(
    String sessionId,
    int pageNumber, {
    required int targetPageNumber,
  }) => WindowsTwainScanRepositorySupport.movePage(
    this,
    sessionId,
    pageNumber,
    targetPageNumber: targetPageNumber,
  );

  Future<ScanSessionSnapshot> deletePage(String sessionId, int pageNumber) =>
      WindowsTwainScanRepositorySupport.deletePage(this, sessionId, pageNumber);

  Future<ScanSessionSnapshot> mergeSession(
    String sessionId,
    String sourceSessionId, {
    int? insertAfterPageNumber,
  }) => WindowsTwainScanRepositorySupport.mergeSession(
    this,
    sessionId,
    sourceSessionId,
    insertAfterPageNumber: insertAfterPageNumber,
  );

  Future<List<int>> downloadPdf(String sessionId) =>
      WindowsTwainScanRepositorySupport.downloadPdf(this, sessionId);
  Future<void> deleteSession(String sessionId) =>
      WindowsTwainScanRepositorySupport.deleteSession(this, sessionId);
  Future<ScanSessionDetails> getSession(String sessionId) async =>
      ScanSessionDetails.fromJson(
        _decodeObject(
          await _httpClient.get(
            _buildUri('/api/scans/$sessionId'),
            headers: const {'Accept': 'application/json'},
          ),
        ),
      );

  http.Client get httpClient => _httpClient;
  Uri buildUri(String path) => _buildUri(path);
  Map<String, dynamic> decodeObject(http.Response response) =>
      _decodeObject(response);
  ApiException toException(http.Response response) => _toException(response);
  ApiException buildApiException(
    Map<String, dynamic> payload,
    int statusCode,
    String fallback,
  ) => ApiException(
    WindowsTwainScanRepositorySupport.messageFromPayload(payload, fallback),
    statusCode: statusCode,
  );

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl/$normalizedPath');
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toException(response);
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'El servicio de escaneo devolvio JSON invalido.',
      );
    }

    return decoded;
  }

  ApiException _toException(http.Response response) =>
      WindowsTwainScanRepositorySupport.toException(response);

  String resolveFileName(http.Response response, String fallbackFileName) =>
      _resolveFileName(response, fallbackFileName);
  Future<WindowsTwainServiceStatus> _deleteStatus(String path) async =>
      WindowsTwainServiceStatus.fromJson(
        _decodeObject(await _httpClient.delete(_buildUri(path))),
      );
  String _resolveFileName(http.Response response, String fallbackFileName) =>
      WindowsTwainScanRepositorySupport.resolveFileName(
        response,
        fallbackFileName,
      );
}
