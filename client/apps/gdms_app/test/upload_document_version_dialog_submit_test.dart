import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/application/document_version_upload_view_model.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
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
      return http.Response('not-found', 404);
    });
  }

  Widget buildDialogHarness({
    required AppSessionViewModel sessionViewModel,
    required DocumentVersionUploadViewModel viewModel,
    required ValueChanged<Object?> onResult,
    Future<Object?> Function(BuildContext context)? scanDocumentLauncher,
    Future<PlatformFile?> Function(BuildContext context)? pickFileLauncher,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog<Object?>(
                context: context,
                builder: (_) => UploadDocumentVersionDialog(
                  apiClient: sessionViewModel.apiClient,
                  sessionViewModel: sessionViewModel,
                  documentId: 'doc-1',
                  documentTitle: 'Contrato marco',
                  viewModel: viewModel,
                  scanDocumentLauncher: scanDocumentLauncher == null
                      ? null
                      : (context) async =>
                            await scanDocumentLauncher(context) as dynamic,
                  pickFileLauncher: pickFileLauncher,
                ),
              ).then(onResult);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('submit exitoso devuelve true y cierra el dialogo', (tester) async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    Object? dialogResult = const Object();
    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
      multipartUploader: ({
        required path,
        required fields,
        required fileFieldName,
        required bytes,
        required fileName,
      }) async {},
    );

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        viewModel: viewModel,
        onResult: (value) => dialogResult = value,
        scanDocumentLauncher: (_) async => const ScannedDocumentFile(
              fileName: 'version.pdf',
              bytes: [1, 2, 3],
              pageCount: 1,
              sessionId: 'session-version-1',
              scannerName: 'Fujitsu',
            ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Subir versión'));
    await tester.tap(find.widgetWithText(FilledButton, 'Subir versión'));
    await tester.pumpAndSettle();

    expect(dialogResult, isTrue);
    expect(find.text('Subir nueva versión'), findsNothing);
  }, variant: windowsVariant);

  testWidgets('submit fallido deja mensaje visible y no cierra el dialogo', (
    tester,
  ) async {
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
        throw const ApiException('La nueva versión fue rechazada.');
      },
    );

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        viewModel: viewModel,
        onResult: (_) {},
        scanDocumentLauncher: (_) async => const ScannedDocumentFile(
              fileName: 'version.pdf',
              bytes: [1, 2, 3],
              pageCount: 1,
              sessionId: 'session-version-2',
              scannerName: 'Fujitsu',
            ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Subir versión'));
    await tester.tap(find.widgetWithText(FilledButton, 'Subir versión'));
    await tester.pumpAndSettle();

    expect(find.text('Subir nueva versión'), findsOneWidget);
    expect(find.text('La nueva versión fue rechazada.'), findsOneWidget);
  }, variant: windowsVariant);

  testWidgets('submit de version en curso bloquea cancelar y muestra progreso', (
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
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        viewModel: viewModel,
        onResult: (_) {},
        scanDocumentLauncher: (_) async => const ScannedDocumentFile(
              fileName: 'version.pdf',
              bytes: [1, 2, 3],
              pageCount: 1,
              sessionId: 'session-version-3',
              scannerName: 'Fujitsu',
            ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
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

  testWidgets('submit de version exitoso tambien funciona con archivo manual', (
    tester,
  ) async {
    final sessionViewModel = await buildSignedInSession(buildClient());
    addTearDown(sessionViewModel.dispose);

    Object? dialogResult = const Object();
    final viewModel = DocumentVersionUploadViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
      multipartUploader: ({
        required path,
        required fields,
        required fileFieldName,
        required bytes,
        required fileName,
      }) async {},
    );

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        viewModel: viewModel,
        onResult: (value) => dialogResult = value,
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
    await tester.pumpAndSettle();

    expect(dialogResult, isTrue);
    expect(find.text('Subir nueva versión'), findsNothing);
  }, variant: windowsVariant);
}
