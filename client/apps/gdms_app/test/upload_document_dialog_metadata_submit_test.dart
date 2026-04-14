import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/documents/application/document_upload_view_model.dart';
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

  MockClient buildClientWithSchemas() {
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
              'metadataSchema': {
                'notes': {'label': 'Notas', 'type': 'text', 'required': false},
                'signed': {
                  'label': 'Firmado',
                  'type': 'boolean',
                  'required': false,
                },
              },
            },
            {
              'id': 'type-2',
              'tenantId': 'tenant-1',
              'code': 'MEMO',
              'name': 'Memo',
              'sector': 'ops',
              'isActive': true,
              'metadataSchema': {
                'reference': {
                  'label': 'Referencia',
                  'type': 'text',
                  'required': false,
                },
              },
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not-found', 404);
    });
  }

  Widget buildDialogHarness({
    required AppSessionViewModel sessionViewModel,
    required DocumentUploadViewModel viewModel,
    Future<Object?> Function(BuildContext context)? scanDocumentLauncher,
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
                  scanDocumentLauncher: scanDocumentLauncher == null
                      ? null
                      : (innerContext) async =>
                            await scanDocumentLauncher(innerContext) as dynamic,
                ),
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets(
    'submit convierte titulo y metadatos tipados en metadataJson',
    (tester) async {
      final sessionViewModel = await buildSignedInSession(
        buildClientWithSchemas(),
      );
      addTearDown(sessionViewModel.dispose);

      Map<String, String>? capturedFields;

      final viewModel = DocumentUploadViewModel(
        sessionViewModel.apiClient,
        sessionViewModel,
        multipartUploader:
            ({
              required path,
              required fields,
              required fileFieldName,
              required bytes,
              required fileName,
            }) async {
              capturedFields = fields;
              return {'id': 'doc-1'};
            },
      );

      await tester.pumpWidget(
        buildDialogHarness(
          sessionViewModel: sessionViewModel,
          viewModel: viewModel,
          scanDocumentLauncher: (_) async => const ScannedDocumentFile(
            fileName: 'contrato.pdf',
            bytes: [1, 2, 3, 4],
            pageCount: 1,
            sessionId: 'session-meta-1',
            scannerName: 'Canon DR',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Contrato marco',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        '  Observacion  ',
      );

      final booleanDropdown = tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .last;
      booleanDropdown.onChanged?.call('true');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Escanear documento'));
      await tester.tap(find.text('Escanear documento'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Subir'));
      await tester.tap(find.widgetWithText(FilledButton, 'Subir'));
      await tester.pumpAndSettle();

      expect(capturedFields, {
        'documentTypeCode': 'LEASE',
        'title': 'Contrato marco',
        'metadataJson': jsonEncode({'notes': 'Observacion', 'signed': true}),
      });
    },
    variant: windowsVariant,
  );

  testWidgets(
    'cambiar de tipo documental limpia metadatos anteriores',
    (tester) async {
      final sessionViewModel = await buildSignedInSession(
        buildClientWithSchemas(),
      );
      addTearDown(sessionViewModel.dispose);

      final viewModel = DocumentUploadViewModel(
        sessionViewModel.apiClient,
        sessionViewModel,
        multipartUploader:
            ({
              required path,
              required fields,
              required fileFieldName,
              required bytes,
              required fileName,
            }) async => {'id': 'doc-1'},
      );

      await tester.pumpWidget(
        buildDialogHarness(
          sessionViewModel: sessionViewModel,
          viewModel: viewModel,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notas'), findsOneWidget);
      expect(find.text('Firmado'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, 'Texto previo');

      final typeDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first,
      );
      typeDropdown.onChanged?.call('MEMO');
      await tester.pumpAndSettle();

      expect(find.text('Notas'), findsNothing);
      expect(find.text('Firmado'), findsNothing);
      expect(find.text('Referencia'), findsOneWidget);
      expect(find.text('Texto previo'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
    variant: windowsVariant,
  );
}
