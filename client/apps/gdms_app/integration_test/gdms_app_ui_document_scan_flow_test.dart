import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/app/gdms_app.dart';
import 'package:integration_test/integration_test.dart';

const _apiBaseUrl = String.fromEnvironment(
  'GDMS_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5015',
);
const _windowsTwainBaseUrl = String.fromEnvironment(
  'WINDOWS_TWAIN_BASE_URL',
  defaultValue: 'http://127.0.0.1:43127',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGdmsApiServer apiServer;
  late _FakeWindowsTwainServer scanServer;

  setUpAll(() async {
    apiServer = _FakeGdmsApiServer(Uri.parse(_apiBaseUrl));
    scanServer = _FakeWindowsTwainServer(Uri.parse(_windowsTwainBaseUrl));

    await apiServer.start();
    await scanServer.start();
  });

  tearDownAll(() async {
    await apiServer.stop();
    await scanServer.stop();
  });

  testWidgets(
    'bootstrap de administrador de organización navega a documentos escanea y sube un documento',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GdmsApp());
      await _pumpUntilFound(tester, find.text('Ingreso al GDMS'));

      await tester.tap(find.text('Organización admin'));
      await tester.pump(const Duration(milliseconds: 300));

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(5));

      await tester.enterText(fields.at(0), _apiBaseUrl);
      await tester.enterText(fields.at(1), 'SCAN-DEMO');
      await tester.enterText(fields.at(2), 'scan.demo.admin@tenant.ar');
      await tester.enterText(fields.at(3), 'Scan Demo Admin');
      await tester.enterText(fields.at(4), 'ScanDemo123!');

      await tester.tap(find.text('Crear administrador de organización'));
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Documentos'));
      await tester.tap(find.text('Documentos').last);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Repositorio documental'));
      await tester.tap(find.text('Escanear documento').first);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Escanear documento'));
      await _pumpUntilFound(
        tester,
        find.text('Selecciona el escaner y dispara el escaneo.'),
      );

      final scanButton = find.widgetWithText(FilledButton, 'Escanear');
      await tester.ensureVisible(scanButton);
      await tester.tap(scanButton);
      await tester.pump(const Duration(milliseconds: 300));

      await _pumpUntilFound(
        tester,
        find.text('Escaneo ADF completado con 2 pagina(s).'),
      );
      final useScanButton = find.widgetWithText(FilledButton, 'Usar escaneo');
      await tester.ensureVisible(useScanButton);
      await tester.tap(useScanButton);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Subir documento'));
      expect(
        find.text('PDF escaneado desde Canon DR-Mock con 2 pagina(s).'),
        findsOneWidget,
      );
      expect(find.text('scan-ui-flow'), findsOneWidget);

      final uploadButton = find.widgetWithText(FilledButton, 'Subir');
      await tester.ensureVisible(uploadButton);
      await tester.tap(uploadButton);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilGone(tester, find.byType(Dialog));
      await _pumpUntilFound(tester, find.text('scan-ui-flow'));

      expect(apiServer.uploadCount, 1);
      expect(
        apiServer.documents.any(
          (document) => document['title'] == 'scan-ui-flow',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'recupera windows-twain cuando el host vuelve y se redescubren escaneres',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await scanServer.stop();

      try {
        await tester.pumpWidget(const GdmsApp());
        await _pumpUntilFound(tester, find.text('Ingreso al GDMS'));

        await tester.tap(find.text('Organización admin'));
        await tester.pump(const Duration(milliseconds: 300));

        final fields = find.byType(TextFormField);
        expect(fields, findsNWidgets(5));

        await tester.enterText(fields.at(0), _apiBaseUrl);
        await tester.enterText(fields.at(1), 'SCAN-DEMO');
        await tester.enterText(fields.at(2), 'scan.demo.admin@tenant.ar');
        await tester.enterText(fields.at(3), 'Scan Demo Admin');
        await tester.enterText(fields.at(4), 'ScanDemo123!');

        await tester.tap(find.text('Crear administrador de organización'));
        await tester.pump(const Duration(milliseconds: 500));

        await _pumpUntilFound(tester, find.text('Documentos'));
        await tester.tap(find.text('Documentos').last);
        await tester.pump(const Duration(milliseconds: 500));

        await _pumpUntilFound(tester, find.text('Repositorio documental'));
        await tester.tap(find.text('Escanear documento').first);
        await tester.pump(const Duration(milliseconds: 500));

        await _pumpUntilFound(tester, find.text('Escanear documento'));
        await _pumpUntilFound(
          tester,
          find.text('Servicio no disponible en $_windowsTwainBaseUrl'),
        );

        await scanServer.start();
        final refreshButton = find.byTooltip('Redescubrir escaneres');
        await tester.ensureVisible(refreshButton);
        await tester.tap(refreshButton);
        await tester.pump(const Duration(milliseconds: 300));

        await _pumpUntilFound(
          tester,
          find.text('Selecciona el escaner y dispara el escaneo.'),
        );
      } finally {
        try {
          await scanServer.start();
        } on SocketException {
          // El host ya estaba arriba despues de la recuperacion.
        }
      }
    },
  );

  testWidgets(
    'reanuda una sesion rehidratada visible en el host y la sube al backend',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      scanServer.upsertSession(
        sessionId: 'rehydrated-session',
        scannerName: 'Canon DR-Mock',
        pageCount: 3,
        mode: 'adf-duplex',
        status: 'completed',
        isRehydrated: true,
      );

      final previousUploadCount = apiServer.uploadCount;

      await tester.pumpWidget(const GdmsApp());
      await _pumpUntilFound(tester, find.text('Ingreso al GDMS'));

      await tester.tap(find.text('Organización admin'));
      await tester.pump(const Duration(milliseconds: 300));

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(5));

      await tester.enterText(fields.at(0), _apiBaseUrl);
      await tester.enterText(fields.at(1), 'SCAN-DEMO');
      await tester.enterText(fields.at(2), 'scan.demo.admin@tenant.ar');
      await tester.enterText(fields.at(3), 'Scan Demo Admin');
      await tester.enterText(fields.at(4), 'ScanDemo123!');

      await tester.tap(find.text('Crear administrador de organización'));
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Documentos'));
      await tester.tap(find.text('Documentos').last);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Repositorio documental'));
      await tester.tap(find.text('Escanear documento').first);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Sesiones activas'));
      await _pumpUntilFound(tester, find.text('Rehidratada'));
      await _pumpUntilFound(tester, find.textContaining('rehydrated-session'));

      final resumeButton = find
          .widgetWithText(OutlinedButton, 'Reanudar')
          .first;
      await tester.ensureVisible(resumeButton);
      await tester.tap(resumeButton);
      await tester.pump(const Duration(milliseconds: 300));

      await _pumpUntilFound(
        tester,
        find.text('Sesion rehydrated-session reanudada con 3 pagina(s).'),
      );
      await _pumpUntilFound(tester, find.text('Previsualizacion'));
      expect(find.textContaining('rehydrated-session.pdf'), findsOneWidget);

      final useScanButton = find.widgetWithText(FilledButton, 'Usar escaneo');
      await tester.ensureVisible(useScanButton);
      await tester.tap(useScanButton);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilFound(tester, find.text('Subir documento'));
      expect(
        find.text('PDF escaneado desde Canon DR-Mock con 3 pagina(s).'),
        findsOneWidget,
      );
      expect(find.text('rehydrated-session'), findsOneWidget);

      final uploadButton = find.widgetWithText(FilledButton, 'Subir');
      await tester.ensureVisible(uploadButton);
      await tester.tap(uploadButton);
      await tester.pump(const Duration(milliseconds: 500));

      await _pumpUntilGone(tester, find.byType(Dialog));
      await _pumpUntilFound(tester, find.text('scan-ui-flow'));

      expect(apiServer.uploadCount, previousUploadCount + 1);
    },
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 60,
}) async {
  for (var attempt = 0; attempt < maxSteps; attempt++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('No se encontro el widget esperado: $finder');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 60,
}) async {
  for (var attempt = 0; attempt < maxSteps; attempt++) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }

  throw TestFailure('El widget sigue visible y debio desaparecer: $finder');
}

