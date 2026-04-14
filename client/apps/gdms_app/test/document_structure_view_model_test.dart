import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/auth/application/app_session_view_model.dart';
import 'package:gdms_app/src/structure/application/document_structure_view_model.dart';
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

  test('carga estructura, selecciona nodo y vincula documento', () async {
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

      throw StateError('Ruta no mockeada: ${request.method} $path');
    });

    final sessionViewModel = await buildSignedInSession(client);
    addTearDown(sessionViewModel.dispose);
    final viewModel = DocumentStructureViewModel(
      sessionViewModel.apiClient,
      sessionViewModel,
    );

    await viewModel.load();

    expect(viewModel.projects.single.code, 'ARCHIVO');
    expect(viewModel.containerTypes, hasLength(2));
    expect(viewModel.rules.single.childContainerTypeId, 'type-folder');
    expect(viewModel.containers, hasLength(2));
    expect(viewModel.message, 'Estructura documental cargada.');

    await viewModel.selectContainer('container-folder');

    expect(viewModel.selectedContainer?.code, 'CARPETA-001');
    expect(viewModel.selectedContainerDocuments, isEmpty);
    expect(
      viewModel.containerAcceptsDocuments(viewModel.selectedContainer),
      isTrue,
    );

    final attached = await viewModel.attachDocument('doc-1');

    expect(attached, isTrue);
    expect(attachBody, {'documentId': 'doc-1'});
    expect(
      viewModel.selectedContainerDocuments.single.documentTitle,
      'Contrato marco',
    );
    expect(viewModel.message, 'Documento vinculado al nodo.');
  });

  test('informa error cuando el JSON de atributos es invalido', () async {
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
            'id': 'type-root',
            'code': 'CAJA',
            'name': 'Caja',
            'iconKey': 'folder',
            'isRootAllowed': true,
            'acceptsDocuments': false,
            'metadataSchema': {},
          },
        ]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/container-type-rules') {
        return _json([]);
      }

      if (path ==
          '/api/tenants/tenant-1/structure/projects/project-1/containers') {
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

    await viewModel.load();
    await viewModel.createContainer(
      containerTypeId: 'type-root',
      code: 'CAJA-001',
      name: 'Caja 001',
      metadataJson: '{invalido',
    );

    expect(viewModel.message, 'El JSON ingresado no tiene un formato válido.');
  });
}

http.Response _json(Object value, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(value),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
