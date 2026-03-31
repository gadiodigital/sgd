import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/application/document_upload_view_model.dart';
import 'package:gdms_app/src/documents/application/document_version_upload_view_model.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_dialog.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_version_dialog.dart';
import 'package:gdms_app/src/infrastructure/api/api_exception.dart';
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

  Widget buildUploadDialogHarness({
    required AppSessionViewModel sessionViewModel,
    required DocumentUploadViewModel viewModel,
    Future<PlatformFile?> Function(BuildContext context)? pickFileLauncher,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog<void>(
                context: context,
                builder: (_) => UploadDocumentDialog(
                  apiClient: sessionViewModel.apiClient,
                  sessionViewModel: sessionViewModel,
                  onUploaded: () async {},
                  viewModel: viewModel,
                  pickFileLauncher: pickFileLauncher,
                ),
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget buildVersionDialogHarness({
    required AppSessionViewModel sessionViewModel,
    required DocumentVersionUploadViewModel viewModel,
    Future<PlatformFile?> Function(BuildContext context)? pickFileLauncher,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog<void>(
                context: context,
                builder: (_) => UploadDocumentVersionDialog(
                  apiClient: sessionViewModel.apiClient,
                  sessionViewModel: sessionViewModel,
                  documentId: 'doc-1',
                  documentTitle: 'Contrato marco',
                  viewModel: viewModel,
                  pickFileLauncher: pickFileLauncher,
                ),
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('submit manual fallido en upload inicial deja mensaje visible y modal abierto', (
    tester,
  ) async {
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
        throw const ApiException('El backend rechazo el archivo manual.');
      },
    );

    await tester.pumpWidget(
      buildUploadDialogHarness(
        sessionViewModel: sessionViewModel,
        viewModel: viewModel,
        pickFileLauncher: (_) async => PlatformFile(
          name: 'contrato-manual.pdf',
          size: 7,
          bytes: Uint8List.fromList(const [9, 8, 7]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Subir'));
    await tester.tap(find.widgetWithText(FilledButton, 'Subir'));
    await tester.pumpAndSettle();

    expect(find.text('Subir documento'), findsOneWidget);
    expect(find.text('El backend rechazo el archivo manual.'), findsOneWidget);
  }, variant: windowsVariant);

  testWidgets('submit manual en curso para nueva version bloquea acciones y muestra progreso', (
    tester,
  ) async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    final completer = Completer<void>();
    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
      multipartUploader: ({
        required path,
        required fields,
        required fileFieldName,
        required bytes,
        required fileName,
      }) => completer.future,
    );

    await tester.pumpWidget(
      buildVersionDialogHarness(
        sessionViewModel: sessionViewModel,
        viewModel: viewModel,
        pickFileLauncher: (_) async => PlatformFile(
          name: 'version-manual.pdf',
          size: 5,
          bytes: Uint8List.fromList(const [3, 2, 1]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Subir versión'));
    await tester.tap(find.widgetWithText(FilledButton, 'Subir versión'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNull,
    );

    completer.complete();
    await tester.pumpAndSettle();
  }, variant: windowsVariant);
}
