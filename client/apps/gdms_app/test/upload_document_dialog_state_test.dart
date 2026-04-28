import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
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

  MockClient buildClient({bool withActiveTypes = true}) {
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
          jsonEncode(
            withActiveTypes
                ? [
                    {
                      'id': 'type-1',
                      'tenantId': 'tenant-1',
                      'code': 'LEASE',
                      'name': 'Contrato',
                      'sector': 'legal',
                      'isActive': true,
                      'metadataSchema': {},
                    },
                  ]
                : const [],
          ),
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
                builder: (_) => UploadDocumentDialog(
                  apiClient: sessionViewModel.apiClient,
                  sessionViewModel: sessionViewModel,
                  onUploaded: () async {},
                  startWithScanner: startWithScanner,
                  scanDocumentLauncher: scanDocumentLauncher == null
                      ? null
                      : (innerContext) async =>
                            await scanDocumentLauncher(innerContext) as dynamic,
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

  testWidgets('cancelar cierra el dialogo de upload', (tester) async {
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

    expect(find.text('Subir documento'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(dialogResult, isNull);
    expect(find.byType(UploadDocumentDialog), findsNothing);
  }, variant: windowsVariant);

  testWidgets('subir sin archivo muestra validacion visible', (tester) async {
    final client = buildClient();
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(sessionViewModel: sessionViewModel, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Subir'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona un archivo antes de subir.'), findsOneWidget);
    expect(find.byType(UploadDocumentDialog), findsOneWidget);
  }, variant: windowsVariant);

  testWidgets('sin tipos activos exige seleccionar tipo documental', (
    tester,
  ) async {
    final client = buildClient(withActiveTypes: false);
    final sessionViewModel = await buildSignedInSession(client);

    addTearDown(sessionViewModel.dispose);

    await tester.pumpWidget(
      buildDialogHarness(sessionViewModel: sessionViewModel, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No hay tipos documentales activos para esta organización.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Subir'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona el tipo documental.'), findsOneWidget);
  }, variant: windowsVariant);

  testWidgets('cancelar el scanner no selecciona archivo ni badge', (
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
  }, variant: windowsVariant);

  testWidgets(
    'seleccionar archivo manual autocompleta titulo y no muestra badge de scan',
    (tester) async {
      final client = buildClient();
      final sessionViewModel = await buildSignedInSession(client);

      addTearDown(sessionViewModel.dispose);

      await tester.pumpWidget(
        buildDialogHarness(
          sessionViewModel: sessionViewModel,
          onResult: (_) {},
          pickFileLauncher: (_) async => PlatformFile(
            name: 'contrato-manual.pdf',
            size: 7,
            bytes: Uint8List.fromList(const [1, 2, 3]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar archivo'));
      await tester.pumpAndSettle();

      expect(find.text('contrato-manual.pdf'), findsOneWidget);
      expect(find.textContaining('PDF escaneado'), findsNothing);
      expect(find.text('contrato-manual'), findsOneWidget);
    },
    variant: windowsVariant,
  );

  testWidgets(
    'seleccionar archivo manual no pisa un titulo ya editado',
    (tester) async {
      final client = buildClient();
      final sessionViewModel = await buildSignedInSession(client);

      addTearDown(sessionViewModel.dispose);

      await tester.pumpWidget(
        buildDialogHarness(
          sessionViewModel: sessionViewModel,
          onResult: (_) {},
          pickFileLauncher: (_) async => PlatformFile(
            name: 'anexo.pdf',
            size: 3,
            bytes: Uint8List.fromList(const [4, 5, 6]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Titulo manual');
      await tester.tap(find.text('Seleccionar archivo'));
      await tester.pumpAndSettle();

      expect(find.text('anexo.pdf'), findsOneWidget);
      expect(find.text('Titulo manual'), findsOneWidget);
      expect(find.text('anexo'), findsNothing);
    },
    variant: windowsVariant,
  );
}
