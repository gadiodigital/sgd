import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/application/document_version_upload_view_model.dart';
import 'package:gdms_app/src/infrastructure/api/api_exception.dart';
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

  MockClient buildClient() {
    return MockClient((request) async {
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
  }

  test('upload de version exitoso usa path y payload correctos', () async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    String? capturedPath;
    Map<String, String>? capturedFields;
    String? capturedFieldName;
    List<int>? capturedBytes;
    String? capturedFileName;

    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
      multipartUploader: ({
        required path,
        required fields,
        required fileFieldName,
        required bytes,
        required fileName,
      }) async {
        capturedPath = path;
        capturedFields = fields;
        capturedFieldName = fileFieldName;
        capturedBytes = bytes;
        capturedFileName = fileName;
      },
    );

    final uploaded = await viewModel.upload(
      documentId: 'doc-55',
      file: PlatformFile(
        name: 'version.pdf',
        size: 3,
        bytes: Uint8List.fromList([7, 8, 9]),
      ),
    );

    expect(uploaded, isTrue);
    expect(
      capturedPath,
      '/api/tenants/tenant-1/documents/doc-55/versions/upload',
    );
    expect(capturedFields, isEmpty);
    expect(capturedFieldName, 'file');
    expect(capturedFileName, 'version.pdf');
    expect(capturedBytes, [7, 8, 9]);
    expect(viewModel.message, 'Nueva versión subida correctamente.');
  });

  test('upload de version usa mensaje de ApiException del uploader multipart', () async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
      multipartUploader: ({
        required path,
        required fields,
        required fileFieldName,
        required bytes,
        required fileName,
      }) async {
        throw const ApiException('La version fue rechazada.');
      },
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
    expect(viewModel.message, 'La version fue rechazada.');
  });
}
