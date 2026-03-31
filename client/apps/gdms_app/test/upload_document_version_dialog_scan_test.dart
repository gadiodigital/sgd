import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_version_dialog.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
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

      return http.Response('not-found', 404);
    });
  }

  ScannedDocumentFile buildScannedFile() {
    return const ScannedDocumentFile(
      fileName: 'version-scan.pdf',
      bytes: [1, 2, 3],
      pageCount: 4,
      sessionId: 'session-v1',
      scannerName: 'Fujitsu fi',
    );
  }

  testWidgets('usar escaneo deja lista una nueva version basada en el PDF escaneado', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var launcherCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentVersionDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            documentId: 'doc-1',
            documentTitle: 'Contrato marco',
            scanDocumentLauncher: (_) async {
              launcherCalls += 1;
              return buildScannedFile();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(launcherCalls, 1);
    expect(find.text('version-scan.pdf'), findsOneWidget);
    expect(
      find.text('PDF escaneado desde Fujitsu fi con 4 pagina(s).'),
      findsOneWidget,
    );

    final uploadButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Subir versión'),
    );
    expect(uploadButton.onPressed, isNotNull);
  }, variant: windowsVariant);

  testWidgets('startWithScanner abre el launcher al iniciar el dialogo de version', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var launcherCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentVersionDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            documentId: 'doc-1',
            documentTitle: 'Contrato marco',
            startWithScanner: true,
            scanDocumentLauncher: (_) async {
              launcherCalls += 1;
              return buildScannedFile();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(launcherCalls, 1);
    expect(find.text('version-scan.pdf'), findsOneWidget);
    expect(
      find.text('PDF escaneado desde Fujitsu fi con 4 pagina(s).'),
      findsOneWidget,
    );
  }, variant: windowsVariant);
}