final class _FakeGdmsApiServer {
  _FakeGdmsApiServer(this._baseUri);

  final Uri _baseUri;
  late HttpServer _server;
  var uploadCount = 0;
  final List<Map<String, Object?>> documents = <Map<String, Object?>>[
    <String, Object?>{
      'id': 'doc-seed-1',
      'title': 'Documento seed',
      'documentTypeCode': 'CONTRACT',
      'status': 'ACTIVE',
      'createdAtUtc': '2026-04-10T18:00:00Z',
    },
  ];

  Future<void> start() async {
    _server = await HttpServer.bind(_baseUri.host, _baseUri.port);
    unawaited(_serve());
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final request in _server) {
      final path = request.uri.path;
      if (request.method == 'POST' &&
          path == '/api/auth/bootstrap-tenant-admin') {
        await _writeJson(request.response, <String, Object?>{
          'accessToken': 'token-123',
          'tokenType': 'Bearer',
          'expiresAtUtc': '2026-04-10T22:00:00Z',
          'expiresInSeconds': 3600,
          'mustChangePassword': false,
          'userId': 'user-1',
          'email': 'scan.demo.admin@tenant.ar',
          'fullName': 'Scan Demo Admin',
          'roles': <String>['TENANT_ADMIN'],
          'tenantId': 'tenant-1',
          'tenantCode': 'SCAN-DEMO',
          'tenantName': 'Scan Demo',
        });
        continue;
      }

      if (request.method == 'GET' && path == '/api/auth/me') {
        await _writeJson(request.response, <String, Object?>{
          'userId': 'user-1',
          'tenantId': 'tenant-1',
          'tenantCode': 'SCAN-DEMO',
          'email': 'scan.demo.admin@tenant.ar',
          'fullName': 'Scan Demo Admin',
          'roles': <String>['TENANT_ADMIN'],
        });
        continue;
      }

      if (request.method == 'GET' && path == '/api/organization/current') {
        await _writeJson(request.response, <String, Object?>{
          'id': 'tenant-1',
          'code': 'SCAN-DEMO',
          'name': 'Scan Demo',
          'sector': 'CORPORATE',
          'primaryCountryCode': 'AR',
          'createdAtUtc': '2026-04-10T18:00:00Z',
        });
        continue;
      }

      if (request.method == 'GET' &&
          path == '/api/tenants/tenant-1/documents') {
        await _writeJson(request.response, documents);
        continue;
      }

      if (request.method == 'GET' &&
          path == '/api/tenants/tenant-1/records/disposition-candidates') {
        await _writeJson(request.response, const <Object>[]);
        continue;
      }

      if (request.method == 'GET' &&
          path == '/api/tenants/tenant-1/document-types') {
        await _writeJson(request.response, <Object>[
          <String, Object?>{
            'id': 'type-1',
            'tenantId': 'tenant-1',
            'code': 'CONTRACT',
            'name': 'Contrato',
            'sector': 'legal',
            'isActive': true,
            'metadataSchema': <String, Object?>{},
          },
        ]);
        continue;
      }

      if (request.method == 'POST' &&
          path == '/api/tenants/tenant-1/documents/upload') {
        uploadCount += 1;
        await request.drain<void>();
        final uploadedDocument = <String, Object?>{
          'id': 'doc-upload-$uploadCount',
          'title': 'scan-ui-flow',
          'documentTypeCode': 'CONTRACT',
          'status': 'ACTIVE',
          'createdAtUtc': '2026-04-10T19:00:00Z',
        };
        documents.insert(0, uploadedDocument);
        request.response.statusCode = HttpStatus.created;
        await _writeJson(request.response, uploadedDocument);
        continue;
      }

      request.response.statusCode = HttpStatus.notFound;
      await _writeJson(request.response, <String, Object?>{
        'message': 'Ruta no soportada: $path',
      });
    }
  }

  Future<void> _writeJson(
    HttpResponse response,
    Object payload, {
    bool close = true,
  }) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    if (close) {
      await response.close();
    }
  }
}

