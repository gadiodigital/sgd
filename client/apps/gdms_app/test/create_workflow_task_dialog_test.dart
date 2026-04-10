import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/workflow/presentation/create_workflow_task_dialog.dart';

void main() {
  testWidgets(
    'valida fecha y crea tarea con payload normalizado',
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

          if (path == '/api/tenants/tenant-1/users') {
            return http.Response(
              jsonEncode([
                {'id': 'user-2', 'fullName': 'Revisor Legal'},
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (path == '/api/tenants/tenant-1/workflow/tasks') {
            capturedRequestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({'id': 'task-1'}),
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

      var createdCalls = 0;
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
                      builder: (_) => CreateWorkflowTaskDialog(
                        apiClient: sessionViewModel.apiClient,
                        sessionViewModel: sessionViewModel,
                        initialDocumentId: 'doc-1',
                        onCreated: () async => createdCalls++,
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
        find.widgetWithText(TextFormField, 'Título de la tarea'),
        '  Aprobar contrato  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vencimiento (AAAA-MM-DD)'),
        '2026/04/10',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.pumpAndSettle();

      expect(find.text('Usá formato AAAA-MM-DD.'), findsOneWidget);
      expect(find.byType(CreateWorkflowTaskDialog), findsOneWidget);
      expect(capturedRequestBody, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notas'),
        '  Revisar antes del cierre  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vencimiento (AAAA-MM-DD)'),
        '2026-04-10',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateWorkflowTaskDialog), findsNothing);
      expect(createdCalls, 1);
      expect(capturedRequestBody, isNotNull);
      expect(capturedRequestBody!['documentId'], 'doc-1');
      expect(capturedRequestBody!['title'], 'Aprobar contrato');
      expect(capturedRequestBody!['notes'], 'Revisar antes del cierre');
      expect(capturedRequestBody!['assignedToUserId'], isNull);
      expect(capturedRequestBody!['dueAtUtc'], '2026-04-10T00:00:00Z');
    },
  );
}
