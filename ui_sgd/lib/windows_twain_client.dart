import 'dart:convert';

import 'package:http/http.dart' as http;

class WindowsTwainClient {
  WindowsTwainClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'WINDOWS_TWAIN_URL',
              defaultValue: 'http://127.0.0.1:43127',
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<TwainScannerDescriptor>> listScanners() async {
    final payload = await _send('GET', '/api/scanners');
    final scanners = (payload['scanners'] as List?) ?? const [];
    return scanners
        .map((item) => TwainScannerDescriptor.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
        .toList();
  }

  Future<Map<String, dynamic>> fetchStatus() => _send('GET', '/api/status');

  Future<TwainScanSession> startScan({
    required bool duplex,
    int? scannerId,
    int? dpi,
    required String pixelType,
    required bool discardBlankPages,
    required int timeoutSeconds,
  }) async {
    final payload = <String, dynamic>{
      'timeoutSeconds': timeoutSeconds,
      'discardBlankPages': discardBlankPages ? 'auto' : 'off',
    };
    if (scannerId != null) {
      payload['scannerId'] = scannerId;
    }
    if (dpi != null) {
      payload['dpi'] = dpi;
    }
    if (pixelType.isNotEmpty) {
      payload['pixelType'] = pixelType;
    }
    final response = await _send('POST', duplex ? '/api/scans/adf/duplex' : '/api/scans/adf/simplex', body: payload);
    return TwainScanSession.fromJson(response);
  }

  Future<TwainScanSession> fetchSession(String sessionId) async {
    final response = await _send('GET', '/api/scans/$sessionId');
    return TwainScanSession.fromJson(response);
  }

  Future<TwainScanSession> rotatePage(String sessionId, int pageNumber, int degrees) async {
    final response = await _send(
      'POST',
      '/api/scans/$sessionId/pages/$pageNumber/rotate',
      body: {'degrees': degrees},
    );
    return TwainScanSession.fromJson(response);
  }

  Future<TwainScanSession> deletePage(String sessionId, int pageNumber) async {
    final response = await _send('DELETE', '/api/scans/$sessionId/pages/$pageNumber');
    return TwainScanSession.fromJson(response);
  }

  Future<TwainScanSession> movePage(String sessionId, int pageNumber, int targetPageNumber) async {
    final response = await _send(
      'POST',
      '/api/scans/$sessionId/pages/$pageNumber/move',
      body: {'targetPageNumber': targetPageNumber},
    );
    return TwainScanSession.fromJson(response);
  }

  Future<TwainScanSession> adjustPage(
    String sessionId,
    int pageNumber, {
    required int brightness,
    required int contrast,
  }) async {
    final response = await _send(
      'POST',
      '/api/scans/$sessionId/pages/$pageNumber/adjust',
      body: {'brightness': brightness, 'contrast': contrast},
    );
    return TwainScanSession.fromJson(response);
  }

  Future<TwainScanSession> mergeSession(
    String targetSessionId,
    String sourceSessionId, {
    int? insertAfterPageNumber,
  }) async {
    final response = await _send(
      'POST',
      '/api/scans/$targetSessionId/merge',
      body: {
        'sourceSessionId': sourceSessionId,
        ...?insertAfterPageNumber == null ? null : {'insertAfterPageNumber': insertAfterPageNumber},
      },
    );
    return TwainScanSession.fromJson(response);
  }

  String previewUrl(
    String sessionId,
    int pageNumber, {
    int width = 420,
    int quality = 78,
  }) {
    final uri = Uri.parse('$baseUrl/api/scans/$sessionId/pages/$pageNumber/preview').replace(
      queryParameters: {
        'width': '$width',
        'quality': '$quality',
        't': '${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return uri.toString();
  }

  String pdfUrl(String sessionId) => '$baseUrl/api/scans/$sessionId/pdf';

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;
    final headers = <String, String>{'content-type': 'application/json'};
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encodedBody);
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
      default:
        throw TwainApiException('Método no soportado: $method');
    }

    final text = response.body.trim();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 400) {
      throw TwainApiException(
        (json['message'] ?? json['error'] ?? 'Error HTTP ${response.statusCode}').toString(),
        statusCode: response.statusCode,
      );
    }