final class _FakeWindowsTwainServer {
  _FakeWindowsTwainServer(this._baseUri);

  final Uri _baseUri;
  late HttpServer _server;
  final Map<String, Map<String, Object?>> _sessions =
      <String, Map<String, Object?>>{};
  final Map<String, List<int>> _sessionPdfBytes = <String, List<int>>{};
  static final List<int> _pdfBytes = utf8.encode('%PDF-1.4 fake gdms scan');

  Future<void> start() async {
    _server = await HttpServer.bind(_baseUri.host, _baseUri.port);
    unawaited(_serve());
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final request in _server) {
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/health') {
        await _writeJson(request.response, <String, Object?>{
          'application': 'windows-twain',
          'version': '1.0.0-test',
          'status': 'ok',
          'baseUrl': _baseUri.toString(),
        });
        continue;
      }

      if (request.method == 'GET' && path == '/api/status') {
        await _writeJson(request.response, _statusPayload());
        continue;
      }

      if (request.method == 'GET' && path == '/api/scanners') {
        await _writeJson(request.response, <String, Object?>{
          'result': 'ok',
          'scanners': <Object>[
            <String, Object?>{
              'id': 7,
              'name': 'Canon DR-Mock',
              'manufacturer': 'Canon',
              'productFamily': 'DR',
              'twainVersion': '2.4',
              'isOpen': false,
            },
          ],
        });
        continue;
      }

