import 'dart:convert';

import 'package:http/http.dart' as http;

class SgdApiClient {
  SgdApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'SGD_API_URL',
              defaultValue: 'http://127.0.0.1:8081',
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _authToken;

  String get acquisitionUrl => '$baseUrl/ui/ui1.html';
  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token?.trim().isEmpty == true ? null : token?.trim();
  }

  Future<Map<String, dynamic>> login({
    required String loginName,
    required String password,
  }) {
    return _send('POST', '/auth/login', body: {
      'login': loginName,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> fetchMe() {
    return _send('GET', '/auth/me');
  }

  Future<void> logout() {
    return _sendWithoutResult('POST', '/auth/logout');
  }

  Future<List<Map<String, dynamic>>> listProjects() async {
    final response = await _send('GET', '/projects');
    final items = (response['items'] as List?) ?? const [];
    return items.map((item) => Map<String, dynamic>.from((item as Map).cast<String, dynamic>())).toList();
  }

  Future<Map<String, dynamic>> fetchProjectSnapshot(String projectId) async {
    return _send('GET', '/projects/$projectId/snapshot');
  }

  Future<Map<String, dynamic>> fetchProjectSecurity(String projectId) {
    return _send('GET', '/projects/$projectId/security');
  }

  Future<String> createProject(Map<String, dynamic> body) async {
    final response = await _send('POST', '/projects', body: body);
    return response['id'] as String;
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> body) {
    return _sendWithoutResult('PUT', '/projects/$projectId', body: body);
  }

  Future<void> deleteProject(String projectId) {
    return _sendWithoutResult('DELETE', '/projects/$projectId');
  }

  Future<String> createProjectProfile(String projectId, Map<String, dynamic> body) async {
    final response = await _send('POST', '/projects/$projectId/profiles', body: body);
    return response['id'] as String;
  }

  Future<void> updateProjectProfile(String projectId, String profileId, Map<String, dynamic> body) {
    return _sendWithoutResult('PUT', '/projects/$projectId/profiles/$profileId', body: body);
  }

  Future<void> deleteProjectProfile(String projectId, String profileId) {
    return _sendWithoutResult('DELETE', '/projects/$projectId/profiles/$profileId');
  }

  Future<Map<String, dynamic>> createProjectMembership(String projectId, Map<String, dynamic> body) {
    return _send('POST', '/projects/$projectId/memberships', body: body);
  }

  Future<void> updateProjectMembership(String projectId, String userId, Map<String, dynamic> body) {
    return _sendWithoutResult('PUT', '/projects/$projectId/memberships/$userId', body: body);
  }

  Future<String> createNodeType(String projectId, Map<String, dynamic> body) async {
    final response = await _send('POST', '/projects/$projectId/node-types', body: body);
    return response['id'] as String;
  }

  Future<void> updateNodeType(String projectId, String typeId, Map<String, dynamic> body) {
    return _sendWithoutResult('PUT', '/projects/$projectId/node-types/$typeId', body: body);
  }

  Future<void> deleteNodeType(String projectId, String typeId) {
    return _sendWithoutResult('DELETE', '/projects/$projectId/node-types/$typeId');
  }

  Future<void> syncNodeTypeAttributes(String projectId, String typeId, List<Map<String, dynamic>> items) {
    return _sendWithoutResult(
      'PUT',
      '/projects/$projectId/node-types/$typeId/attributes/sync',
      body: {'items': items},
    );
  }

  Future<void> createRule(String projectId, Map<String, dynamic> body) {
    return _sendWithoutResult('POST', '/projects/$projectId/rules', body: body);
  }

  Future<void> deleteRule(String projectId, String parentTypeId, String childTypeId) {
    return _sendWithoutResult('DELETE', '/projects/$projectId/rules/$parentTypeId/$childTypeId');
  }

  Future<String> createNode(String projectId, Map<String, dynamic> body) async {
    final response = await _send('POST', '/projects/$projectId/nodes', body: body);
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> listNodeDocuments(String projectId, String nodeId) async {
    final response = await _send('GET', '/projects/$projectId/nodes/$nodeId/documents');
    final items = (response['items'] as List?) ?? const [];
    return items.map((item) => Map<String, dynamic>.from((item as Map).cast<String, dynamic>())).toList();
  }

  Future<Map<String, dynamic>> createDocumentFromScan(
    String projectId,
    String nodeId,
    Map<String, dynamic> body,
  ) {
    return _send('POST', '/projects/$projectId/nodes/$nodeId/documents/from-scan', body: body);
  }

  String documentPdfUrl(String projectId, String documentId) => '$baseUrl/projects/$projectId/documents/$documentId/pdf';

  Future<void> updateNode(String projectId, String nodeId, Map<String, dynamic> body) {
    return _sendWithoutResult('PUT', '/projects/$projectId/nodes/$nodeId', body: body);
  }

  Future<void> deleteNode(String projectId, String nodeId) {
    return _sendWithoutResult('DELETE', '/projects/$projectId/nodes/$nodeId');
  }

  Future<void> _sendWithoutResult(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    await _send(method, path, body: body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;
    final headers = <String, String>{'content-type': 'application/json'};
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['authorization'] = 'Bearer $_authToken';
    }
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encodedBody);
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encodedBody);
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
      default:
        throw ApiException('Método no soportado: $method');
    }

    final text = response.body.trim();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 400) {
      throw ApiException(
        (json['error'] ?? 'Error HTTP ${response.statusCode}').toString(),
        statusCode: response.statusCode,
      );
    }

    return json;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
