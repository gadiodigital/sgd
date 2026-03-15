import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_sgd/main.dart';
import 'package:ui_sgd/sgd_api_client.dart';

void main() {
  testWidgets('renderiza la pantalla de jerarquia sin errores', (tester) async {
    await tester.pumpWidget(UiSgdApp(api: _FakeSgdApiClient.withHierarchy()));
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.tap(find.text('Jerarquía').first);
    await tester.pumpAndSettle();

    expect(find.text('Jerarquía documental'), findsOneWidget);
    expect(find.text('Caja 001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la validacion del proyecto mantiene abierto el dialogo', (tester) async {
    await tester.pumpWidget(UiSgdApp(api: _FakeSgdApiClient.empty()));
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.tap(find.text('Nuevo proyecto').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Proyecto Demo');
    await tester.enterText(find.widgetWithText(TextFormField, 'Slug'), 'Slug Invalido');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();

    expect(find.text('Usa minúsculas, números y guiones.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
    expect(find.text('Proyecto Demo'), findsOneWidget);
  });

  testWidgets('muestra tipos aunque el snapshot llegue con claves en minuscula', (tester) async {
    await tester.pumpWidget(UiSgdApp(api: _FakeSgdApiClient.withLowercaseTypeKeys()));
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.tap(find.text('Tipos').first);
    await tester.pumpAndSettle();

    expect(find.text('Bibliorato visible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('jerarquia muestra atributos sin valor cuando el tipo los define despues', (tester) async {
    await tester.pumpWidget(UiSgdApp(api: _FakeSgdApiClient.withMissingNodeAttributeValues()));
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.tap(find.text('Jerarquía').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('1 sin valor'), findsOneWidget);
    expect(find.text('Fecha de cierre: Sin valor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
  await tester.pumpAndSettle();
}

class _FakeSgdApiClient extends SgdApiClient {
  _FakeSgdApiClient._({
    required this.projects,
    required this.snapshots,
  }) : super(baseUrl: 'http://fake.local');

  factory _FakeSgdApiClient.empty() => _FakeSgdApiClient._(
        projects: const [],
        snapshots: const {},
      );

  factory _FakeSgdApiClient.withHierarchy() => _FakeSgdApiClient._(
        projects: const [
          {
            'id': 'project-1',
            'name': 'Estudio Central',
            'slug': 'estudio-central',
            'description': 'Proyecto demo',
          },
        ],
        snapshots: const {
          'project-1': {
            'projectId': 'project-1',
            'types': [
              {
                'id': 'type-caja',
                'projectId': 'project-1',
                'code': 'caja',
                'name': 'Caja',
                'description': '',
                'root': true,
                'acceptsDocs': false,
                'iconKey': 'inventory_2',
                'order': 10,
                'attributes': [],
              },
              {
                'id': 'type-carpeta',
                'projectId': 'project-1',
                'code': 'carpeta',
                'name': 'Carpeta',
                'description': '',
                'root': false,
                'acceptsDocs': true,
                'iconKey': 'folder',
                'order': 20,
                'attributes': [
                  {
                    'id': 'attr-estado',
                    'name': 'Estado',
                    'code': 'estado',
                    'dataType': 'list',
                    'extension': '',
                    'regex': '',
                    'options': [
                      {
                        'id': 'op-vigente',
                        'code': 'vigente',
                        'label': 'Vigente',
                      },
                    ],
                  },
                ],
              },
            ],
            'rules': [
              {
                'id': 'type-caja|type-carpeta',
                'projectId': 'project-1',
                'parentTypeId': 'type-caja',
                'childTypeId': 'type-carpeta',
              },
            ],
            'nodes': [
              {
                'id': 'node-1',
                'projectId': 'project-1',
                'typeId': 'type-caja',
                'parentId': null,
                'code': 'CAJA-001',
                'name': 'Caja 001',
                'description': '',
                'depth': 0,
                'order': 10,
                'values': {},
              },
              {
                'id': 'node-2',
                'projectId': 'project-1',
                'typeId': 'type-carpeta',
                'parentId': 'node-1',
                'code': 'CARP-001',
                'name': 'Contratos',
                'description': '',
                'depth': 1,
                'order': 10,
                'values': {'attr-estado': 'vigente'},
              },
            ],
          },
        },
      );

  factory _FakeSgdApiClient.withLowercaseTypeKeys() => _FakeSgdApiClient._(
        projects: const [
          {
            'id': 'project-lower',
            'name': 'Proyecto Lower',
            'slug': 'proyecto-lower',
            'description': 'Snapshot con claves en minuscula',
          },
        ],
        snapshots: const {
          'project-lower': {
            'projectId': 'project-lower',
            'types': [
              {
                'id': 'type-visible',
                'projectid': 'project-lower',
                'code': 'bib',
                'name': 'Bibliorato visible',
                'description': '',
                'root': true,
                'acceptsdocs': false,
                'iconkey': 'inventory_2',
                'order': 10,
                'attributes': [],
              },
            ],
            'rules': [],
            'nodes': [],
          },
        },
      );

  factory _FakeSgdApiClient.withMissingNodeAttributeValues() => _FakeSgdApiClient._(
        projects: const [
          {
            'id': 'project-missing-attrs',
            'name': 'Proyecto Atributos',
            'slug': 'proyecto-atributos',
            'description': 'Nodos creados antes que sus atributos',
          },
        ],
        snapshots: const {
          'project-missing-attrs': {
            'projectId': 'project-missing-attrs',
            'types': [
              {
                'id': 'type-expediente',
                'projectId': 'project-missing-attrs',
                'code': 'exp',
                'name': 'Expediente',
                'description': '',
                'root': true,
                'acceptsDocs': true,
                'iconKey': 'folder',
                'order': 10,
                'attributes': [
                  {
                    'id': 'attr-fecha-cierre',
                    'name': 'Fecha de cierre',
                    'code': 'fecha_cierre',
                    'dataType': 'date',
                    'extension': '',
                    'regex': '',
                    'options': [],
                  },
                ],
              },
            ],
            'rules': [],
            'nodes': [
              {
                'id': 'node-expediente-1',
                'projectId': 'project-missing-attrs',
                'typeId': 'type-expediente',
                'parentId': null,
                'code': 'EXP-001',
                'name': 'Expediente 001',
                'description': '',
                'depth': 0,
                'order': 10,
                'values': {},
              },
            ],
          },
        },
      );

  final List<Map<String, dynamic>> projects;
  final Map<String, Map<String, dynamic>> snapshots;

  Map<String, dynamic> _sessionPayload() => {
        'user': const {
          'id': 'user-admin',
          'displayName': 'Administrador local',
          'email': 'admin@local.test',
          'loginName': 'admin',
          'isPlatformAdmin': true,
        },
        'memberships': projects
            .map((project) => {
                  'projectId': project['id'],
                  'profileId': 'profile-admin',
                  'profileCode': 'admin',
                  'profileName': 'Administrador del proyecto',
                  'permissionCodes': const [
                    'project.read',
                    'project.write',
                    'types.read',
                    'types.write',
                    'hierarchy.read',
                    'hierarchy.write',
                    'security.read',
                    'security.write',
                  ],
                })
            .toList(),
        'allPermissions': const [
          'project.read',
          'project.write',
          'types.read',
          'types.write',
          'hierarchy.read',
          'hierarchy.write',
          'security.read',
          'security.write',
        ],
      };

  @override
  Future<Map<String, dynamic>> login({
    required String loginName,
    required String password,
  }) async =>
      {
        'token': 'fake-token',
        ..._sessionPayload(),
      };

  @override
  Future<Map<String, dynamic>> fetchMe() async => _sessionPayload();

  @override
  Future<List<Map<String, dynamic>>> listProjects() async => projects;

  @override
  Future<Map<String, dynamic>> fetchProjectSnapshot(String projectId) async => snapshots[projectId]!;
}