      if (request.method == 'GET' && path == '/api/sessions') {
        await _writeJson(
          request.response,
          _sessions.values.toList(growable: false),
        );
        continue;
      }

      if (request.method == 'POST' && path == '/api/scanners/discover') {
        await _writeJson(request.response, <String, Object?>{
          'result': 'ok',
          'scanners': <Object>[
            <String, Object?>{
              'id': 7,
              'name': 'Canon DR-Mock',
              'manufacturer': 'Canon',
              'productFamily': 'DR',
              'twainVersion': '2.4',
              'isOpen': false,
            },
          ],
        });
        continue;
      }

      if (request.method == 'POST' &&
          (path == '/api/scans/adf/duplex' ||
              path == '/api/scans/adf/simplex')) {
        final sessionId = 'scan-ui-flow';
        final mode = path.endsWith('/duplex') ? 'adf-duplex' : 'adf-simplex';
        upsertSession(
          sessionId: sessionId,
          scannerName: 'Canon DR-Mock',
          pageCount: 2,
          mode: mode,
          status: 'completed',
        );

        await _writeJson(request.response, <String, Object?>{
          'result': 'ok',
          'sessionId': sessionId,
          'status': 'completed',
          'pageCount': 2,
          'scannerName': 'Canon DR-Mock',
        });
        continue;
      }

