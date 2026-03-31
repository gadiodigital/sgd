import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/application/document_version_upload_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<AppSessionViewModel> buildSignedInSession(MockClient client) async {
    final sessionViewModel = AppSessionViewModel(httpClient: client);
    final signedIn = await sessionViewModel.signIn(
      tenantCode: 'acme',
      email: 'scanner@gdms.test',
      password: 'secret',
    );
    expect(signedIn, isTrue);
    return sessionViewModel;
  }

  test('upload de version informa cuando no hay sesion autenticada', () async {
    final client = MockClient((request) async {
      return http.Response('not-found', 404);
    });
    final sessionViewModel = AppSessionViewModel(httpClient: client);
    addTearDown(sessionViewModel.dispose);

    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    final uploaded = await viewModel.upload(
      documentId: 'doc-1',
      file: PlatformFile(
        name: 'version.pdf',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect(uploaded, isFalse);
    expect(viewModel.message, 'No hay una sesion autenticada activa.');
  });

  test('upload de version valida archivo vacio antes de subir', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/token') {
        return http.Response(
          jsonEncode({
            'accessToken': 'token-123',
            'tokenType': 'Bearer',
            'expiresAtUtc': '2026-03-31T12:00:00Z',
            'expiresInSeconds': 3600,
            'mustChangePassword': false,
            'userId': 'user-1',
            'email': 'scanner@gdms.test',
            'fullName': 'Scanner User',
            'roles': ['TENANT_ADMIN'],
            'tenantId': 'tenant-1',
            'tenantCode': 'acme',
            'tenantName': 'ACME',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/auth/me') {
        return http.Response(
          jsonEncode({
            'userId': 'user-1',
            'tenantId': 'tenant-1',
            'tenantCode': 'acme',
            'email': 'scanner@gdms.test',
            'fullName': 'Scanner User',
            'roles': ['TENANT_ADMIN'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('not-found', 404);
    });

    final sessionViewModel = await buildSignedInSession(client);
    addTearDown(sessionViewModel.dispose);

    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    final emptyUpload = await viewModel.upload(
      documentId: 'doc-1',
      file: PlatformFile(name: 'empty.pdf', size: 0, bytes: Uint8List(0)),
    );

    expect(emptyUpload, isFalse);
    expect(viewModel.message, 'No se pudo leer el archivo seleccionado.');
  });
}
