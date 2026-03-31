import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_dialog.dart';
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

  testWidgets('usar escaneo actualiza el dialogo de upload con badge y archivo', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var launcherCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            onUploaded: () async {},
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
    expect(find.text('scan-lease.pdf'), findsOneWidget);
    expect(
      find.text('PDF escaneado desde Canon DR con 2 pagina(s).'),
      findsOneWidget,
    );
    expect(find.text('scan-lease'), findsOneWidget);
  }, variant: windowsVariant);

  testWidgets('startWithScanner dispara el launcher al abrir y deja el scan activo', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var launcherCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            onUploaded: () async {},
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
    expect(find.text('scan-lease.pdf'), findsOneWidget);
    expect(
      find.text('PDF escaneado desde Canon DR con 2 pagina(s).'),
      findsOneWidget,
    );
  }, variant: windowsVariant);

  testWidgets('el escaneo no pisa un titulo ya editado por el usuario', (
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
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Titulo manual');
    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(find.text('Titulo manual'), findsOneWidget);
    expect(find.text('scan-lease.pdf'), findsOneWidget);
    expect(find.text('scan-lease'), findsNothing);
  }, variant: windowsVariant);

  testWidgets('un segundo escaneo reemplaza el archivo pero conserva el titulo autocompletado previo', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    var launcherCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadDocumentDialog(
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
            onUploaded: () async {},
            scanDocumentLauncher: (_) async {
              launcherCalls += 1;
              if (launcherCalls == 1) {
                return buildScannedFile();
              }
              return const ScannedDocumentFile(
                fileName: 'scan-amendment.pdf',
                bytes: [9, 8, 7],
                pageCount: 1,
                sessionId: 'session-scan-2',
                scannerName: 'Epson DS',
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();
    expect(find.text('scan-lease'), findsOneWidget);

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(launcherCalls, 2);
    expect(find.text('scan-amendment.pdf'), findsOneWidget);
    expect(
      find.text('PDF escaneado desde Epson DS con 1 pagina(s).'),
      findsOneWidget,
    );
    expect(find.text('scan-lease'), findsOneWidget);
    expect(find.text('scan-amendment'), findsNothing);
  }, variant: windowsVariant);
}