      if (request.method == 'GET' &&
          path.startsWith('/api/scans/') &&
          path.contains('/pages/')) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, <String, Object?>{
          'message': 'Preview no disponible en entorno fake.',
        });
        continue;
      }

      if (request.method == 'GET' &&
          path.startsWith('/api/scans/') &&
          path.endsWith('/pdf')) {
        final sessionId = _extractSessionId(path);
        final session = sessionId == null ? null : _sessions[sessionId];
        if (session != null) {
          request.response.headers.contentType = ContentType(
            'application',
            'pdf',
          );
          request.response.headers.set(
            'content-disposition',
            'attachment; filename="$sessionId.pdf"',
          );
          request.response.add(_sessionPdfBytes[sessionId] ?? _pdfBytes);
          await request.response.close();
          continue;
        }
      }

      if (request.method == 'GET' && path.startsWith('/api/scans/')) {
        final sessionId = _extractSessionId(path);
        final session = sessionId == null ? null : _sessions[sessionId];
        if (session != null) {
          await _writeJson(request.response, _sessionDetails(session));
          continue;
        }
      }

      if (request.method == 'DELETE' && path.startsWith('/api/scans/')) {
        final sessionId = _extractSessionId(path);
        if (sessionId != null) {
          _sessions.remove(sessionId);
          _sessionPdfBytes.remove(sessionId);
          await _writeJson(request.response, <String, Object?>{'result': 'ok'});
          continue;
        }
      }

      request.response.statusCode = HttpStatus.notFound;
      await _writeJson(request.response, <String, Object?>{
        'message': 'Ruta no soportada: $path',
      });
    }
  }

  Map<String, Object?> _statusPayload() {
    return <String, Object?>{
      'application': 'windows-twain',
      'version': '1.0.0-test',
      'baseUrl': _baseUri.toString(),
      'runMode': 'headless',
      'startupLogPath': 'C:/tmp/windows-twain.log',
      'scanner': <String, Object?>{'message': '1 scanner disponible'},
      'sessions': <String, Object?>{
        'activeSessions': _sessions.length,
        'sessionsRootPath': 'C:/tmp/windows-twain/sessions',
        'lastCleanupDeletedCount': 0,
      },
      'operations': <Object>[
        <String, Object?>{'id': 'scan-adf-simplex', 'availability': 'ready'},
        <String, Object?>{'id': 'scan-adf-duplex', 'availability': 'ready'},
        <String, Object?>{'id': 'scan-flatbed-single', 'availability': 'ready'},
        <String, Object?>{'id': 'get-session', 'availability': 'ready'},
        <String, Object?>{'id': 'delete-page', 'availability': 'ready'},
        <String, Object?>{'id': 'move-page', 'availability': 'ready'},
        <String, Object?>{'id': 'rotate-page', 'availability': 'ready'},
        <String, Object?>{'id': 'adjust-page', 'availability': 'ready'},
        <String, Object?>{'id': 'merge-session', 'availability': 'ready'},
        <String, Object?>{'id': 'export-pdf', 'availability': 'ready'},
      ],
    };
  }

  void upsertSession({
    required String sessionId,
    required String scannerName,
    required int pageCount,
    required String mode,
    String status = 'completed',
    bool isRehydrated = false,
    List<int>? pdfBytes,
  }) {
    _sessions[sessionId] = _sessionSummary(
      sessionId: sessionId,
      scannerName: scannerName,
      pageCount: pageCount,
      mode: mode,
      status: status,
      isRehydrated: isRehydrated,
    );
    _sessionPdfBytes[sessionId] = pdfBytes ?? _pdfBytes;
  }

  Map<String, Object?> _sessionSummary({
    required String sessionId,
    required String scannerName,
    required int pageCount,
    required String mode,
    required String status,
    required bool isRehydrated,
  }) {
    return <String, Object?>{
      'sessionId': sessionId,
      'createdAtUtc': '2026-04-10T19:00:00Z',
      'lastTouchedAtUtc': '2026-04-10T19:00:01Z',
      'scannerName': scannerName,
      'mode': mode,
      'status': status,
      'pageCount': pageCount,
      'isRehydrated': isRehydrated,
    };
  }

  Map<String, Object?> _sessionDetails(Map<String, Object?> session) {
    return <String, Object?>{
      'sessionId': session['sessionId'],
      'status': session['status'],
      'mode': session['mode'],
      'pageCount': session['pageCount'],
      'scannerName': session['scannerName'],
      'settings': <String, Object?>{
        'dpi': 300,
        'pixelType': 'color',
        'discardBlankPages': 'auto',
      },
    };
  }

  String? _extractSessionId(String path) {
    final segments = Uri.parse('http://localhost$path').pathSegments;
    if (segments.length < 3 || segments[0] != 'api' || segments[1] != 'scans') {
      return null;
    }
    return segments[2];
  }

  Future<void> _writeJson(
    HttpResponse response,
    Object payload, {
    bool close = true,
  }) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    if (close) {
      await response.close();
    }
  }
}
