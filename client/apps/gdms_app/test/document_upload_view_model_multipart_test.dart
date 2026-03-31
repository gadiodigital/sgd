import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/application/document_upload_view_model.dart';
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

  test('upload exitoso usa path fields metadata normalizada y bytes reales', () async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    String? capturedPath;
    Map<String, String>? capturedFields;
    String? capturedFieldName;
    List<int>? capturedBytes;
    String? capturedFileName;

    final viewModel = DocumentUploadViewModel(
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
      documentTypeCode: '  LEASE  ',
      title: '  Contrato marco  ',
      file: PlatformFile(
        name: 'contrato.pdf',
        size: 4,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      ),
      metadata: const {
        'caseNumber': '  EXP-123  ',
        'signed': true,
        'empty': '   ',
      },
    );

    expect(uploaded, isTrue);
    expect(capturedPath, '/api/tenants/tenant-1/documents/upload');
    expect(capturedFieldName, 'file');
    expect(capturedFileName, 'contrato.pdf');
    expect(capturedBytes, [1, 2, 3, 4]);
    expect(capturedFields, {
      'documentTypeCode': 'LEASE',
      'title': 'Contrato marco',
      'metadataJson': jsonEncode({
        'caseNumber': 'EXP-123',
        'signed': true,
      }),
    });
    expect(viewModel.message, 'Documento subido correctamente.');
  });

  test('upload usa mensaje de ApiException del uploader multipart', () async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    final viewModel = DocumentUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
      multipartUploader: ({
        required path,
        required fields,
        required fileFieldName,
        required bytes,
        required fileName,
      }) async {
        throw const ApiException('El backend rechazo el binario.');
      },
    );

    final uploaded = await viewModel.upload(
      documentTypeCode: 'LEASE',
      title: null,
      file: PlatformFile(
        name: 'contrato.pdf',
        size: 4,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      ),
    );

    expect(uploaded, isFalse);
    expect(viewModel.message, 'El backend rechazo el binario.');
  });
}