    final result = (json['result'] ?? '').toString().toLowerCase();
    if (result == 'error' || result == 'not-ready') {
      throw TwainApiException(
        (json['message'] ?? 'windows-twain devolvió un error.').toString(),
        statusCode: response.statusCode,
      );
    }

    return json;
  }
}

class TwainApiException implements Exception {
  TwainApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TwainScannerDescriptor {
  const TwainScannerDescriptor({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.productFamily,
    required this.twainVersion,
    required this.isOpen,
  });

  factory TwainScannerDescriptor.fromJson(Map<String, dynamic> json) => TwainScannerDescriptor(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        manufacturer: (json['manufacturer'] ?? '').toString(),
        productFamily: (json['productFamily'] ?? '').toString(),
        twainVersion: (json['twainVersion'] ?? '').toString(),
        isOpen: json['isOpen'] == true,
      );

  final int id;
  final String name;
  final String manufacturer;
  final String productFamily;
  final String twainVersion;
  final bool isOpen;
}

class TwainScanSession {
  const TwainScanSession({
    required this.result,
    required this.sessionId,
    required this.status,
    required this.createdAtUtc,
    required this.scannerName,
    required this.mode,
    required this.settings,
    required this.pageCount,
    required this.pages,
    required this.sessionPath,
    required this.message,
  });

  factory TwainScanSession.fromJson(Map<String, dynamic> json) => TwainScanSession(
        result: (json['result'] ?? 'ok').toString(),
        sessionId: (json['sessionId'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        createdAtUtc: (json['createdAtUtc'] ?? '').toString(),
        scannerName: (json['scannerName'] ?? '').toString(),
        mode: (json['mode'] ?? '').toString(),
        settings: TwainScanSettings.fromJson(Map<String, dynamic>.from(((json['settings'] as Map?) ?? const {}).cast<String, dynamic>())),
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        pages: ((json['pages'] as List?) ?? const [])
            .map((item) => TwainScanPage.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
        sessionPath: (json['sessionPath'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
      );

  final String result;
  final String sessionId;
  final String status;
  final String createdAtUtc;
  final String scannerName;
  final String mode;
  final TwainScanSettings settings;
  final int pageCount;
  final List<TwainScanPage> pages;
  final String sessionPath;
  final String message;
}

class TwainScanSettings {
  const TwainScanSettings({
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
    required this.transferFormat,
  });

  factory TwainScanSettings.fromJson(Map<String, dynamic> json) => TwainScanSettings(
        dpi: (json['dpi'] as num?)?.toDouble(),
        pixelType: (json['pixelType'] ?? '').toString(),
        discardBlankPages: (json['discardBlankPages'] ?? '').toString(),
        transferFormat: (json['transferFormat'] ?? '').toString(),
      );

  final double? dpi;
  final String pixelType;
  final String discardBlankPages;
  final String transferFormat;
}

class TwainScanPage {
  const TwainScanPage({
    required this.pageNumber,
    required this.fileName,
    required this.filePath,
    required this.transferType,
    required this.fileFormat,
    required this.length,
  });

  factory TwainScanPage.fromJson(Map<String, dynamic> json) => TwainScanPage(
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
        fileName: (json['fileName'] ?? '').toString(),
        filePath: (json['filePath'] ?? '').toString(),
        transferType: (json['transferType'] ?? '').toString(),
        fileFormat: (json['fileFormat'] ?? '').toString(),
        length: (json['length'] as num?)?.toInt() ?? 0,
      );

  final int pageNumber;
  final String fileName;
  final String filePath;
  final String transferType;
  final String fileFormat;
  final int length;
}
