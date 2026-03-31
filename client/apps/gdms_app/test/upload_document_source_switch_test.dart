import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
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

  ScannedDocumentFile buildScannedFile() {
    return const ScannedDocumentFile(
      fileName: 'scan-lease.pdf',
      bytes: [1, 2, 3, 4],
      pageCount: 2,
      sessionId: 'session-scan-1',
      scannerName: 'Canon DR',
    );
  }

  testWidgets('upload inicial cambia de escaneo a archivo manual sin dejar badge fantasma', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            onUploaded: () async {},
            scanDocumentLauncher: (_) async => buildScannedFile(),
            pickFileLauncher: (_) async =>
                PlatformFile(
                  name: 'contrato-manual.pdf',
                  size: 7,
                  bytes: Uint8List.fromList(const [9, 8, 7]),
                ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(find.text('scan-lease.pdf'), findsOneWidget);
    expect(
      find.text('PDF escaneado desde Canon DR con 2 pagina(s).'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('scan-lease.pdf'));
    await tester.tap(find.text('scan-lease.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('contrato-manual.pdf'), findsOneWidget);
    expect(find.text('scan-lease.pdf'), findsNothing);
    expect(find.textContaining('PDF escaneado'), findsNothing);
    expect(find.text('scan-lease'), findsOneWidget);
  }, variant: windowsVariant);

  testWidgets('upload de version cambia de archivo manual a escaneo y reemplaza el origen activo', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentVersionDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            documentId: 'doc-1',
            documentTitle: 'Contrato marco',
            pickFileLauncher: (_) async =>
                PlatformFile(
                  name: 'version-manual.pdf',
                  size: 5,
                  bytes: Uint8List.fromList(const [5, 4, 3]),
                ),
            scanDocumentLauncher: (_) async => buildScannedFile(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    expect(find.text('version-manual.pdf'), findsOneWidget);
    expect(find.textContaining('PDF escaneado'), findsNothing);

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(find.text('scan-lease.pdf'), findsOneWidget);
    expect(find.text('version-manual.pdf'), findsNothing);
    expect(
      find.text('PDF escaneado desde Canon DR con 2 pagina(s).'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNotNull,
    );
  }, variant: windowsVariant);
}
