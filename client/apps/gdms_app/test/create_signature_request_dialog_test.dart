import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/signature/application/create_signature_request_view_model.dart';
import 'package:gdms_app/src/signature/presentation/create_signature_request_dialog.dart';

void main() {
  testWidgets(
    'valida email real y envia valores normalizados al crear solicitud',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? capturedRequestBody;
      final sessionViewModel = AppSessionViewModel(
        httpClient: MockClient((request) async {
          final path = request.url.path;

          if (path == '/api/auth/token') {
            return http.Response(
              jsonEncode({
                'accessToken': 'token-dev',
                'tokenType': 'Bearer',
                'expiresAtUtc': DateTime.utc(2026, 4, 11).toIso8601String(),
                'expiresInSeconds': 3600,
                'mustChangePassword': false,
                'userId': 'user-1',
                'email': 'admin@tenant.ar',
                'fullName': 'Admin Tenant',
                'roles': ['TENANT_ADMIN'],
                'tenantId': 'tenant-1',
                'tenantCode': 'tenant-ar',
                'tenantName': 'Tenant AR',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (path == '/api/auth/me') {
            return http.Response(
              jsonEncode({
                'userId': 'user-1',
                'tenantId': 'tenant-1',
                'tenantCode': 'tenant-ar',
                'email': 'admin@tenant.ar',
                'fullName': 'Admin Tenant',
                'roles': ['TENANT_ADMIN'],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (path == '/api/tenants/tenant-1/documents') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'doc-1',
                  'title': 'Contrato marco',
                  'documentTypeCode': 'CONTRACT',
                  'status': 'ACTIVE',
                  'createdAtUtc': DateTime.utc(2026, 4, 10).toIso8601String(),
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (path == '/api/tenants/tenant-1/records/disposition-candidates') {
            return http.Response(
              jsonEncode(const []),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (path == '/api/tenants/tenant-1/signature/envelopes') {
            capturedRequestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({'id': 'sig-1'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          throw StateError('Ruta no mockeada: ${request.method} $path');
        }),
      );

      final signedIn = await sessionViewModel.signIn(
        tenantCode: 'tenant-ar',
        email: 'admin@tenant.ar',
        password: 'Password!23',
      );
      expect(signedIn, isTrue);

      final viewModel = CreateSignatureRequestViewModel(
        sessionViewModel: sessionViewModel,
      );
      var dialogOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                if (!dialogOpened) {
                  dialogOpened = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<bool>(
                      context: context,
                      builder: (_) => CreateSignatureRequestDialog(
                        viewModel: viewModel,
                        initialDocumentId: 'doc-1',
                        initialDocumentTitle: 'Contrato marco',
                      ),
                    );
                  });
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Firmante'),
        '  Juan Perez  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email del firmante'),
        'juan@@tenant',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear solicitud'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un email válido.'), findsOneWidget);
      expect(find.byType(CreateSignatureRequestDialog), findsOneWidget);
      expect(capturedRequestBody, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email del firmante'),
        '  juan@tenant.ar  ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear solicitud'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateSignatureRequestDialog), findsNothing);
      expect(capturedRequestBody, isNotNull);
      expect(capturedRequestBody!['documentId'], 'doc-1');
      expect(capturedRequestBody!['signerDisplayName'], 'Juan Perez');
      expect(capturedRequestBody!['signerEmail'], 'juan@tenant.ar');
      expect(capturedRequestBody!['signatureLevel'], 'ELECTRONIC');
    },
  );
}
