import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_dialog.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_version_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const windowsVariant = TargetPlatformVariant(<TargetPlatform>{
    TargetPlatform.windows,
  });

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
      if (request.url.path == '/api/tenants/tenant-1/document-types') {
        return http.Response(
          jsonEncode([
            {
              'id': 'type-1',
              'tenantId': 'tenant-1',
              'code': 'LEASE',
              'name': 'Contrato',
              'sector': 'legal',
              'isActive': true,
              'metadataSchema': {},
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('not-found', 404);
    });
  }

  testWidgets('upload inicial cambia de un archivo manual a otro y conserva el titulo previo', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var pickCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            onUploaded: () async {},
            pickFileLauncher: (_) async {
              pickCalls += 1;
              if (pickCalls == 1) {
                return PlatformFile(
                  name: 'contrato-base.pdf',
                  size: 7,
                  bytes: Uint8List.fromList(const [1, 2, 3]),
                );
              }
              return PlatformFile(
                name: 'contrato-anexo.pdf',
                size: 5,
                bytes: Uint8List.fromList(const [4, 5, 6]),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    expect(find.text('contrato-base.pdf'), findsOneWidget);
    expect(find.text('contrato-base'), findsOneWidget);

    await tester.tap(find.text('contrato-base.pdf'));
    await tester.pumpAndSettle();

    expect(pickCalls, 2);
    expect(find.text('contrato-anexo.pdf'), findsOneWidget);
    expect(find.text('contrato-base.pdf'), findsNothing);
    expect(find.textContaining('PDF escaneado'), findsNothing);
    expect(find.text('contrato-base'), findsOneWidget);
    expect(find.text('contrato-anexo'), findsNothing);
  }, variant: windowsVariant);

  testWidgets('upload de version mantiene el archivo manual previo si el segundo picker se cancela', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var pickCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentVersionDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            documentId: 'doc-1',
            documentTitle: 'Contrato marco',
            pickFileLauncher: (_) async {
              pickCalls += 1;
              if (pickCalls == 1) {
                return PlatformFile(
                  name: 'version-base.pdf',
                  size: 5,
                  bytes: Uint8List.fromList(const [7, 8, 9]),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    expect(find.text('version-base.pdf'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('version-base.pdf'));
    await tester.pumpAndSettle();

    expect(pickCalls, 2);
    expect(find.text('version-base.pdf'), findsOneWidget);
    expect(find.textContaining('PDF escaneado'), findsNothing);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNotNull,
    );
  }, variant: windowsVariant);
}
