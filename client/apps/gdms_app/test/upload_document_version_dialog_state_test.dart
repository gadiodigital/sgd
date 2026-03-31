import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
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

      return http.Response('not-found', 404);
    });
  }

  Widget buildDialogHarness({
    required AppSessionViewModel sessionViewModel,
    required ValueChanged<Object?> onResult,
    bool startWithScanner = false,
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
                  startWithScanner: startWithScanner,
                  scanDocumentLauncher: scanDocumentLauncher == null
                      ? null
                      : (innerContext) async =>
                            await scanDocumentLauncher(innerContext)
                                as dynamic,
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

  testWidgets('dialogo inicia con subida deshabilitada y texto base', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subir nueva versión'), findsOneWidget);
    expect(find.text('Contrato marco'), findsOneWidget);
    expect(find.text('Seleccionar archivo'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNull,
    );
  }, variant: windowsVariant);

  testWidgets('cancelar cierra el dialogo de nueva version', (tester) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);
    Object? dialogResult = const Object();

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        onResult: (value) => dialogResult = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(dialogResult, isNull);
    expect(find.byType(UploadDocumentVersionDialog), findsNothing);
  }, variant: windowsVariant);

  testWidgets('cancelar el scanner mantiene la version sin archivo activo', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);
    var launcherCalls = 0;

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        onResult: (_) {},
        scanDocumentLauncher: (_) async {
          launcherCalls += 1;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(launcherCalls, 1);
    expect(find.textContaining('.pdf'), findsNothing);
    expect(find.textContaining('PDF escaneado'), findsNothing);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNull,
    );
  }, variant: windowsVariant);

  testWidgets('startWithScanner cancelado no deja archivo seleccionado', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);
    var launcherCalls = 0;

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        onResult: (_) {},
        startWithScanner: true,
        scanDocumentLauncher: (_) async {
          launcherCalls += 1;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(launcherCalls, 1);
    expect(find.text('Seleccionar archivo'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNull,
    );
  }, variant: windowsVariant);

  testWidgets('seleccionar archivo manual habilita subir version sin badge de scan', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        onResult: (_) {},
        pickFileLauncher: (_) async => PlatformFile(
          name: 'version-manual.pdf',
          size: 5,
          bytes: Uint8List.fromList(const [7, 8, 9]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    expect(find.text('version-manual.pdf'), findsOneWidget);
    expect(find.textContaining('PDF escaneado'), findsNothing);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNotNull,
    );
  }, variant: windowsVariant);

  testWidgets('cancelar el picker manual no altera el estado inicial de version', (
    tester,
  ) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(
        sessionViewModel: sessionViewModel,
        onResult: (_) {},
        pickFileLauncher: (_) async => null,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar archivo'), findsOneWidget);
    expect(find.textContaining('.pdf'), findsNothing);
    expect(find.textContaining('PDF escaneado'), findsNothing);
    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Subir versión'),
      ).onPressed,
      isNull,
    );
  }, variant: windowsVariant);
}
