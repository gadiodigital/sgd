import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../documents/domain/scan_session_snapshot.dart';
import '../../documents/domain/scanner_device.dart';
import '../../documents/domain/scanned_document_file.dart';
import '../api/api_exception.dart';
import 'windows_twain_scan_repository.dart';

final class WindowsTwainScanRepositorySupport {
  static Future<ScannedDocumentFile> scanSession(
    WindowsTwainScanRepository repo,
    String path, {
    int? scannerId,
    String? scannerName,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    int timeoutSeconds = 90,
  }) async {
    final sessionResponse = await repo.httpClient.post(
      repo.buildUri(path),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        if (scannerId != null) 'scannerId': scannerId,
        if (scannerName != null && scannerName.trim().isNotEmpty)
          'scannerName': scannerName.trim(),
        'timeoutSeconds': timeoutSeconds,
        'dpi': dpi,
        'pixelType': pixelType,
        'discardBlankPages': discardBlankPages,
      }),
    );
    final payload = repo.decodeObject(sessionResponse);
    final result = (payload['result'] as String? ?? '').trim().toLowerCase();
    if (result.isNotEmpty && result != 'ok') {
      throw repo.buildApiException(
        payload,
        sessionResponse.statusCode,
        'El escaneo no pudo completarse.',
      );
    }

    final status = (payload['status'] as String? ?? '').trim().toLowerCase();
    final pageCount = payload['pageCount'] as int? ?? 0;
    final sessionId = (payload['sessionId'] as String? ?? '').trim();
    if (sessionId.isEmpty || status != 'completed' || pageCount <= 0) {
      throw repo.buildApiException(
        payload,
        sessionResponse.statusCode,
        'El escaneo no devolvio paginas validas.',
      );
    }

    final pdfResponse = await repo.httpClient.get(
      repo.buildUri('/api/scans/$sessionId/pdf'),
      headers: const {'Accept': '*/*'},
    );
    ensureSuccess(repo, pdfResponse);

    return ScannedDocumentFile(
      sessionId: sessionId,
      fileName: repo.resolveFileName(pdfResponse, '$sessionId.pdf'),
      bytes: pdfResponse.bodyBytes,
      pageCount: pageCount,
      scannerName: (payload['scannerName'] as String? ?? '').trim(),
    );
  }

  static Future<List<int>> getPagePreview(
    WindowsTwainScanRepository repo,
    String sessionId,
    int pageNumber, {
    int width = 720,
    int quality = 82,
  }) async {
    final response = await repo.httpClient.get(
      repo.buildUri(
        '/api/scans/$sessionId/pages/$pageNumber/preview?width=$width&quality=$quality',
      ),
      headers: const {'Accept': '*/*'},
    );
    ensureSuccess(repo, response);
    return response.bodyBytes;
  }

  static Future<void> rotatePage(
    WindowsTwainScanRepository repo,
    String sessionId,
    int pageNumber, {
    int degrees = 90,
  }) async {
    ensureSuccess(
      repo,
      await jsonPost(
        repo,
        '/api/scans/$sessionId/pages/$pageNumber/rotate',
        <String, Object?>{'degrees': degrees},
      ),
    );
  }

  static Future<void> adjustPage(
    WindowsTwainScanRepository repo,
    String sessionId,
    int pageNumber, {
    int brightness = 0,
    int contrast = 0,
  }) async {
    ensureSuccess(
      repo,
      await jsonPost(
        repo,
        '/api/scans/$sessionId/pages/$pageNumber/adjust',
        <String, Object?>{'brightness': brightness, 'contrast': contrast},
      ),
    );
  }

  static Future<void> movePage(
    WindowsTwainScanRepository repo,
    String sessionId,
    int pageNumber, {
    required int targetPageNumber,
  }) async {
    ensureSuccess(
      repo,
      await jsonPost(
        repo,
        '/api/scans/$sessionId/pages/$pageNumber/move',
        <String, Object?>{'targetPageNumber': targetPageNumber},
      ),
    );
  }

  static Future<ScanSessionSnapshot> deletePage(
    WindowsTwainScanRepository repo,
    String sessionId,
    int pageNumber,
  ) async {
    final response = await repo.httpClient.delete(
      repo.buildUri('/api/scans/$sessionId/pages/$pageNumber'),
      headers: const {'Accept': 'application/json'},
    );
    return ScanSessionSnapshot.fromJson(repo.decodeObject(response));
  }

  static Future<ScanSessionSnapshot> mergeSession(
    WindowsTwainScanRepository repo,
    String sessionId,
    String sourceSessionId, {
    int? insertAfterPageNumber,
  }) async {
    final response =
        await jsonPost(repo, '/api/scans/$sessionId/merge', <String, Object?>{
          'sourceSessionId': sourceSessionId,
          if (insertAfterPageNumber != null)
            'insertAfterPageNumber': insertAfterPageNumber,
        });
    return ScanSessionSnapshot.fromJson(repo.decodeObject(response));
  }

  static Future<List<int>> downloadPdf(
    WindowsTwainScanRepository repo,
    String sessionId,
  ) async {
    final response = await repo.httpClient.get(
      repo.buildUri('/api/scans/$sessionId/pdf'),
      headers: const {'Accept': '*/*'},
    );
    ensureSuccess(repo, response);
    return response.bodyBytes;
  }

  static Future<void> deleteSession(
    WindowsTwainScanRepository repo,
    String sessionId,
  ) async {
    final response = await repo.httpClient.delete(
      repo.buildUri('/api/scans/$sessionId'),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode == 404) {
      return;
    }
    ensureSuccess(repo, response);
  }

  static List<ScannerDevice> parseScannersResponse(
    WindowsTwainScanRepository repo,
    http.Response response,
  ) {
    final payload = repo.decodeObject(response);
    final result = (payload['result'] as String? ?? 'ok').trim().toLowerCase();
    if (result == 'error') {
      throw repo.buildApiException(
        payload,
        response.statusCode,
        'El servicio de escaneo devolvio un error al listar escaneres.',
      );
    }

    final scanners = payload['scanners'];
    if (scanners is! List<dynamic>) {
      return const [];
    }

    return scanners
        .whereType<Map<String, dynamic>>()
        .map(ScannerDevice.fromJson)
        .where((device) => device.name.isNotEmpty)
        .toList(growable: false);
  }

  static ApiException toException(http.Response response) {
    if (response.body.trim().isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiException(
          messageFromPayload(
            decoded,
            'La solicitud al servicio de escaneo fallo con estado '
            '${response.statusCode}.',
          ),
          statusCode: response.statusCode,
        );
      }
    }

    return ApiException(
      'La solicitud al servicio de escaneo fallo con estado '
      '${response.statusCode}.',
      statusCode: response.statusCode,
    );
  }

  static String messageFromPayload(
    Map<String, dynamic> payload,
    String fallback,
  ) {
    final message = payload['message'] ?? payload['detail'] ?? payload['title'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return fallback;
  }

  static String resolveFileName(
    http.Response response,
    String fallbackFileName,
  ) {
    final header = response.headers['content-disposition'];
    if (header == null || header.trim().isEmpty) {
      return fallbackFileName;
    }

    final utf8Match = RegExp(
      "filename\\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1) ?? fallbackFileName);
    }

    final simpleMatch = RegExp(
      'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    if (simpleMatch != null) {
      return simpleMatch.group(1)?.trim() ?? fallbackFileName;
    }

    return fallbackFileName;
  }

  static Future<http.Response> jsonPost(
    WindowsTwainScanRepository repo,
    String path,
    Map<String, Object?> body,
  ) => repo.httpClient.post(
    repo.buildUri(path),
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  static void ensureSuccess(
    WindowsTwainScanRepository repo,
    http.Response response,
  ) => response.statusCode < 200 || response.statusCode >= 300
      ? throw toException(response)
      : null;
}
