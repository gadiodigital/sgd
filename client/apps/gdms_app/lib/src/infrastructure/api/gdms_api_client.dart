import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_defaults.dart';
import 'api_exception.dart';
import 'downloaded_binary_file.dart';

/// Handles authenticated and anonymous JSON requests to the GDMS backend.
final class GdmsApiClient {
  GdmsApiClient({
    required String Function() baseUrlProvider,
    required String? Function() accessTokenProvider,
    http.Client? httpClient,
  }) : _baseUrlProvider = baseUrlProvider,
       _accessTokenProvider = accessTokenProvider,
       _httpClient = httpClient ?? http.Client();

  final String Function() _baseUrlProvider;
  final String? Function() _accessTokenProvider;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> getObject(String path) async {
    final response = await _httpClient.get(
      _buildUri(path),
      headers: _headers(),
    );

    return _decodeObject(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _httpClient.get(
      _buildUri(path),
      headers: _headers(),
    );

    return _decodeList(response);
  }

  Future<DownloadedBinaryFile> getBinary(
    String path, {
    String fallbackFileName = 'documento.bin',
  }) async {
    final response = await _httpClient.get(
      _buildUri(path),
      headers: _binaryHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toException(response);
    }

    return DownloadedBinaryFile(
      bytes: response.bodyBytes,
      fileName: _resolveFileName(response, fallbackFileName),
      contentType:
          response.headers['content-type'] ?? 'application/octet-stream',
    );
  }

  Future<Map<String, dynamic>> postObject(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _httpClient.post(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putObject(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _httpClient.put(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postMultipartObject(
    String path, {
    required Map<String, String> fields,
    required String fileFieldName,
    required List<int> bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path))
      ..headers.addAll(_multipartHeaders())
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          fileFieldName,
          bytes,
          filename: fileName,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeObject(response);
  }

  Future<void> postNoContent(String path, Map<String, Object?> body) async {
    final response = await _httpClient.post(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toException(response);
    }
  }

  Uri _buildUri(String path) {
    final normalizedBaseUrl = ApiDefaults.normalizeBaseUrl(_baseUrlProvider());
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBaseUrl/$normalizedPath');
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final accessToken = _accessTokenProvider();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  Map<String, String> _multipartHeaders() {
    final headers = <String, String>{'Accept': 'application/json'};
    final accessToken = _accessTokenProvider();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  Map<String, String> _binaryHeaders() {
    final headers = <String, String>{'Accept': '*/*'};
    final accessToken = _accessTokenProvider();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toException(response);
    }

    final decoded = _decodeBody(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('La API devolvio un objeto JSON invalido.');
    }

    return decoded;
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toException(response);
    }

    final decoded = _decodeBody(response.body);
    if (decoded is! List<dynamic>) {
      throw const ApiException('La API devolvio una lista JSON invalida.');
    }

    return decoded;
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(body);
  }

  ApiException _toException(http.Response response) {
    final decoded = response.body.trim().isEmpty
        ? null
        : _decodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      final detail =
          decoded['detail'] ?? decoded['title'] ?? decoded['message'];
      if (detail is String && detail.trim().isNotEmpty) {
        return ApiException(detail, statusCode: response.statusCode);
      }
    }

    return ApiException(
      'La solicitud a la API fallo con estado ${response.statusCode}.',
      statusCode: response.statusCode,
    );
  }

  String _resolveFileName(http.Response response, String fallbackFileName) {
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

    final simpleMatch = RegExp('filename="?([^";]+)"?', caseSensitive: false)
        .firstMatch(header);
    if (simpleMatch != null) {
      return simpleMatch.group(1)?.trim() ?? fallbackFileName;
    }

    return fallbackFileName;
  }
}
