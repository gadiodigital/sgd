import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/structure/application/document_structure_view_model.dart';
import 'package:gdms_app/src/structure/presentation/document_structure_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<AppSessionViewModel> buildSignedInSession(MockClient client) async {
    final sessionViewModel = AppSessionViewModel(httpClient: client);
    final signedIn = await sessionViewModel.signIn(
      tenantCode: 'tenant-ar',
      email: 'operator@tenant.ar',
      password: 'Password!23',
    );
    expect(signedIn, isTrue);
    return sessionViewModel;
  }

  testWidgets('muestra jerarquia y vincula documento existente al nodo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var linked = false;
    Map<String, dynamic>? attachBody;

    final client = MockClient((request) async {
      final path = request.url.path;

      if (path == '/api/auth/token') {
        return _json({
          'accessToken': 'token-dev',
          'tokenType': 'Bearer',
          'expiresAtUtc': DateTime.utc(2026, 4, 14).toIso8601String(),
          'expiresInSeconds': 3600,
          'mustChangePassword': false,
          'userId': 'user-1',
          'email': 'operator@tenant.ar',
          'fullName': 'Operador Tenant',
          'roles': ['DOCUMENT_OPERATOR'],
          'tenantId': 'tenant-1',
          'tenantCode': 'tenant-ar',
          'tenantName': 'Tenant AR',
        });
      }

      if (path == '/api/auth/me') {
        return _json({
          'userId': 'user-1',
          'tenantId': 'tenant-1',
          'tenantCode': 'tenant-ar',
          'email': 'operator@tenant.ar',
          'fullName': 'Operador Tenant',
          'roles': ['DOCUMENT_OPERATOR'],
        });
      }

      if (path == '/api/tenants/tenant-1/structure/projects') {
        return _json([
          {
            'id': 'project-1',
            'code': 'ARCHIVO',
            'name': 'Archivo central',
            'description': 'Archivo documental',
            'status': 'Active',
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/container-types') {
        return _json([
          {
            'id': 'type-root',
            'code': 'CAJA',
            'name': 'Caja',
            'iconKey': 'inventory_2',
            'isRootAllowed': true,
            'acceptsDocuments': false,
            'metadataSchema': {},
          },
          {
            'id': 'type-folder',
            'code': 'CARPETA',
            'name': 'Carpeta',
            'iconKey': 'folder',
            'isRootAllowed': false,
            'acceptsDocuments': true,
            'metadataSchema': {},
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/container-type-rules') {
        return _json([
          {
            'id': 'rule-1',
            'parentContainerTypeId': 'type-root',
            'childContainerTypeId': 'type-folder',
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/containers') {
        return _json([
          {
            'id': 'container-root',
            'containerTypeId': 'type-root',
            'parentContainerId': null,
            'code': 'CAJA-001',
            'name': 'Caja 001',
            'metadata': {},
          },
          {
            'id': 'container-folder',
            'containerTypeId': 'type-folder',
            'parentContainerId': 'container-root',
            'code': 'CARPETA-001',
            'name': 'Carpeta 001',
            'metadata': {},
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/containers/container-folder/documents') {
        if (request.method == 'POST') {
          attachBody = jsonDecode(request.body) as Map<String, dynamic>;
          linked = true;
          return http.Response('', 204);
        }

        return _json(
          linked
              ? [
                  {
                    'documentId': 'doc-1',
                    'documentTitle': 'Contrato marco',
                    'documentTypeCode': 'CONTRACT',
                    'documentStatus': 'ACTIVE',
                  },
                ]
              : <Map<String, dynamic>>[],
        );
      }

      if (path == '/api/tenants/tenant-1/documents') {
        return _json([
          {
            'id': 'doc-1',
            'title': 'Contrato marco',
            'documentTypeCode': 'CONTRACT',
            'status': 'ACTIVE',
            'createdAtUtc': DateTime.utc(2026, 4, 14).toIso8601String(),
          },
        ]);
      }

      throw StateError('Ruta no mockeada: ${request.method} $path');
    });

    final sessionViewModel = await buildSignedInSession(client);
    addTearDown(sessionViewModel.dispose);
    final viewModel = DocumentStructureViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: DocumentStructurePage(
            viewModel: viewModel,
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estructura documental'), findsOneWidget);
    expect(find.text('CAJA-001 - Caja 001'), findsOneWidget);
    expect(find.text('CARPETA-001 - Carpeta 001'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Subir al nodo'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('CARPETA-001 - Carpeta 001'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Subir al nodo'),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Escanear al nodo'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Vincular doc'));
    await tester.pumpAndSettle();

    expect(find.text('Vincular documento'), findsOneWidget);
    expect(find.text('Contrato marco - CONTRACT'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Vincular'));
    await tester.pumpAndSettle();

    expect(attachBody, {'documentId': 'doc-1'});
    expect(find.text('Vincular documento'), findsNothing);
    expect(find.text('Contrato marco'), findsOneWidget);
    expect(find.text('Documento vinculado al nodo.'), findsOneWidget);
  });

  testWidgets('mantiene modal abierto cuando la API rechaza la operacion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      final path = request.url.path;

      if (path == '/api/auth/token') {
        return _json({
          'accessToken': 'token-dev',
          'tokenType': 'Bearer',
          'expiresAtUtc': DateTime.utc(2026, 4, 14).toIso8601String(),
          'expiresInSeconds': 3600,
          'mustChangePassword': false,
          'userId': 'user-1',
          'email': 'operator@tenant.ar',
          'fullName': 'Operador Tenant',
          'roles': ['DOCUMENT_OPERATOR'],
          'tenantId': 'tenant-1',
          'tenantCode': 'tenant-ar',
          'tenantName': 'Tenant AR',
        });
      }

      if (path == '/api/auth/me') {
        return _json({
          'userId': 'user-1',
          'tenantId': 'tenant-1',
          'tenantCode': 'tenant-ar',
          'email': 'operator@tenant.ar',
          'fullName': 'Operador Tenant',
          'roles': ['DOCUMENT_OPERATOR'],
        });
      }

      if (path == '/api/tenants/tenant-1/structure/projects') {
        if (request.method == 'POST') {
          return _json({'detail': 'El codigo ya existe.'}, statusCode: 400);
        }

        return _json([]);
      }

      throw StateError('Ruta no mockeada: ${request.method} $path');
    });

    final sessionViewModel = await buildSignedInSession(client);
    addTearDown(sessionViewModel.dispose);
    final viewModel = DocumentStructureViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: DocumentStructurePage(
            viewModel: viewModel,
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Proyecto'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Codigo'),
      'ARCHIVO',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Archivo central',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Crear proyecto documental'), findsOneWidget);
    expect(find.text('El codigo ya existe.'), findsWidgets);
  });

  testWidgets('crea nodo con atributos generados desde el esquema del tipo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? capturedCreateNodeBody;
    var nodeCreated = false;

    final client = MockClient((request) async {
      final path = request.url.path;

      if (path == '/api/auth/token') {
        return _json({
          'accessToken': 'token-dev',
          'tokenType': 'Bearer',
          'expiresAtUtc': DateTime.utc(2026, 4, 14).toIso8601String(),
          'expiresInSeconds': 3600,
          'mustChangePassword': false,
          'userId': 'user-1',
          'email': 'operator@tenant.ar',
          'fullName': 'Operador Tenant',
          'roles': ['DOCUMENT_OPERATOR'],
          'tenantId': 'tenant-1',
          'tenantCode': 'tenant-ar',
          'tenantName': 'Tenant AR',
        });
      }

      if (path == '/api/auth/me') {
        return _json({
          'userId': 'user-1',
          'tenantId': 'tenant-1',
          'tenantCode': 'tenant-ar',
          'email': 'operator@tenant.ar',
          'fullName': 'Operador Tenant',
          'roles': ['DOCUMENT_OPERATOR'],
        });
      }

      if (path == '/api/tenants/tenant-1/structure/projects') {
        return _json([
          {
            'id': 'project-1',
            'code': 'ARCHIVO',
            'name': 'Archivo central',
            'description': null,
            'status': 'Active',
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/container-types') {
        return _json([
          {
            'id': 'type-box',
            'code': 'CAJA',
            'name': 'Caja',
            'iconKey': 'inventory_2',
            'isRootAllowed': true,
            'acceptsDocuments': false,
            'metadataSchema': {
              'boxNumber': {
                'label': 'Numero de caja',
                'type': 'string',
                'required': true,
                'maxLength': 20,
              },
              'classification': {
                'label': 'Clasificacion',
                'type': 'list',
                'required': true,
                'options': ['PUBLICO', 'RESERVADO'],
              },
              'extra': {
                'label': 'Datos extra',
                'type': 'json',
                'required': false,
              },
              'archived': {
                'label': 'Archivado',
                'type': 'boolean',
                'required': false,
              },
            },
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/container-type-rules') {
        return _json([]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/containers') {
        if (request.method == 'POST') {
          capturedCreateNodeBody =
              jsonDecode(request.body) as Map<String, dynamic>;
          nodeCreated = true;
          return _json({
            'id': 'container-box',
            'containerTypeId': 'type-box',
            'parentContainerId': null,
            'code': 'CAJA-001',
            'name': 'Caja 001',
            'metadata': capturedCreateNodeBody?['metadata'] ?? {},
          });
        }

        return _json(
          nodeCreated
              ? [
                  {
                    'id': 'container-box',
                    'containerTypeId': 'type-box',
                    'parentContainerId': null,
                    'code': 'CAJA-001',
                    'name': 'Caja 001',
                    'metadata': capturedCreateNodeBody?['metadata'] ?? {},
                  },
                ]
              : <Map<String, dynamic>>[],
        );
      }

      throw StateError('Ruta no mockeada: ${request.method} $path');
    });

    final sessionViewModel = await buildSignedInSession(client);
    addTearDown(sessionViewModel.dispose);
    final viewModel = DocumentStructureViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: DocumentStructurePage(
            viewModel: viewModel,
            apiClient: sessionViewModel.apiClient,
            sessionViewModel: sessionViewModel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Nodo'));
    await tester.pumpAndSettle();

    expect(find.text('Atributos del nodo'), findsOneWidget);
    expect(find.text('Numero de caja'), findsOneWidget);
    expect(find.text('Clasificacion'), findsOneWidget);
    expect(find.text('Datos extra'), findsOneWidget);
    expect(find.text('Archivado'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Codigo'),
      'CAJA-001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Caja 001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numero de caja'),
      '  001  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Datos extra'),
      '{"folios":3}',
    );

    final dropdowns = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .toList(growable: false);
    dropdowns[dropdowns.length - 2].onChanged?.call('RESERVADO');
    dropdowns.last.onChanged?.call('true');
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Guardar');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(capturedCreateNodeBody, isNotNull);
    expect(capturedCreateNodeBody!['metadata'], {
      'boxNumber': '001',
      'classification': 'RESERVADO',
      'extra': {'folios': 3},
      'archived': true,
    });
    expect(find.text('Crear nodo jerarquico'), findsNothing);
    expect(find.text('CAJA-001 - Caja 001'), findsOneWidget);
  });
}

http.Response _json(Object value, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(value),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
