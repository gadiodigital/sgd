import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

typedef AuthenticatedHandler = Future<Response> Function(AuthenticatedRequest actor);

Future<void> main() async {
  final config = ServerConfig.fromEnvironment();
  final connection = await Connection.open(
    Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
  final repo = SgdRepository(
    connection,
    repoRoot: config.repoRoot,
    scannerBaseUrl: config.scannerBaseUrl,
  );
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_errors())
      .addHandler(_buildRouter(repo, config).call);

  final server = await shelf_io.serve(handler, config.host, config.port);
  stdout.writeln('sgd_api en http://${server.address.host}:${server.port}');
}

Router _buildRouter(SgdRepository repo, ServerConfig config) {
  return Router()
    ..get('/', (_) => _jsonResponse({'service': 'sgd_api', 'status': 'ok'}))
    ..get('/health', (_) => _jsonResponse({'status': 'ok'}))
    ..post('/auth/login', (request) async {
      final body = await _readJsonMap(request);
      final login = _requiredString(body, 'login');
      final password = _requiredString(body, 'password');
      try {
        final result = await repo.loginLocal(
          login,
          password,
          ipAddress: _requestIp(request),
          userAgent: request.headers[HttpHeaders.userAgentHeader],
        );
        final state = await repo.fetchCurrentUserState(result.userId);
        await repo.logAuditEvent(
          userId: result.userId,
          sessionId: result.sessionId,
          projectId: null,
          actionCode: 'auth.login',
          accessKind: 'write',
          resourceType: 'auth_session',
          resourceId: result.sessionId,
          outcome: 'success',
          details: {'provider': 'local', 'login': result.loginName},
          ipAddress: _requestIp(request),
          userAgent: request.headers[HttpHeaders.userAgentHeader],
        );
        return _jsonResponse({'token': result.token, ...state});
      } on ApiError catch (error) {
        await repo.logAuditEvent(
          userId: null,
          sessionId: null,
          projectId: null,
          actionCode: 'auth.login',
          accessKind: 'write',
          resourceType: 'auth_session',
          resourceId: null,
          outcome: error.statusCode == 401 ? 'denied' : 'error',
          message: error.message,
          details: {'provider': 'local', 'login': login},
          ipAddress: _requestIp(request),
          userAgent: request.headers[HttpHeaders.userAgentHeader],
        );
        rethrow;
      } catch (error) {
        await repo.logAuditEvent(
          userId: null,
          sessionId: null,
          projectId: null,
          actionCode: 'auth.login',
          accessKind: 'write',
          resourceType: 'auth_session',
          resourceId: null,
          outcome: 'error',
          message: _formatError(error),
          details: {'provider': 'local', 'login': login},
          ipAddress: _requestIp(request),
          userAgent: request.headers[HttpHeaders.userAgentHeader],
        );
        rethrow;
      }
    })
    ..get(
      '/auth/me',
      (request) => _withAuth(
        request,
        repo,
        audit: const AuditSpec(actionCode: 'auth.me', accessKind: 'read', resourceType: 'auth_user'),
        handler: (actor) async => _jsonResponse(await repo.fetchCurrentUserState(actor.userId)),
      ),
    )
    ..post(
      '/auth/logout',
      (request) => _withAuth(
        request,
        repo,
        audit: const AuditSpec(actionCode: 'auth.logout', accessKind: 'write', resourceType: 'auth_session'),
        handler: (actor) async {
          await repo.revokeSession(actor.sessionId);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..get(
      '/projects',
      (request) => _withAuth(
        request,
        repo,
        audit: const AuditSpec(actionCode: 'project.list', accessKind: 'read', resourceType: 'project_collection'),
        handler: (actor) async => _jsonResponse({'items': await repo.listProjectsForUser(actor.userId, isPlatformAdmin: actor.isPlatformAdmin)}),
      ),
    )
    ..post(
      '/projects',
      (request) => _withAuth(
        request,
        repo,
        requirePlatformAdmin: true,
        audit: const AuditSpec(actionCode: 'project.create', accessKind: 'write', resourceType: 'project'),
        handler: (actor) async {
          final body = await _readJsonMap(request);
          final id = await repo.createProject(
            createdByUserId: actor.userId,
            name: _requiredString(body, 'name'),
            slug: _requiredString(body, 'slug'),
            description: _optionalString(body, 'description') ?? '',
          );
          return _jsonResponse({'id': id}, statusCode: 201);
        },
      ),
    )
    ..put(
      '/projects/<projectId>',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'project.write',
        audit: AuditSpec(actionCode: 'project.update', accessKind: 'write', resourceType: 'project', resourceId: projectId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          await repo.updateProject(
            projectId,
            name: _requiredString(body, 'name'),
            slug: _requiredString(body, 'slug'),
            description: _optionalString(body, 'description') ?? '',
          );
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..delete(
      '/projects/<projectId>',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'project.write',
        audit: AuditSpec(actionCode: 'project.delete', accessKind: 'write', resourceType: 'project', resourceId: projectId),
        handler: (_) async {
          await repo.deleteProject(projectId);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..get(
      '/projects/<projectId>/snapshot',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'project.read',
        audit: AuditSpec(actionCode: 'project.snapshot', accessKind: 'read', resourceType: 'project', resourceId: projectId),
        handler: (_) async => _jsonResponse(await repo.fetchProjectSnapshot(projectId)),
      ),
    )
    ..get(
      '/projects/<projectId>/security',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'security.read',
        audit: AuditSpec(actionCode: 'security.read', accessKind: 'read', resourceType: 'project_security', resourceId: projectId),
        handler: (_) async => _jsonResponse(await repo.fetchProjectSecurity(projectId)),
      ),
    )
    ..post(
      '/projects/<projectId>/profiles',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'security.write',
        audit: AuditSpec(actionCode: 'security.profile.create', accessKind: 'write', resourceType: 'project_profile', resourceId: projectId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          final id = await repo.createProjectProfile(projectId, body);
          return _jsonResponse({'id': id}, statusCode: 201);
        },
      ),
    )
    ..put(
      '/projects/<projectId>/profiles/<profileId>',
      (request, projectId, profileId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'security.write',
        audit: AuditSpec(actionCode: 'security.profile.update', accessKind: 'write', resourceType: 'project_profile', resourceId: profileId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          await repo.updateProjectProfile(projectId, profileId, body);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..delete(
      '/projects/<projectId>/profiles/<profileId>',
      (request, projectId, profileId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'security.write',
        audit: AuditSpec(actionCode: 'security.profile.delete', accessKind: 'write', resourceType: 'project_profile', resourceId: profileId),
        handler: (_) async {
          await repo.deleteProjectProfile(projectId, profileId);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..post(
      '/projects/<projectId>/memberships',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'security.write',
        audit: AuditSpec(actionCode: 'security.membership.create', accessKind: 'write', resourceType: 'project_membership', resourceId: projectId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          final result = await repo.createOrAssignProjectMembership(projectId, body);
          return _jsonResponse(result, statusCode: 201);
        },
      ),
    )
    ..put(
      '/projects/<projectId>/memberships/<userId>',
      (request, projectId, userId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'security.write',
        audit: AuditSpec(actionCode: 'security.membership.update', accessKind: 'write', resourceType: 'project_membership', resourceId: userId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          await repo.updateProjectMembership(projectId, userId, body);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..post(
      '/projects/<projectId>/node-types',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'types.write',
        audit: AuditSpec(actionCode: 'types.create', accessKind: 'write', resourceType: 'node_type', resourceId: projectId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          final id = await repo.createNodeType(projectId, body);
          return _jsonResponse({'id': id}, statusCode: 201);
        },
      ),
    )
    ..put(
      '/projects/<projectId>/node-types/<typeId>',
      (request, projectId, typeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'types.write',
        audit: AuditSpec(actionCode: 'types.update', accessKind: 'write', resourceType: 'node_type', resourceId: typeId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          await repo.updateNodeType(projectId, typeId, body);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..delete(
      '/projects/<projectId>/node-types/<typeId>',
      (request, projectId, typeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'types.write',
        audit: AuditSpec(actionCode: 'types.delete', accessKind: 'write', resourceType: 'node_type', resourceId: typeId),
        handler: (_) async {
          await repo.deleteNodeType(projectId, typeId);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..put(
      '/projects/<projectId>/node-types/<typeId>/attributes/sync',
      (request, projectId, typeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'types.write',
        audit: AuditSpec(actionCode: 'types.attributes.sync', accessKind: 'write', resourceType: 'node_type', resourceId: typeId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          final items = (body['items'] as List?) ?? const [];
          await repo.syncNodeTypeAttributes(projectId, typeId, items);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..post(
      '/projects/<projectId>/rules',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'types.write',
        audit: AuditSpec(actionCode: 'types.rules.create', accessKind: 'write', resourceType: 'node_type_rule', resourceId: projectId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          await repo.createRule(
            projectId,
            parentTypeId: _requiredString(body, 'parentTypeId'),
            childTypeId: _requiredString(body, 'childTypeId'),
          );
          return _jsonResponse({'status': 'ok'}, statusCode: 201);
        },
      ),
    )
    ..delete(
      '/projects/<projectId>/rules/<parentTypeId>/<childTypeId>',
      (request, projectId, parentTypeId, childTypeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'types.write',
        audit: AuditSpec(actionCode: 'types.rules.delete', accessKind: 'write', resourceType: 'node_type_rule', resourceId: '$parentTypeId|$childTypeId'),
        handler: (_) async {
          await repo.deleteRule(projectId, parentTypeId: parentTypeId, childTypeId: childTypeId);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..post(
      '/projects/<projectId>/nodes',
      (request, projectId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'hierarchy.write',
        audit: AuditSpec(actionCode: 'hierarchy.node.create', accessKind: 'write', resourceType: 'hierarchy_node', resourceId: projectId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          final id = await repo.createNode(projectId, body);
          return _jsonResponse({'id': id}, statusCode: 201);
        },
      ),
    )
    ..put(
      '/projects/<projectId>/nodes/<nodeId>',
      (request, projectId, nodeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'hierarchy.write',
        audit: AuditSpec(actionCode: 'hierarchy.node.update', accessKind: 'write', resourceType: 'hierarchy_node', resourceId: nodeId),
        handler: (_) async {
          final body = await _readJsonMap(request);
          await repo.updateNode(projectId, nodeId, body);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..delete(
      '/projects/<projectId>/nodes/<nodeId>',
      (request, projectId, nodeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'hierarchy.write',
        audit: AuditSpec(actionCode: 'hierarchy.node.delete', accessKind: 'write', resourceType: 'hierarchy_node', resourceId: nodeId),
        handler: (_) async {
          await repo.deleteNode(projectId, nodeId);
          return _jsonResponse({'status': 'ok'});
        },
      ),
    )
    ..get(
      '/projects/<projectId>/nodes/<nodeId>/documents',
      (request, projectId, nodeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'documents.read',
        audit: AuditSpec(actionCode: 'documents.list', accessKind: 'read', resourceType: 'document_collection', resourceId: nodeId),
        handler: (_) async => _jsonResponse({'items': await repo.listNodeDocuments(projectId, nodeId)}),
      ),
    )
    ..post(
      '/projects/<projectId>/nodes/<nodeId>/documents/from-scan',
      (request, projectId, nodeId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'documents.write',
        audit: AuditSpec(actionCode: 'documents.create', accessKind: 'write', resourceType: 'document', resourceId: nodeId),
        handler: (actor) async {
          final body = await _readJsonMap(request);
          final result = await repo.createDocumentFromScan(
            projectId,
            nodeId,
            body,
            createdByUserId: actor.userId,
          );
          return _jsonResponse(result, statusCode: 201);
        },
      ),
    )
    ..get(
      '/projects/<projectId>/documents/<documentId>/pdf',
      (request, projectId, documentId) => _withAuth(
        request,
        repo,
        projectId: projectId,
        permissionCode: 'documents.read',
        audit: AuditSpec(actionCode: 'documents.file.get', accessKind: 'read', resourceType: 'document_file', resourceId: documentId),
        handler: (_) async {
          final file = await repo.findCurrentDocumentPdf(projectId, documentId);
          final filePath = file['storagePath']!.toString();
          final downloadName = file['originalName']!.toString();
          final target = File(filePath);
          if (!target.existsSync()) {
            throw const ApiError(404, 'No se encontró el PDF actual del documento.');
          }
          return Response.ok(
            target.openRead(),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/pdf',
              'content-disposition': 'inline; filename="${_contentDispositionName(downloadName)}"',
            },
          );
        },
      ),
    )
    ..get('/ui/<name>', (_, name) async {
      if (!const {'ui1.html', 'ui2.html', 'ui3.html'}.contains(name)) {
        throw const ApiError(404, 'UI no encontrada.');
      }
      final file = File('${config.repoRoot.path}${Platform.pathSeparator}$name');
      if (!file.existsSync()) {
        throw ApiError(404, 'No se encontró $name en el repo.');
      }
      return Response.ok(
        await file.readAsString(),
        headers: const {HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8'},
      );
    });
}

Future<Response> _withAuth(
  Request request,
  SgdRepository repo, {
  required AuditSpec audit,
  String? projectId,
  String? permissionCode,
  bool requirePlatformAdmin = false,
  required AuthenticatedHandler handler,
}) async {
  final actor = await _authenticateRequest(request, repo);
  final ipAddress = _requestIp(request);
  final userAgent = request.headers[HttpHeaders.userAgentHeader];
  try {
    if (requirePlatformAdmin && !actor.isPlatformAdmin) {
      throw const ApiError(403, 'Solo un administrador global puede realizar esta acción.');
    }
    if (projectId != null && permissionCode != null && !actor.isPlatformAdmin) {
      final allowed = await repo.userHasProjectPermission(actor.userId, projectId, permissionCode);
      if (!allowed) {
        throw const ApiError(403, 'No tienes permisos para realizar esta acción en el proyecto actual.');
      }
    }
    final response = await handler(actor);
    await repo.logAuditEvent(
      userId: actor.userId,
      sessionId: actor.sessionId,
      projectId: projectId,
      actionCode: audit.actionCode,
      accessKind: audit.accessKind,
      resourceType: audit.resourceType,
      resourceId: audit.resourceId,
      outcome: 'success',
      details: audit.details,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    return response;
  } on ApiError catch (error) {
    await repo.logAuditEvent(
      userId: actor.userId,
      sessionId: actor.sessionId,
      projectId: projectId,
      actionCode: audit.actionCode,
      accessKind: audit.accessKind,
      resourceType: audit.resourceType,
      resourceId: audit.resourceId,
      outcome: error.statusCode == 403 ? 'denied' : 'error',
      message: error.message,
      details: audit.details,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    rethrow;
  } catch (error) {
    await repo.logAuditEvent(
      userId: actor.userId,
      sessionId: actor.sessionId,
      projectId: projectId,
      actionCode: audit.actionCode,
      accessKind: audit.accessKind,
      resourceType: audit.resourceType,
      resourceId: audit.resourceId,
      outcome: 'error',
      message: _formatError(error),
      details: audit.details,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    rethrow;
  }
}

Future<AuthenticatedRequest> _authenticateRequest(Request request, SgdRepository repo) async {
  final authHeader = request.headers[HttpHeaders.authorizationHeader] ?? '';
  if (!authHeader.toLowerCase().startsWith('bearer ')) {
    throw const ApiError(401, 'Debes iniciar sesión.');
  }
  final token = authHeader.substring(7).trim();
  if (token.isEmpty) {
    throw const ApiError(401, 'Debes iniciar sesión.');
  }
  final actor = await repo.findAuthenticatedSession(token);
  if (actor == null) {
    throw const ApiError(401, 'La sesión expiró o ya no es válida.');
  }
  await repo.touchSession(actor.sessionId);
  return actor;
}

class ServerConfig {
  ServerConfig({
    required this.host,
    required this.port,
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.repoRoot,
    required this.scannerBaseUrl,
  });

  factory ServerConfig.fromEnvironment() {
    final current = Directory.current;
    final repoRoot = Platform.environment['SGD_REPO_ROOT']?.trim().isNotEmpty == true
        ? Directory(Platform.environment['SGD_REPO_ROOT']!)
        : (_basename(current.path) == 'sgd_api' ? current.parent : current);
    return ServerConfig(
      host: Platform.environment['SGD_API_HOST']?.trim().isNotEmpty == true ? Platform.environment['SGD_API_HOST']! : '127.0.0.1',
      port: int.tryParse(Platform.environment['SGD_API_PORT'] ?? '') ?? 8081,
      dbHost: Platform.environment['SGD_DB_HOST']?.trim().isNotEmpty == true ? Platform.environment['SGD_DB_HOST']! : 'localhost',
      dbPort: int.tryParse(Platform.environment['SGD_DB_PORT'] ?? '') ?? 5432,
      dbName: Platform.environment['SGD_DB_NAME']?.trim().isNotEmpty == true ? Platform.environment['SGD_DB_NAME']! : 'sgd',
      dbUser: Platform.environment['SGD_DB_USER']?.trim().isNotEmpty == true ? Platform.environment['SGD_DB_USER']! : 'postgres',
      dbPassword: Platform.environment['SGD_DB_PASSWORD']?.trim().isNotEmpty == true ? Platform.environment['SGD_DB_PASSWORD']! : '12.',
      repoRoot: repoRoot,
      scannerBaseUrl: Uri.parse(
        Platform.environment['WINDOWS_TWAIN_BASE_URL']?.trim().isNotEmpty == true
            ? Platform.environment['WINDOWS_TWAIN_BASE_URL']!
            : 'http://127.0.0.1:43127',
      ),
    );
  }

  final String host;
  final int port;
  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final Directory repoRoot;
  final Uri scannerBaseUrl;
}

class SgdRepository {
  SgdRepository(
    this.connection, {
    required this.repoRoot,
    required this.scannerBaseUrl,
  });

  final Connection connection;
  final Directory repoRoot;
  final Uri scannerBaseUrl;

  Future<LoginResult> loginLocal(
    String login,
    String password, {
    String? ipAddress,
    String? userAgent,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
        SELECT
          u.id::text AS "userId",
          ai.id::text AS "identityId",
          ap.id::text AS "providerId",
          COALESCE(ai.login_name, ai.subject) AS "loginName"
        FROM auth_identities ai
        JOIN auth_providers ap
          ON ap.id = ai.provider_id
        JOIN app_users u
          ON u.id = ai.user_id
        WHERE ap.code = 'local'
          AND ap.is_enabled = true
          AND ai.is_active = true
          AND u.is_active = true
          AND lower(COALESCE(ai.login_name, ai.subject)) = lower(@login)
          AND ai.password_hash = crypt(@password, ai.password_hash)
      '''),
      parameters: {'login': login, 'password': password},
    );
    if (rows.isEmpty) {
      throw const ApiError(401, 'Credenciales inválidas.');
    }

    final map = _rowMap(rows.first);
    final sessionRows = await connection.execute(
      Sql.named('''
        INSERT INTO auth_sessions (
          user_id,
          identity_id,
          provider_id,
          session_token,
          expires_at,
          ip_address,
          user_agent
        )
        VALUES (
          @userId,
          @identityId,
          @providerId,
          encode(gen_random_bytes(32), 'hex'),
          now() + interval '12 hours',
          CAST(@ipAddress AS inet),
          @userAgent
        )
        RETURNING id::text AS id, session_token AS token
      '''),
      parameters: {
        'userId': _requiredColumnString(map, 'userId'),
        'identityId': _requiredColumnString(map, 'identityId'),
        'providerId': _requiredColumnString(map, 'providerId'),
        'ipAddress': _nullIfBlank(ipAddress),
        'userAgent': _nullIfBlank(userAgent),
      },
    );
    await connection.execute(
      Sql.named('UPDATE auth_identities SET last_login_at = now() WHERE id = @identityId'),
      parameters: {'identityId': _requiredColumnString(map, 'identityId')},
    );
    final sessionMap = _rowMap(sessionRows.first);
    return LoginResult(
      userId: _requiredColumnString(map, 'userId'),
      sessionId: _requiredColumnString(sessionMap, 'id'),
      token: _requiredColumnString(sessionMap, 'token'),
      loginName: _requiredColumnString(map, 'loginName'),
    );
  }

  Future<AuthenticatedRequest?> findAuthenticatedSession(String token) async {
    final rows = await connection.execute(
      Sql.named('''
        SELECT
          s.id::text AS "sessionId",
          s.user_id::text AS "userId",
          u.display_name AS "displayName",
          u.is_platform_admin AS "isPlatformAdmin"
        FROM auth_sessions s
        JOIN app_users u
          ON u.id = s.user_id
        JOIN auth_identities ai
          ON ai.id = s.identity_id
        JOIN auth_providers ap
          ON ap.id = s.provider_id
        WHERE s.session_token = @token
          AND s.revoked_at IS NULL
          AND s.expires_at > now()
          AND u.is_active = true
          AND ai.is_active = true
          AND ap.is_enabled = true
      '''),
      parameters: {'token': token},
    );
    if (rows.isEmpty) {
      return null;
    }
    final map = _rowMap(rows.first);
    return AuthenticatedRequest(
      sessionId: _requiredColumnString(map, 'sessionId'),
      userId: _requiredColumnString(map, 'userId'),
      displayName: _requiredColumnString(map, 'displayName'),
      isPlatformAdmin: _columnBool(map, 'isPlatformAdmin'),
    );
  }

  Future<void> touchSession(String sessionId) {
    return connection.execute(
      Sql.named('UPDATE auth_sessions SET last_seen_at = now() WHERE id = @sessionId'),
      parameters: {'sessionId': sessionId},
    );
  }

  Future<void> revokeSession(String sessionId) async {
    final rows = await connection.execute(
      Sql.named('UPDATE auth_sessions SET revoked_at = now() WHERE id = @sessionId RETURNING id::text AS id'),
      parameters: {'sessionId': sessionId},
    );
    _ensureFound(rows, 'Sesión no encontrada.');
  }

  Future<Map<String, dynamic>> fetchCurrentUserState(String userId) async {
    final userRows = await connection.execute(
      Sql.named('''
        SELECT
          u.id::text AS id,
          COALESCE(u.email, '') AS email,
          u.display_name AS "displayName",
          u.is_platform_admin AS "isPlatformAdmin",
          COALESCE(ai.login_name, '') AS "loginName"
        FROM app_users u
        LEFT JOIN LATERAL (
          SELECT login_name
          FROM auth_identities ai
          JOIN auth_providers ap
            ON ap.id = ai.provider_id
          WHERE ai.user_id = u.id
            AND ai.is_active = true
            AND ap.code = 'local'
          ORDER BY ai.created_at
          LIMIT 1
        ) ai ON true
        WHERE u.id = @userId
      '''),
      parameters: {'userId': userId},
    );
    _ensureFound(userRows, 'Usuario no encontrado.');
    final userMap = _rowMap(userRows.first);

    final membershipRows = await connection.execute(
      Sql.named('''
        SELECT
          pm.project_id::text AS "projectId",
          pm.profile_id::text AS "profileId",
          pp.code AS "profileCode",
          pp.name AS "profileName",
          ppp.permission_code AS "permissionCode"
        FROM project_memberships pm
        JOIN project_profiles pp
          ON pp.project_id = pm.project_id
         AND pp.id = pm.profile_id
        LEFT JOIN project_profile_permissions ppp
          ON ppp.project_id = pp.project_id
         AND ppp.profile_id = pp.id
        WHERE pm.user_id = @userId
          AND pm.is_active = true
          AND pp.is_active = true
        ORDER BY pm.project_id, pp.code, ppp.permission_code
      '''),
      parameters: {'userId': userId},
    );

    final membershipsByProject = <String, Map<String, dynamic>>{};
    for (final row in membershipRows) {
      final map = _rowMap(row);
      final projectId = _requiredColumnString(map, 'projectId');
      final item = membershipsByProject.putIfAbsent(
        projectId,
        () => {
          'projectId': projectId,
          'profileId': _requiredColumnString(map, 'profileId'),
          'profileCode': _requiredColumnString(map, 'profileCode'),
          'profileName': _requiredColumnString(map, 'profileName'),
          'permissionCodes': <String>[],
        },
      );
      final permissionCode = _columnValue(map, 'permissionCode')?.toString();
      if (permissionCode != null && permissionCode.isNotEmpty) {
        (item['permissionCodes'] as List<String>).add(permissionCode);
      }
    }

    final permissionRows = await connection.execute(Sql.named('SELECT code FROM permission_catalog ORDER BY code'));
    final allPermissions = permissionRows.map((row) => row[0].toString()).toList();

    return {
      'user': {
        'id': _requiredColumnString(userMap, 'id'),
        'displayName': _requiredColumnString(userMap, 'displayName'),
        'email': (_columnValue(userMap, 'email') ?? '').toString(),
        'loginName': (_columnValue(userMap, 'loginName') ?? '').toString(),
        'isPlatformAdmin': _columnBool(userMap, 'isPlatformAdmin'),
      },
      'memberships': membershipsByProject.values
          .map((item) => {
                ...item,
                'permissionCodes': () {
                  final codes = (item['permissionCodes'] as List<String>).toSet().toList()..sort();
                  return codes;
                }(),
              })
          .toList(),
      'allPermissions': allPermissions,
    };
  }

  Future<bool> userHasProjectPermission(String userId, String projectId, String permissionCode) async {
    final rows = await connection.execute(
      Sql.named('''
        SELECT 1
        FROM project_memberships pm
        JOIN project_profiles pp
          ON pp.project_id = pm.project_id
         AND pp.id = pm.profile_id
        JOIN project_profile_permissions ppp
          ON ppp.project_id = pp.project_id
         AND ppp.profile_id = pp.id
        WHERE pm.project_id = @projectId
          AND pm.user_id = @userId
          AND pm.is_active = true
          AND pp.is_active = true
          AND ppp.permission_code = @permissionCode
        LIMIT 1
      '''),
      parameters: {
        'projectId': projectId,
        'userId': userId,
        'permissionCode': permissionCode,
      },
    );
    return rows.isNotEmpty;
  }

  Future<void> logAuditEvent({
    required String? userId,
    required String? sessionId,
    required String? projectId,
    required String actionCode,
    required String accessKind,
    required String resourceType,
    required String? resourceId,
    required String outcome,
    String? message,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    await connection.execute(
      Sql.named('''
        INSERT INTO audit_events (
          user_id,
          session_id,
          project_id,
          action_code,
          access_kind,
          resource_type,
          resource_id,
          outcome,
          message,
          details_json,
          ip_address,
          user_agent
        )
        VALUES (
          @userId,
          @sessionId,
          @projectId,
          @actionCode,
          @accessKind,
          @resourceType,
          @resourceId,
          @outcome,
          @message,
          CAST(@detailsJson AS jsonb),
          CAST(@ipAddress AS inet),
          @userAgent
        )
      '''),
      parameters: {
        'userId': userId,
        'sessionId': sessionId,
        'projectId': projectId,
        'actionCode': actionCode,
        'accessKind': accessKind,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'outcome': outcome,
        'message': _nullIfBlank(message),
        'detailsJson': jsonEncode(details ?? const <String, dynamic>{}),
        'ipAddress': _nullIfBlank(ipAddress),
        'userAgent': _nullIfBlank(userAgent),
      },
    );
  }

  Future<List<Map<String, dynamic>>> listProjectsForUser(
    String userId, {
    required bool isPlatformAdmin,
  }) async {
    final rows = await connection.execute(
      isPlatformAdmin
          ? Sql.named('''
              SELECT id::text AS id, slug, name, COALESCE(description, '') AS description
              FROM projects
              WHERE is_active = true
              ORDER BY name, slug
            ''')
          : Sql.named('''
              SELECT DISTINCT p.id::text AS id, p.slug, p.name, COALESCE(p.description, '') AS description
              FROM projects p
              JOIN project_memberships pm
                ON pm.project_id = p.id
              JOIN project_profiles pp
                ON pp.project_id = pm.project_id
               AND pp.id = pm.profile_id
              JOIN project_profile_permissions ppp
                ON ppp.project_id = pp.project_id
               AND ppp.profile_id = pp.id
              WHERE p.is_active = true
                AND pm.user_id = @userId
                AND pm.is_active = true
                AND pp.is_active = true
                AND ppp.permission_code = 'project.read'
              ORDER BY p.name, p.slug
            '''),
      parameters: isPlatformAdmin ? const {} : {'userId': userId},
    );
    return rows.map((row) => row.toColumnMap()).cast<Map<String, dynamic>>().toList();
  }

  Future<String> createProject({
    required String createdByUserId,
    required String name,
    required String slug,
    required String description,
  }) {
    return connection.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO projects (name, slug, description)
          VALUES (@name, @slug, @description)
          RETURNING id::text AS id
        '''),
        parameters: {'name': name, 'slug': slug, 'description': _nullIfBlank(description)},
      );
      final projectId = rows.first[0] as String;
      await tx.execute(
        Sql.named('SELECT ensure_default_project_security(@projectId, @createdByUserId)'),
        parameters: {'projectId': projectId, 'createdByUserId': createdByUserId},
      );
      return projectId;
    });
  }

  Future<void> updateProject(
    String projectId, {
    required String name,
    required String slug,
    required String description,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
        UPDATE projects
        SET name = @name, slug = @slug, description = @description
        WHERE id = @projectId
        RETURNING id::text AS id
      '''),
      parameters: {
        'projectId': projectId,
        'name': name,
        'slug': slug,
        'description': _nullIfBlank(description),
      },
    );
    _ensureFound(rows, 'Proyecto no encontrado.');
  }

  Future<void> deleteProject(String projectId) async {
    final rows = await connection.execute(
      Sql.named('DELETE FROM projects WHERE id = @projectId RETURNING id::text AS id'),
      parameters: {'projectId': projectId},
    );
    _ensureFound(rows, 'Proyecto no encontrado.');
  }

  Future<Map<String, dynamic>> fetchProjectSecurity(String projectId) async {
    await _ensureProjectExists(projectId);

    final permissionsRows = await connection.execute(
      Sql.named('SELECT code, name, description, access_kind AS "accessKind" FROM permission_catalog ORDER BY code'),
    );
    final profileRows = await connection.execute(
      Sql.named('''
        SELECT
          id::text AS id,
          project_id::text AS "projectId",
          code,
          name,
          COALESCE(description, '') AS description,
          is_system AS "isSystem",
          is_active AS "isActive"
        FROM project_profiles
        WHERE project_id = @projectId
        ORDER BY is_system DESC, name, code
      '''),
      parameters: {'projectId': projectId},
    );
    final profilePermissionRows = await connection.execute(
      Sql.named('''
        SELECT
          profile_id::text AS "profileId",
          permission_code AS "permissionCode"
        FROM project_profile_permissions
        WHERE project_id = @projectId
        ORDER BY profile_id, permission_code
      '''),
      parameters: {'projectId': projectId},
    );
    final membershipRows = await connection.execute(
      Sql.named('''
        SELECT
          pm.user_id::text AS "userId",
          pm.profile_id::text AS "profileId",
          pm.is_active AS "isActive",
          u.is_active AS "userActive",
          u.display_name AS "displayName",
          COALESCE(u.email, '') AS email,
          pp.code AS "profileCode",
          pp.name AS "profileName",
          COALESCE(ai.login_name, '') AS "loginName"
        FROM project_memberships pm
        JOIN app_users u
          ON u.id = pm.user_id
        JOIN project_profiles pp
          ON pp.project_id = pm.project_id
         AND pp.id = pm.profile_id
        LEFT JOIN LATERAL (
          SELECT login_name
          FROM auth_identities ai
          JOIN auth_providers ap
            ON ap.id = ai.provider_id
          WHERE ai.user_id = u.id
            AND ai.is_active = true
            AND ap.code = 'local'
          ORDER BY ai.created_at
          LIMIT 1
        ) ai ON true
        WHERE pm.project_id = @projectId
        ORDER BY u.display_name, u.email, ai.login_name
      '''),
      parameters: {'projectId': projectId},
    );

    final permissionsByProfile = <String, List<String>>{};
    for (final row in profilePermissionRows) {
      final map = _rowMap(row);
      final profileId = _requiredColumnString(map, 'profileId');
      permissionsByProfile.putIfAbsent(profileId, () => []).add(_requiredColumnString(map, 'permissionCode'));
    }

    return {
      'projectId': projectId,
      'permissions': permissionsRows.map((row) => row.toColumnMap()).cast<Map<String, dynamic>>().toList(),
      'profiles': profileRows.map((row) {
        final map = _rowMap(row);
        final id = _requiredColumnString(map, 'id');
        return {
          'id': id,
          'projectId': _requiredColumnString(map, 'projectId'),
          'code': _requiredColumnString(map, 'code'),
          'name': _requiredColumnString(map, 'name'),
          'description': (_columnValue(map, 'description') ?? '').toString(),
          'isSystem': _columnBool(map, 'isSystem'),
          'isActive': _columnBool(map, 'isActive'),
          'permissionCodes': permissionsByProfile[id] ?? const <String>[],
        };
      }).toList(),
      'memberships': membershipRows.map((row) => row.toColumnMap()).cast<Map<String, dynamic>>().toList(),
    };
  }

  Future<String> createProjectProfile(String projectId, Map<String, dynamic> body) {
    return connection.runTx((tx) async {
      await _ensureProjectExists(projectId, session: tx);
      final permissionCodes = _readStringList(body, 'permissionCodes');
      await _validatePermissionCodes(permissionCodes, session: tx);
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO project_profiles (
            project_id,
            code,
            name,
            description,
            is_system,
            is_active
          )
          VALUES (
            @projectId,
            @code,
            @name,
            @description,
            false,
            @isActive
          )
          RETURNING id::text AS id
        '''),
        parameters: {
          'projectId': projectId,
          'code': _requiredString(body, 'code'),
          'name': _requiredString(body, 'name'),
          'description': _nullIfBlank(_optionalString(body, 'description')),
          'isActive': body['isActive'] != false,
        },
      );
      final profileId = rows.first[0] as String;
      await _syncProjectProfilePermissions(tx, projectId, profileId, permissionCodes);
      return profileId;
    });
  }

  Future<void> updateProjectProfile(String projectId, String profileId, Map<String, dynamic> body) {
    return connection.runTx((tx) async {
      final existing = await tx.execute(
        Sql.named('''
          SELECT is_system AS "isSystem", code
          FROM project_profiles
          WHERE project_id = @projectId
            AND id = @profileId
        '''),
        parameters: {'projectId': projectId, 'profileId': profileId},
      );
      _ensureFound(existing, 'Perfil no encontrado.');
      final existingMap = _rowMap(existing.first);
      final isSystem = _columnBool(existingMap, 'isSystem');
      final requestedCode = _requiredString(body, 'code');
      if (isSystem && requestedCode != _requiredColumnString(existingMap, 'code')) {
        throw const ApiError(400, 'Los perfiles del sistema no pueden cambiar su código.');
      }
      final permissionCodes = _readStringList(body, 'permissionCodes');
      await _validatePermissionCodes(permissionCodes, session: tx);
      final rows = await tx.execute(
        Sql.named('''
          UPDATE project_profiles
          SET
            code = @code,
            name = @name,
            description = @description,
            is_active = @isActive
          WHERE project_id = @projectId
            AND id = @profileId
          RETURNING id::text AS id
        '''),
        parameters: {
          'projectId': projectId,
          'profileId': profileId,
          'code': requestedCode,
          'name': _requiredString(body, 'name'),
          'description': _nullIfBlank(_optionalString(body, 'description')),
          'isActive': body['isActive'] != false,
        },
      );
      _ensureFound(rows, 'Perfil no encontrado.');
      await _syncProjectProfilePermissions(tx, projectId, profileId, permissionCodes);
    });
  }

  Future<void> deleteProjectProfile(String projectId, String profileId) {
    return connection.runTx((tx) async {
      final existing = await tx.execute(
        Sql.named('''
          SELECT is_system AS "isSystem"
          FROM project_profiles
          WHERE project_id = @projectId
            AND id = @profileId
        '''),
        parameters: {'projectId': projectId, 'profileId': profileId},
      );
      _ensureFound(existing, 'Perfil no encontrado.');
      if (_columnBool(_rowMap(existing.first), 'isSystem')) {
        throw const ApiError(400, 'Los perfiles del sistema no se pueden eliminar.');
      }
      final usageRows = await tx.execute(
        Sql.named('''
          SELECT 1
          FROM project_memberships
          WHERE project_id = @projectId
            AND profile_id = @profileId
          LIMIT 1
        '''),
        parameters: {'projectId': projectId, 'profileId': profileId},
      );
      if (usageRows.isNotEmpty) {
        throw const ApiError(400, 'El perfil todavía está asignado a usuarios del proyecto.');
      }
      final deleted = await tx.execute(
        Sql.named('''
          DELETE FROM project_profiles
          WHERE project_id = @projectId
            AND id = @profileId
          RETURNING id::text AS id
        '''),
        parameters: {'projectId': projectId, 'profileId': profileId},
      );
      _ensureFound(deleted, 'Perfil no encontrado.');
    });
  }

  Future<Map<String, dynamic>> createOrAssignProjectMembership(String projectId, Map<String, dynamic> body) {
    return connection.runTx((tx) async {
      await _ensureProjectExists(projectId, session: tx);
      await _ensureProfileExists(projectId, _requiredString(body, 'profileId'), session: tx);
      final localProviderId = await _localProviderId(tx);
      final loginName = _requiredString(body, 'loginName').toLowerCase();
      final displayName = _requiredString(body, 'displayName');
      final password = _optionalString(body, 'password');
      final email = _optionalString(body, 'email');
      final profileId = _requiredString(body, 'profileId');
      final isActive = body['isActive'] != false;
      final userActive = body['userActive'] != false;

      final existingIdentityRows = await tx.execute(
        Sql.named('''
          SELECT
            ai.user_id::text AS "userId",
            ai.id::text AS "identityId"
          FROM auth_identities ai
          WHERE ai.provider_id = @providerId
            AND lower(COALESCE(ai.login_name, ai.subject)) = lower(@loginName)
          LIMIT 1
        '''),
        parameters: {'providerId': localProviderId, 'loginName': loginName},
      );

      late final String userId;
      if (existingIdentityRows.isEmpty) {
        if (password == null || password.isEmpty) {
          throw const ApiError(400, 'Debes indicar contraseña para crear un usuario nuevo.');
        }
        final createdUserRows = await tx.execute(
          Sql.named('''
            INSERT INTO app_users (display_name, email, is_active, is_platform_admin)
            VALUES (@displayName, @email, @userActive, false)
            RETURNING id::text AS id
          '''),
          parameters: {'displayName': displayName, 'email': _nullIfBlank(email), 'userActive': userActive},
        );
        userId = createdUserRows.first[0] as String;
        await tx.execute(
          Sql.named('''
            INSERT INTO auth_identities (
              user_id,
              provider_id,
              subject,
              login_name,
              password_hash,
              is_active
            )
            VALUES (
              @userId,
              @providerId,
              @subject,
              @loginName,
              crypt(@password, gen_salt('bf', 12)),
              true
            )
          '''),
          parameters: {
            'userId': userId,
            'providerId': localProviderId,
            'subject': loginName,
            'loginName': loginName,
            'password': password,
          },
        );
      } else {
        final identityMap = _rowMap(existingIdentityRows.first);
        userId = _requiredColumnString(identityMap, 'userId');
        await tx.execute(
          Sql.named('''
            UPDATE app_users
            SET
              display_name = @displayName,
              email = @email,
              is_active = @userActive
            WHERE id = @userId
          '''),
          parameters: {
            'displayName': displayName,
            'email': _nullIfBlank(email),
            'userActive': userActive,
            'userId': userId,
          },
        );
        if (password != null && password.isNotEmpty) {
          await tx.execute(
            Sql.named('''
              UPDATE auth_identities
              SET
                password_hash = crypt(@password, gen_salt('bf', 12)),
                is_active = true
              WHERE id = @identityId
            '''),
            parameters: {
              'password': password,
              'identityId': _requiredColumnString(identityMap, 'identityId'),
            },
          );
        }
      }

      await tx.execute(
        Sql.named('''
          INSERT INTO project_memberships (project_id, user_id, profile_id, is_active)
          VALUES (@projectId, @userId, @profileId, @isActive)
          ON CONFLICT (project_id, user_id) DO UPDATE
          SET
            profile_id = EXCLUDED.profile_id,
            is_active = EXCLUDED.is_active
        '''),
        parameters: {
          'projectId': projectId,
          'userId': userId,
          'profileId': profileId,
          'isActive': isActive,
        },
      );

      return {'userId': userId};
    });
  }

  Future<void> updateProjectMembership(String projectId, String userId, Map<String, dynamic> body) {
    return connection.runTx((tx) async {
      final profileId = _requiredString(body, 'profileId');
      await _ensureProfileExists(projectId, profileId, session: tx);
      final rows = await tx.execute(
        Sql.named('''
          UPDATE project_memberships
          SET
            profile_id = @profileId,
            is_active = @isActive
          WHERE project_id = @projectId
            AND user_id = @userId
          RETURNING user_id::text AS id
        '''),
        parameters: {
          'projectId': projectId,
          'userId': userId,
          'profileId': profileId,
          'isActive': body['isActive'] != false,
        },
      );
      _ensureFound(rows, 'Membresía no encontrada.');

      await tx.execute(
        Sql.named('''
          UPDATE app_users
          SET
            display_name = @displayName,
            email = @email,
            is_active = @userActive
          WHERE id = @userId
        '''),
        parameters: {
          'displayName': _requiredString(body, 'displayName'),
          'email': _nullIfBlank(_optionalString(body, 'email')),
          'userActive': body['userActive'] != false,
          'userId': userId,
        },
      );

      final password = _optionalString(body, 'password');
      if (password != null && password.isNotEmpty) {
        final localProviderId = await _localProviderId(tx);
        await tx.execute(
          Sql.named('''
            UPDATE auth_identities
            SET
              password_hash = crypt(@password, gen_salt('bf', 12)),
              is_active = true
            WHERE provider_id = @providerId
              AND user_id = @userId
          '''),
          parameters: {
            'password': password,
            'providerId': localProviderId,
            'userId': userId,
          },
        );
      }
    });
  }

  Future<Map<String, dynamic>> fetchProjectSnapshot(String projectId) async {
    final projectRows = await connection.execute(
      Sql.named('SELECT id::text AS id FROM projects WHERE id = @projectId'),
      parameters: {'projectId': projectId},
    );
    _ensureFound(projectRows, 'Proyecto no encontrado.');

    final typeRows = await connection.execute(
      Sql.named('''
        SELECT
          id::text AS id,
          project_id::text AS "projectId",
          code,
          name,
          COALESCE(description, '') AS description,
          is_root_allowed AS root,
          allows_documents AS "acceptsDocs",
          COALESCE(icon_key, 'folder') AS "iconKey",
          sort_order AS "order"
        FROM hierarchy_node_types
        WHERE project_id = @projectId
        ORDER BY sort_order, name
      '''),
      parameters: {'projectId': projectId},
    );
    final attributeRows = await connection.execute(
      Sql.named('''
        SELECT
          nta.node_type_id::text AS "nodeTypeId",
          ad.id::text AS id,
          ad.code,
          ad.name,
          ad.data_type AS "dataType",
          COALESCE(ad.type_extension::text, '') AS extension,
          COALESCE(ad.validation_regex, '') AS regex
        FROM node_type_attributes nta
        JOIN attribute_definitions ad
          ON ad.project_id = nta.project_id
         AND ad.id = nta.attribute_definition_id
        WHERE nta.project_id = @projectId
        ORDER BY nta.node_type_id, nta.display_order, ad.name
      '''),
      parameters: {'projectId': projectId},
    );
    final optionRows = await connection.execute(
      Sql.named('''
        SELECT
          attribute_definition_id::text AS "attributeId",
          id::text AS id,
          code,
          label
        FROM attribute_options
        WHERE project_id = @projectId
          AND is_active = true
        ORDER BY attribute_definition_id, sort_order, label
      '''),
      parameters: {'projectId': projectId},
    );
    final ruleRows = await connection.execute(
      Sql.named('''
        SELECT
          project_id::text AS "projectId",
          parent_node_type_id::text AS "parentTypeId",
          child_node_type_id::text AS "childTypeId"
        FROM hierarchy_type_rules
        WHERE project_id = @projectId
        ORDER BY parent_node_type_id, child_node_type_id
      '''),
      parameters: {'projectId': projectId},
    );
    final nodeRows = await connection.execute(
      Sql.named('''
        SELECT
          id::text AS id,
          project_id::text AS "projectId",
          node_type_id::text AS "typeId",
          parent_id::text AS "parentId",
          COALESCE(code, '') AS code,
          name,
          COALESCE(description, '') AS description,
          depth,
          sort_order AS "order"
        FROM hierarchy_nodes
        WHERE project_id = @projectId
        ORDER BY depth, sort_order, name
      '''),
      parameters: {'projectId': projectId},
    );
    final valueRows = await connection.execute(
      Sql.named('''
        SELECT
          node_id::text AS "nodeId",
          attribute_definition_id::text AS "attributeId",
          COALESCE(value_text, value_number::text, value_date::text, value_boolean::text, value_json::text) AS value
        FROM node_attribute_values
        WHERE project_id = @projectId
        ORDER BY node_id, attribute_definition_id
      '''),
      parameters: {'projectId': projectId},
    );

    final optionsByAttribute = <String, List<Map<String, dynamic>>>{};
    for (final row in optionRows) {
      final map = _rowMap(row);
      final attributeId = _requiredColumnString(map, 'attributeId');
      optionsByAttribute.putIfAbsent(attributeId, () => []).add({
        'id': _requiredColumnString(map, 'id'),
        'code': _requiredColumnString(map, 'code'),
        'label': _requiredColumnString(map, 'label'),
      });
    }
    final attributesByType = <String, List<Map<String, dynamic>>>{};
    for (final row in attributeRows) {
      final map = _rowMap(row);
      final attributeId = _requiredColumnString(map, 'id');
      final nodeTypeId = _requiredColumnString(map, 'nodeTypeId');
      attributesByType.putIfAbsent(nodeTypeId, () => []).add({
        'id': attributeId,
        'code': _requiredColumnString(map, 'code'),
        'name': _requiredColumnString(map, 'name'),
        'dataType': _requiredColumnString(map, 'dataType'),
        'extension': _columnValue(map, 'extension')?.toString() ?? '',
        'regex': _columnValue(map, 'regex')?.toString() ?? '',
        'options': optionsByAttribute[attributeId] ?? const [],
      });
    }
    final valuesByNode = <String, Map<String, String>>{};
    for (final row in valueRows) {
      final map = _rowMap(row);
      final nodeId = _requiredColumnString(map, 'nodeId');
      final attributeId = _requiredColumnString(map, 'attributeId');
      valuesByNode.putIfAbsent(nodeId, () => {})[attributeId] = (_columnValue(map, 'value') ?? '').toString();
    }

    return {
      'projectId': projectId,
      'types': typeRows.map((row) {
        final map = _rowMap(row);
        final id = _requiredColumnString(map, 'id');
        return {
          'id': id,
          'projectId': _requiredColumnString(map, 'projectId'),
          'code': _requiredColumnString(map, 'code'),
          'name': _requiredColumnString(map, 'name'),
          'description': _columnValue(map, 'description')?.toString() ?? '',
          'root': _columnBool(map, 'root'),
          'acceptsDocs': _columnBool(map, 'acceptsDocs'),
          'iconKey': _columnValue(map, 'iconKey')?.toString() ?? 'folder',
          'order': _columnInt(map, 'order'),
          'attributes': attributesByType[id] ?? const [],
        };
      }).toList(),
      'rules': ruleRows.map((row) {
        final map = _rowMap(row);
        final parentTypeId = _requiredColumnString(map, 'parentTypeId');
        final childTypeId = _requiredColumnString(map, 'childTypeId');
        return {
          'id': '$parentTypeId|$childTypeId',
          'projectId': _requiredColumnString(map, 'projectId'),
          'parentTypeId': parentTypeId,
          'childTypeId': childTypeId,
        };
      }).toList(),
      'nodes': nodeRows.map((row) {
        final map = _rowMap(row);
        final id = _requiredColumnString(map, 'id');
        final parentId = _columnValue(map, 'parentId')?.toString();
        return {
          'id': id,
          'projectId': _requiredColumnString(map, 'projectId'),
          'typeId': _requiredColumnString(map, 'typeId'),
          'parentId': parentId == null || parentId.isEmpty ? null : parentId,
          'code': _columnValue(map, 'code')?.toString() ?? '',
          'name': _requiredColumnString(map, 'name'),
          'description': _columnValue(map, 'description')?.toString() ?? '',
          'depth': _columnInt(map, 'depth'),
          'order': _columnInt(map, 'order'),
          'values': valuesByNode[id] ?? const <String, String>{},
        };
      }).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> listNodeDocuments(String projectId, String nodeId) async {
    await _loadNodeDocumentTarget(projectId, nodeId);

    final rows = await connection.execute(
      Sql.named('''
        SELECT
          d.id::text AS id,
          d.title,
          COALESCE(d.description, '') AS description,
          d.status,
          d.current_version_number AS "currentVersionNumber",
          COALESCE(dt.name, '') AS "documentTypeName",
          COALESCE(pdf.page_count, 0) AS "pageCount",
          COALESCE(pdf.original_name, '') AS "fileName",
          d.updated_at AS "updatedAt"
        FROM documents d
        LEFT JOIN document_types dt
          ON dt.project_id = d.project_id
         AND dt.id = d.document_type_id
        LEFT JOIN LATERAL (
          SELECT
            df.page_count,
            df.original_name
          FROM document_versions dv
          JOIN document_files df
            ON df.project_id = dv.project_id
           AND df.document_version_id = dv.id
          WHERE dv.project_id = d.project_id
            AND dv.document_id = d.id
            AND dv.version_number = d.current_version_number
            AND df.file_role = 'pdf'
          ORDER BY df.created_at DESC
          LIMIT 1
        ) pdf ON true
        WHERE d.project_id = @projectId
          AND d.node_id = @nodeId
        ORDER BY d.updated_at DESC, d.title
      '''),
      parameters: {'projectId': projectId, 'nodeId': nodeId},
    );

    return rows.map((row) {
      final map = _rowMap(row);
      final updatedAt = _columnValue(map, 'updatedAt');
      return {
        'id': _requiredColumnString(map, 'id'),
        'title': _requiredColumnString(map, 'title'),
        'description': (_columnValue(map, 'description') ?? '').toString(),
        'status': _requiredColumnString(map, 'status'),
        'currentVersionNumber': _columnInt(map, 'currentVersionNumber'),
        'documentTypeName': (_columnValue(map, 'documentTypeName') ?? '').toString(),
        'pageCount': _columnInt(map, 'pageCount'),
        'fileName': (_columnValue(map, 'fileName') ?? '').toString(),
        'updatedAt': updatedAt is DateTime ? updatedAt.toUtc().toIso8601String() : updatedAt?.toString(),
      };
    }).toList();
  }

  Future<Map<String, String>> findCurrentDocumentPdf(String projectId, String documentId) async {
    final rows = await connection.execute(
      Sql.named('''
        SELECT
          df.storage_path AS "storagePath",
          COALESCE(df.original_name, d.title || '.pdf') AS "originalName"
        FROM documents d
        JOIN document_versions dv
          ON dv.project_id = d.project_id
         AND dv.document_id = d.id
         AND dv.version_number = d.current_version_number
        JOIN document_files df
          ON df.project_id = dv.project_id
         AND df.document_version_id = dv.id
         AND df.file_role = 'pdf'
        WHERE d.project_id = @projectId
          AND d.id = @documentId
        ORDER BY df.created_at DESC
        LIMIT 1
      '''),
      parameters: {'projectId': projectId, 'documentId': documentId},
    );
    _ensureFound(rows, 'Documento no encontrado o sin PDF actual.');
    final map = _rowMap(rows.first);
    return {
      'storagePath': _requiredColumnString(map, 'storagePath'),
      'originalName': (_columnValue(map, 'originalName') ?? 'documento.pdf').toString(),
    };
  }

  Future<Map<String, dynamic>> createDocumentFromScan(
    String projectId,
    String nodeId,
    Map<String, dynamic> body, {
    required String createdByUserId,
  }) async {
    final title = _requiredString(body, 'title');
    final description = _optionalString(body, 'description') ?? '';
    final sessionId = _requiredString(body, 'sessionId');
    final attributeValues = _readDocumentAttributeValues(body);

    final scanSession = await _fetchScannerSession(sessionId);
    final scanResult = (scanSession['result'] ?? 'ok').toString().toLowerCase();
    final scanStatus = (scanSession['status'] ?? '').toString().toLowerCase();
    final pageCount = _parseInt(scanSession['pageCount'], fallback: 0);
    if (scanResult == 'error' || scanStatus == 'error' || scanStatus == 'canceled') {
      throw ApiError(400, (scanSession['message'] ?? 'La sesión de escaneo terminó con error.').toString());
    }
    if (pageCount <= 0) {
      throw const ApiError(400, 'La sesión de escaneo no contiene páginas para guardar.');
    }

    final pdfBytes = await _downloadScannerPdf(sessionId);
    String? storedFilePath;

    try {
      return await connection.runTx((tx) async {
        final nodeTarget = await _loadNodeDocumentTarget(projectId, nodeId, session: tx);
        final binding = await _ensureScanDocumentType(tx, projectId, nodeTarget);

        final documentRows = await tx.execute(
          Sql.named('''
            INSERT INTO documents (
              project_id,
              node_id,
              document_type_id,
              title,
              description,
              status,
              current_version_number
            )
            VALUES (
              @projectId,
              @nodeId,
              @documentTypeId,
              @title,
              @description,
              'active',
              1
            )
            RETURNING id::text AS id
          '''),
          parameters: {
            'projectId': projectId,
            'nodeId': nodeId,
            'documentTypeId': binding.documentTypeId,
            'title': title,
            'description': _nullIfBlank(description),
          },
        );
        final documentId = documentRows.first[0] as String;

        final versionNotes = jsonEncode({
          'captureProfile': 'scan',
          'savedByUserId': createdByUserId,
          'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'scannerSession': {
            'sessionId': (scanSession['sessionId'] ?? sessionId).toString(),
            'scannerName': (scanSession['scannerName'] ?? '').toString(),
            'mode': (scanSession['mode'] ?? '').toString(),
            'settings': scanSession['settings'] ?? const <String, dynamic>{},
            'pageCount': pageCount,
            'createdAtUtc': (scanSession['createdAtUtc'] ?? '').toString(),
          },
        });

        final versionRows = await tx.execute(
          Sql.named('''
            INSERT INTO document_versions (
              project_id,
              document_id,
              version_number,
              source_type,
              notes
            )
            VALUES (
              @projectId,
              @documentId,
              1,
              'scan',
              @notes
            )
            RETURNING id::text AS id
          '''),
          parameters: {
            'projectId': projectId,
            'documentId': documentId,
            'notes': versionNotes,
          },
        );
        final versionId = versionRows.first[0] as String;

        final storedPdf = await _storeDocumentPdf(
          projectId: projectId,
          documentId: documentId,
          versionNumber: 1,
          title: title,
          pdfBytes: pdfBytes,
        );
        storedFilePath = storedPdf.storagePath;

        await tx.execute(
          Sql.named('''
            INSERT INTO document_files (
              project_id,
              document_version_id,
              file_role,
              storage_path,
              original_name,
              extension,
              mime_type,
              size_bytes,
              page_count
            )
            VALUES (
              @projectId,
              @versionId,
              'pdf',
              @storagePath,
              @originalName,
              @extension,
              @mimeType,
              @sizeBytes,
              @pageCount
            )
          '''),
          parameters: {
            'projectId': projectId,
            'versionId': versionId,
            'storagePath': storedPdf.storagePath,
            'originalName': storedPdf.originalName,
            'extension': storedPdf.extension,
            'mimeType': 'application/pdf',
            'sizeBytes': storedPdf.sizeBytes,
            'pageCount': pageCount,
          },
        );

        await _replaceDocumentValues(
          tx,
          projectId,
          documentId,
          attributeValues,
          binding.attributesBySourceNodeAttributeId,
        );

        return {
          'id': documentId,
          'versionId': versionId,
          'pageCount': pageCount,
          'documentTypeId': binding.documentTypeId,
        };
      });
    } catch (_) {
      if (storedFilePath != null) {
        final storedFile = File(storedFilePath!);
        if (storedFile.existsSync()) {
          storedFile.deleteSync();
        }
      }
      rethrow;
    }
  }

  Future<String> createNodeType(String projectId, Map<String, dynamic> body) async {
    final rows = await connection.execute(
      Sql.named('''
        INSERT INTO hierarchy_node_types (
          project_id, code, name, description, allows_documents, is_root_allowed, sort_order, icon_key
        )
        VALUES (@projectId, @code, @name, @description, @acceptsDocs, @root, @order, @iconKey)
        RETURNING id::text AS id
      '''),
      parameters: _typeParams(projectId, body),
    );
    return rows.first[0] as String;
  }

  Future<void> updateNodeType(String projectId, String typeId, Map<String, dynamic> body) async {
    final rows = await connection.execute(
      Sql.named('''
        UPDATE hierarchy_node_types
        SET
          code = @code,
          name = @name,
          description = @description,
          allows_documents = @acceptsDocs,
          is_root_allowed = @root,
          sort_order = @order,
          icon_key = @iconKey
        WHERE project_id = @projectId
          AND id = @typeId
        RETURNING id::text AS id
      '''),
      parameters: {..._typeParams(projectId, body), 'typeId': typeId},
    );
    _ensureFound(rows, 'Tipo no encontrado.');
  }

  Map<String, dynamic> _typeParams(String projectId, Map<String, dynamic> body) {
    final name = _requiredString(body, 'name');
    return {
      'projectId': projectId,
      'code': _optionalString(body, 'code') ?? _slugify(name),
      'name': name,
      'description': _nullIfBlank(_optionalString(body, 'description')),
      'acceptsDocs': body['acceptsDocs'] == true,
      'root': body['root'] == true,
      'order': _parseInt(body['order'], fallback: 10),
      'iconKey': _optionalString(body, 'iconKey') ?? 'folder',
    };
  }

  Future<void> deleteNodeType(String projectId, String typeId) async {
    await connection.runTx((tx) async {
      final attributeRows = await tx.execute(
        Sql.named('SELECT attribute_definition_id::text AS id FROM node_type_attributes WHERE project_id = @projectId AND node_type_id = @typeId'),
        parameters: {'projectId': projectId, 'typeId': typeId},
      );
      final deletedType = await tx.execute(
        Sql.named('DELETE FROM hierarchy_node_types WHERE project_id = @projectId AND id = @typeId RETURNING id::text AS id'),
        parameters: {'projectId': projectId, 'typeId': typeId},
      );
      _ensureFound(deletedType, 'Tipo no encontrado.');
      for (final row in attributeRows) {
        await _deleteAttributeIfUnused(tx, projectId, row[0] as String);
      }
    });
  }

  Future<void> syncNodeTypeAttributes(String projectId, String typeId, List<dynamic> items) async {
    await connection.runTx((tx) async {
      final existingRows = await tx.execute(
        Sql.named('SELECT attribute_definition_id::text AS id FROM node_type_attributes WHERE project_id = @projectId AND node_type_id = @typeId'),
        parameters: {'projectId': projectId, 'typeId': typeId},
      );
      final existingIds = existingRows.map((row) => row[0] as String).toSet();
      final keptIds = <String>{};
      await tx.execute(
        Sql.named('DELETE FROM node_type_attributes WHERE project_id = @projectId AND node_type_id = @typeId'),
        parameters: {'projectId': projectId, 'typeId': typeId},
      );

      for (var i = 0; i < items.length; i++) {
        final item = Map<String, dynamic>.from((items[i] as Map).cast<String, dynamic>());
        final name = _requiredString(item, 'name');
        final attrId = _optionalString(item, 'id');
        final activeId = attrId != null && existingIds.contains(attrId) ? attrId : await _insertAttribute(tx, projectId, item, name);
        if (attrId != null && existingIds.contains(attrId)) {
          await tx.execute(
            Sql.named('''
              UPDATE attribute_definitions
              SET
                code = @code,
                name = @name,
                data_type = @dataType,
                type_extension = @typeExtension,
                validation_regex = @validationRegex,
                validation_message = NULL
              WHERE project_id = @projectId
                AND id = @attributeId
            '''),
            parameters: {
              'projectId': projectId,
              'attributeId': activeId,
              'code': _optionalString(item, 'code') ?? _slugify(name),
              'name': name,
              'dataType': _requiredString(item, 'dataType'),
              'typeExtension': _parseNullableInt(item['extension']),
              'validationRegex': _nullIfBlank(_optionalString(item, 'regex')),
            },
          );
          await tx.execute(
            Sql.named('DELETE FROM attribute_options WHERE project_id = @projectId AND attribute_definition_id = @attributeId'),
            parameters: {'projectId': projectId, 'attributeId': activeId},
          );
        }

        keptIds.add(activeId);
        await tx.execute(
          Sql.named('''
            INSERT INTO node_type_attributes (project_id, node_type_id, attribute_definition_id, display_order)
            VALUES (@projectId, @typeId, @attributeId, @displayOrder)
          '''),
          parameters: {'projectId': projectId, 'typeId': typeId, 'attributeId': activeId, 'displayOrder': i * 10},
        );

        if (_requiredString(item, 'dataType') == 'list') {
          final options = (item['options'] as List?) ?? const [];
          for (var j = 0; j < options.length; j++) {
            final option = Map<String, dynamic>.from((options[j] as Map).cast<String, dynamic>());
            await tx.execute(
              Sql.named('''
                INSERT INTO attribute_options (project_id, attribute_definition_id, code, label, sort_order)
                VALUES (@projectId, @attributeId, @code, @label, @sortOrder)
              '''),
              parameters: {
                'projectId': projectId,
                'attributeId': activeId,
                'code': _requiredString(option, 'code'),
                'label': _requiredString(option, 'label'),
                'sortOrder': j * 10,
              },
            );
          }
        }
      }

      for (final removedId in existingIds.difference(keptIds)) {
        await _deleteAttributeIfUnused(tx, projectId, removedId);
      }
    });
  }

  Future<String> _insertAttribute(TxSession tx, String projectId, Map<String, dynamic> body, String name) async {
    final rows = await tx.execute(
      Sql.named('''
        INSERT INTO attribute_definitions (
          project_id, scope, code, name, data_type, type_extension, validation_regex
        )
        VALUES (@projectId, 'node', @code, @name, @dataType, @typeExtension, @validationRegex)
        RETURNING id::text AS id
      '''),
      parameters: {
        'projectId': projectId,
        'code': _optionalString(body, 'code') ?? _slugify(name),
        'name': name,
        'dataType': _requiredString(body, 'dataType'),
        'typeExtension': _parseNullableInt(body['extension']),
        'validationRegex': _nullIfBlank(_optionalString(body, 'regex')),
      },
    );
    return rows.first[0] as String;
  }

  Future<void> _deleteAttributeIfUnused(TxSession tx, String projectId, String attributeId) {
    return tx.execute(
      Sql.named('''
        DELETE FROM attribute_definitions ad
        WHERE ad.project_id = @projectId
          AND ad.id = @attributeId
          AND NOT EXISTS (
            SELECT 1
            FROM node_type_attributes nta
            WHERE nta.project_id = ad.project_id
              AND nta.attribute_definition_id = ad.id
          )
          AND NOT EXISTS (
            SELECT 1
            FROM document_type_attributes dta
            WHERE dta.project_id = ad.project_id
              AND dta.attribute_definition_id = ad.id
          )
      '''),
      parameters: {'projectId': projectId, 'attributeId': attributeId},
    );
  }

  Future<void> createRule(String projectId, {required String parentTypeId, required String childTypeId}) {
    return connection.execute(
      Sql.named('''
        INSERT INTO hierarchy_type_rules (project_id, parent_node_type_id, child_node_type_id)
        VALUES (@projectId, @parentTypeId, @childTypeId)
      '''),
      parameters: {'projectId': projectId, 'parentTypeId': parentTypeId, 'childTypeId': childTypeId},
    );
  }

  Future<void> deleteRule(String projectId, {required String parentTypeId, required String childTypeId}) async {
    final rows = await connection.execute(
      Sql.named('''
        DELETE FROM hierarchy_type_rules
        WHERE project_id = @projectId
          AND parent_node_type_id = @parentTypeId
          AND child_node_type_id = @childTypeId
        RETURNING parent_node_type_id::text AS id
      '''),
      parameters: {'projectId': projectId, 'parentTypeId': parentTypeId, 'childTypeId': childTypeId},
    );
    _ensureFound(rows, 'Relación no encontrada.');
  }

  Future<String> createNode(String projectId, Map<String, dynamic> body) {
    return connection.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO hierarchy_nodes (
            project_id, node_type_id, parent_id, code, name, description, sort_order
          )
          VALUES (@projectId, @typeId, @parentId, @code, @name, @description, @order)
          RETURNING id::text AS id
        '''),
        parameters: _nodeParams(projectId, body),
      );
      final nodeId = rows.first[0] as String;
      await _replaceNodeValues(tx, projectId, nodeId, _readValues(body));
      return nodeId;
    });
  }

  Future<void> updateNode(String projectId, String nodeId, Map<String, dynamic> body) {
    return connection.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          UPDATE hierarchy_nodes
          SET
            node_type_id = @typeId,
            parent_id = @parentId,
            code = @code,
            name = @name,
            description = @description,
            sort_order = @order
          WHERE project_id = @projectId
            AND id = @nodeId
          RETURNING id::text AS id
        '''),
        parameters: {..._nodeParams(projectId, body), 'nodeId': nodeId},
      );
      _ensureFound(rows, 'Nodo no encontrado.');
      await _replaceNodeValues(tx, projectId, nodeId, _readValues(body));
    });
  }

  Map<String, dynamic> _nodeParams(String projectId, Map<String, dynamic> body) {
    return {
      'projectId': projectId,
      'typeId': _requiredString(body, 'typeId'),
      'parentId': _nullIfBlank(_optionalString(body, 'parentId')),
      'code': _nullIfBlank(_optionalString(body, 'code')),
      'name': _requiredString(body, 'name'),
      'description': _nullIfBlank(_optionalString(body, 'description')),
      'order': _parseInt(body['order'], fallback: 10),
    };
  }

  Map<String, dynamic> _readValues(Map<String, dynamic> body) {
    final values = body['values'];
    if (values is! Map) {
      return const {};
    }
    return Map<String, dynamic>.from(values.cast<String, dynamic>());
  }

  Future<void> _replaceNodeValues(TxSession tx, String projectId, String nodeId, Map<String, dynamic> values) async {
    await tx.execute(
      Sql.named('DELETE FROM node_attribute_values WHERE project_id = @projectId AND node_id = @nodeId'),
      parameters: {'projectId': projectId, 'nodeId': nodeId},
    );
    for (final entry in values.entries) {
      final attributeId = entry.key.trim();
      final rawValue = entry.value?.toString().trim() ?? '';
      if (attributeId.isEmpty || rawValue.isEmpty) {
        continue;
      }
      final rows = await tx.execute(
        Sql.named('SELECT data_type FROM attribute_definitions WHERE project_id = @projectId AND id = @attributeId'),
        parameters: {'projectId': projectId, 'attributeId': attributeId},
      );
      _ensureFound(rows, 'Atributo no encontrado.');
      final parsed = _parseAttributeValue(rows.first[0] as String, rawValue);
      await tx.execute(
        Sql.named('''
          INSERT INTO node_attribute_values (
            project_id, node_id, attribute_definition_id, value_text, value_number, value_date, value_boolean, value_json
          )
          VALUES (
            @projectId, @nodeId, @attributeId, @valueText, @valueNumber, CAST(@valueDate AS date), @valueBoolean, CAST(@valueJson AS jsonb)
          )
        '''),
        parameters: {
          'projectId': projectId,
          'nodeId': nodeId,
          'attributeId': attributeId,
          'valueText': parsed.valueText,
          'valueNumber': parsed.valueNumber,
          'valueDate': parsed.valueDate,
          'valueBoolean': parsed.valueBoolean,
          'valueJson': parsed.valueJson,
        },
      );
    }
  }

  Future<void> deleteNode(String projectId, String nodeId) async {
    final rows = await connection.execute(
      Sql.named('DELETE FROM hierarchy_nodes WHERE project_id = @projectId AND id = @nodeId RETURNING id::text AS id'),
      parameters: {'projectId': projectId, 'nodeId': nodeId},
    );
    _ensureFound(rows, 'Nodo no encontrado.');
  }

  Future<void> _ensureProjectExists(String projectId, {Session? session}) async {
    final activeSession = session ?? connection;
    final rows = await activeSession.execute(
      Sql.named('SELECT id::text AS id FROM projects WHERE id = @projectId'),
      parameters: {'projectId': projectId},
    );
    _ensureFound(rows, 'Proyecto no encontrado.');
  }

  Future<void> _ensureProfileExists(String projectId, String profileId, {required Session session}) async {
    final rows = await session.execute(
      Sql.named('''
        SELECT id::text AS id
        FROM project_profiles
        WHERE project_id = @projectId
          AND id = @profileId
      '''),
      parameters: {'projectId': projectId, 'profileId': profileId},
    );
    _ensureFound(rows, 'Perfil no encontrado.');
  }

  Future<void> _validatePermissionCodes(List<String> permissionCodes, {required Session session}) async {
    if (permissionCodes.isEmpty) {
      throw const ApiError(400, 'Debes indicar al menos un permiso para el perfil.');
    }
    final rows = await session.execute(
      Sql.named('SELECT code FROM permission_catalog WHERE code = ANY(@codes)'),
      parameters: {'codes': permissionCodes},
    );
    final found = rows.map((row) => row[0].toString()).toSet();
    final missing = permissionCodes.where((code) => !found.contains(code)).toList();
    if (missing.isNotEmpty) {
      throw ApiError(400, 'Permisos inválidos: ${missing.join(', ')}.');
    }
  }

  Future<void> _syncProjectProfilePermissions(
    TxSession tx,
    String projectId,
    String profileId,
    List<String> permissionCodes,
  ) async {
    await tx.execute(
      Sql.named('DELETE FROM project_profile_permissions WHERE project_id = @projectId AND profile_id = @profileId'),
      parameters: {'projectId': projectId, 'profileId': profileId},
    );
    for (final code in permissionCodes.toSet().toList()..sort()) {
      await tx.execute(
        Sql.named('''
          INSERT INTO project_profile_permissions (project_id, profile_id, permission_code)
          VALUES (@projectId, @profileId, @permissionCode)
        '''),
        parameters: {'projectId': projectId, 'profileId': profileId, 'permissionCode': code},
      );
    }
  }

  Future<Map<String, dynamic>> _loadNodeDocumentTarget(String projectId, String nodeId, {Session? session}) async {
    final activeSession = session ?? connection;
    final rows = await activeSession.execute(
      Sql.named('''
        SELECT
          n.id::text AS "nodeId",
          COALESCE(n.code, '') AS "nodeCode",
          n.name AS "nodeName",
          t.id::text AS "nodeTypeId",
          t.name AS "nodeTypeName",
          t.allows_documents AS "acceptsDocs"
        FROM hierarchy_nodes n
        JOIN hierarchy_node_types t
          ON t.project_id = n.project_id
         AND t.id = n.node_type_id
        WHERE n.project_id = @projectId
          AND n.id = @nodeId
      '''),
      parameters: {'projectId': projectId, 'nodeId': nodeId},
    );
    _ensureFound(rows, 'Nodo no encontrado.');
    final map = _rowMap(rows.first);
    if (!_columnBool(map, 'acceptsDocs')) {
      throw const ApiError(400, 'El nodo seleccionado no acepta documentos.');
    }
    return map;
  }

  Future<ScanDocumentTypeBinding> _ensureScanDocumentType(
    TxSession tx,
    String projectId,
    Map<String, dynamic> nodeTarget,
  ) async {
    final nodeTypeId = _requiredColumnString(nodeTarget, 'nodeTypeId');
    final nodeTypeName = _requiredColumnString(nodeTarget, 'nodeTypeName');
    final documentTypeCode = 'scan-node-$nodeTypeId';

    final documentTypeRows = await tx.execute(
      Sql.named('''
        INSERT INTO document_types (project_id, code, name, description)
        VALUES (@projectId, @code, @name, @description)
        ON CONFLICT (project_id, code) DO UPDATE
        SET
          name = EXCLUDED.name,
          description = EXCLUDED.description
        RETURNING id::text AS id
      '''),
      parameters: {
        'projectId': projectId,
        'code': documentTypeCode,
        'name': 'Documento escaneado - $nodeTypeName',
        'description': 'Tipo documental autogenerado para capturas desde el nodo/tipo $nodeTypeName.',
      },
    );
    final documentTypeId = documentTypeRows.first[0] as String;

    final nodeAttributeRows = await tx.execute(
      Sql.named('''
        SELECT
          ad.id::text AS "nodeAttributeId",
          ad.code,
          ad.name,
          ad.data_type AS "dataType",
          ad.is_required AS "isRequired",
          COALESCE(ad.default_value, '') AS "defaultValue",
          COALESCE(ad.help_text, '') AS "helpText",
          COALESCE(ad.type_extension::text, '') AS extension,
          COALESCE(ad.validation_regex, '') AS regex,
          nta.display_order AS "displayOrder"
        FROM node_type_attributes nta
        JOIN attribute_definitions ad
          ON ad.project_id = nta.project_id
         AND ad.id = nta.attribute_definition_id
        WHERE nta.project_id = @projectId
          AND nta.node_type_id = @nodeTypeId
        ORDER BY nta.display_order, ad.name
      '''),
      parameters: {'projectId': projectId, 'nodeTypeId': nodeTypeId},
    );

    final nodeAttributeIds = nodeAttributeRows.map((row) => _requiredColumnString(_rowMap(row), 'nodeAttributeId')).toList();
    final optionRows = nodeAttributeIds.isEmpty
        ? const <ResultRow>[]
        : await tx.execute(
            Sql.named('''
              SELECT
                attribute_definition_id::text AS "nodeAttributeId",
                code,
                label,
                sort_order AS "sortOrder"
              FROM attribute_options
              WHERE project_id = @projectId
                AND attribute_definition_id = ANY(@attributeIds)
                AND is_active = true
              ORDER BY attribute_definition_id, sort_order, label
            '''),
            parameters: {'projectId': projectId, 'attributeIds': nodeAttributeIds},
          );

    final optionsByNodeAttributeId = <String, List<Map<String, dynamic>>>{};
    for (final row in optionRows) {
      final map = _rowMap(row);
      final nodeAttributeId = _requiredColumnString(map, 'nodeAttributeId');
      optionsByNodeAttributeId.putIfAbsent(nodeAttributeId, () => []).add({
        'code': _requiredColumnString(map, 'code'),
        'label': _requiredColumnString(map, 'label'),
        'sortOrder': _columnInt(map, 'sortOrder'),
      });
    }

    final binding = <String, GeneratedDocumentAttributeBinding>{};
    for (final row in nodeAttributeRows) {
      final map = _rowMap(row);
      final nodeAttributeId = _requiredColumnString(map, 'nodeAttributeId');
      final generatedCode = 'scan-${nodeAttributeId.replaceAll('-', '').substring(0, 12)}';
      final settingsJson = jsonEncode({
        'capture_mode': 'scan_mirror',
        'generated_from_node_attribute_id': nodeAttributeId,
        'generated_from_node_type_id': nodeTypeId,
      });

      final existingDocumentAttributeRows = await tx.execute(
        Sql.named('''
          SELECT id::text AS id
          FROM attribute_definitions
          WHERE project_id = @projectId
            AND scope = 'document'
            AND COALESCE(settings_json ->> 'generated_from_node_attribute_id', '') = @nodeAttributeId
          LIMIT 1
        '''),
        parameters: {'projectId': projectId, 'nodeAttributeId': nodeAttributeId},
      );

      late final String documentAttributeId;
      if (existingDocumentAttributeRows.isEmpty) {
        final inserted = await tx.execute(
          Sql.named('''
            INSERT INTO attribute_definitions (
              project_id,
              scope,
              code,
              name,
              data_type,
              is_required,
              default_value,
              help_text,
              type_extension,
              validation_regex,
              settings_json
            )
            VALUES (
              @projectId,
              'document',
              @code,
              @name,
              @dataType,
              @isRequired,
              @defaultValue,
              @helpText,
              @typeExtension,
              @validationRegex,
              CAST(@settingsJson AS jsonb)
            )
            RETURNING id::text AS id
          '''),
          parameters: {
            'projectId': projectId,
            'code': generatedCode,
            'name': _requiredColumnString(map, 'name'),
            'dataType': _requiredColumnString(map, 'dataType'),
            'isRequired': _columnBool(map, 'isRequired'),
            'defaultValue': _nullIfBlank((_columnValue(map, 'defaultValue') ?? '').toString()),
            'helpText': _nullIfBlank((_columnValue(map, 'helpText') ?? '').toString()),
            'typeExtension': _parseNullableInt(_columnValue(map, 'extension')),
            'validationRegex': _nullIfBlank((_columnValue(map, 'regex') ?? '').toString()),
            'settingsJson': settingsJson,
          },
        );
        documentAttributeId = inserted.first[0] as String;
      } else {
        documentAttributeId = existingDocumentAttributeRows.first[0] as String;
        await tx.execute(
          Sql.named('''
            UPDATE attribute_definitions
            SET
              code = @code,
              name = @name,
              data_type = @dataType,
              is_required = @isRequired,
              default_value = @defaultValue,
              help_text = @helpText,
              type_extension = @typeExtension,
              validation_regex = @validationRegex,
              validation_message = NULL,
              settings_json = CAST(@settingsJson AS jsonb),
              is_active = true
            WHERE project_id = @projectId
              AND id = @attributeId
          '''),
          parameters: {
            'projectId': projectId,
            'attributeId': documentAttributeId,
            'code': generatedCode,
            'name': _requiredColumnString(map, 'name'),
            'dataType': _requiredColumnString(map, 'dataType'),
            'isRequired': _columnBool(map, 'isRequired'),
            'defaultValue': _nullIfBlank((_columnValue(map, 'defaultValue') ?? '').toString()),
            'helpText': _nullIfBlank((_columnValue(map, 'helpText') ?? '').toString()),
            'typeExtension': _parseNullableInt(_columnValue(map, 'extension')),
            'validationRegex': _nullIfBlank((_columnValue(map, 'regex') ?? '').toString()),
            'settingsJson': settingsJson,
          },
        );
      }

      await tx.execute(
        Sql.named('DELETE FROM attribute_options WHERE project_id = @projectId AND attribute_definition_id = @attributeId'),
        parameters: {'projectId': projectId, 'attributeId': documentAttributeId},
      );

      final nodeAttributeOptions = optionsByNodeAttributeId[nodeAttributeId] ?? const <Map<String, dynamic>>[];
      for (final option in nodeAttributeOptions) {
        await tx.execute(
          Sql.named('''
            INSERT INTO attribute_options (
              project_id,
              attribute_definition_id,
              code,
              label,
              sort_order
            )
            VALUES (
              @projectId,
              @attributeId,
              @code,
              @label,
              @sortOrder
            )
          '''),
          parameters: {
            'projectId': projectId,
            'attributeId': documentAttributeId,
            'code': option['code'],
            'label': option['label'],
            'sortOrder': option['sortOrder'],
          },
        );
      }

      binding[nodeAttributeId] = GeneratedDocumentAttributeBinding(
        documentAttributeId: documentAttributeId,
        dataType: _requiredColumnString(map, 'dataType'),
      );
    }

    await tx.execute(
      Sql.named('DELETE FROM document_type_attributes WHERE project_id = @projectId AND document_type_id = @documentTypeId'),
      parameters: {'projectId': projectId, 'documentTypeId': documentTypeId},
    );

    for (final row in nodeAttributeRows) {
      final map = _rowMap(row);
      final nodeAttributeId = _requiredColumnString(map, 'nodeAttributeId');
      final generated = binding[nodeAttributeId];
      if (generated == null) {
        continue;
      }
      await tx.execute(
        Sql.named('''
          INSERT INTO document_type_attributes (
            project_id,
            document_type_id,
            attribute_definition_id,
            display_order
          )
          VALUES (
            @projectId,
            @documentTypeId,
            @attributeId,
            @displayOrder
          )
        '''),
        parameters: {
          'projectId': projectId,
          'documentTypeId': documentTypeId,
          'attributeId': generated.documentAttributeId,
          'displayOrder': _columnInt(map, 'displayOrder'),
        },
      );
    }

    return ScanDocumentTypeBinding(
      documentTypeId: documentTypeId,
      attributesBySourceNodeAttributeId: binding,
    );
  }

  Future<void> _replaceDocumentValues(
    TxSession tx,
    String projectId,
    String documentId,
    Map<String, dynamic> values,
    Map<String, GeneratedDocumentAttributeBinding> binding,
  ) async {
    await tx.execute(
      Sql.named('DELETE FROM document_attribute_values WHERE project_id = @projectId AND document_id = @documentId'),
      parameters: {'projectId': projectId, 'documentId': documentId},
    );

    for (final entry in values.entries) {
      final sourceNodeAttributeId = entry.key.trim();
      final rawValue = entry.value?.toString().trim() ?? '';
      if (sourceNodeAttributeId.isEmpty || rawValue.isEmpty) {
        continue;
      }

      final generated = binding[sourceNodeAttributeId];
      if (generated == null) {
        throw const ApiError(400, 'Se recibió un atributo que no pertenece al tipo del nodo.');
      }

      final parsed = _parseAttributeValue(generated.dataType, rawValue);
      await tx.execute(
        Sql.named('''
          INSERT INTO document_attribute_values (
            project_id,
            document_id,
            attribute_definition_id,
            value_text,
            value_number,
            value_date,
            value_boolean,
            value_json
          )
          VALUES (
            @projectId,
            @documentId,
            @attributeId,
            @valueText,
            @valueNumber,
            CAST(@valueDate AS date),
            @valueBoolean,
            CAST(@valueJson AS jsonb)
          )
        '''),
        parameters: {
          'projectId': projectId,
          'documentId': documentId,
          'attributeId': generated.documentAttributeId,
          'valueText': parsed.valueText,
          'valueNumber': parsed.valueNumber,
          'valueDate': parsed.valueDate,
          'valueBoolean': parsed.valueBoolean,
          'valueJson': parsed.valueJson,
        },
      );
    }
  }

  Future<StoredPdfArtifact> _storeDocumentPdf({
    required String projectId,
    required String documentId,
    required int versionNumber,
    required String title,
    required List<int> pdfBytes,
  }) async {
    final safeTitle = _slugify(title);
    final versionFolder = 'v${versionNumber.toString().padLeft(3, '0')}';
    final storageDir = Directory(
      '${repoRoot.path}${Platform.pathSeparator}sgd_storage${Platform.pathSeparator}documents${Platform.pathSeparator}$projectId${Platform.pathSeparator}$documentId${Platform.pathSeparator}$versionFolder',
    );
    await storageDir.create(recursive: true);

    final fileName = '$safeTitle.pdf';
    final filePath = '${storageDir.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);

    return StoredPdfArtifact(
      storagePath: file.path,
      originalName: fileName,
      extension: 'pdf',
      sizeBytes: pdfBytes.length,
    );
  }

  Future<Map<String, dynamic>> _fetchScannerSession(String sessionId) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(scannerBaseUrl.resolve('/api/scans/$sessionId'));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.trim().isEmpty ? <String, dynamic>{} : jsonDecode(text);
      final json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

      if (response.statusCode >= 400) {
        throw ApiError(
          response.statusCode == 404 ? 400 : 502,
          response.statusCode == 404
              ? 'La sesión de escaneo ya no existe en windows-twain.'
              : (json['message'] ?? json['error'] ?? 'windows-twain respondió HTTP ${response.statusCode}.').toString(),
        );
      }

      return json;
    } on SocketException catch (error) {
      throw ApiError(502, 'No se pudo conectar con windows-twain en ${scannerBaseUrl.toString()}: ${error.message}');
    } on HttpException catch (error) {
      throw ApiError(502, 'Error HTTP al comunicarse con windows-twain: ${error.message}');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<int>> _downloadScannerPdf(String sessionId) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(scannerBaseUrl.resolve('/api/scans/$sessionId/pdf'));
      final response = await request.close();
      final bytes = await response.fold<List<int>>(<int>[], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      });

      if (response.statusCode >= 400) {
        final text = utf8.decode(bytes, allowMalformed: true);
        var message = 'No se pudo descargar el PDF desde windows-twain.';
        if (text.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(text);
            if (decoded is Map<String, dynamic>) {
              message = (decoded['message'] ?? decoded['error'] ?? message).toString();
            } else {
              message = text;
            }
          } catch (_) {
            message = text;
          }
        }
        throw ApiError(response.statusCode == 404 ? 400 : 502, message);
      }

      return bytes;
    } on SocketException catch (error) {
      throw ApiError(502, 'No se pudo conectar con windows-twain en ${scannerBaseUrl.toString()}: ${error.message}');
    } on HttpException catch (error) {
      throw ApiError(502, 'Error HTTP al comunicarse con windows-twain: ${error.message}');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _localProviderId(Session session) async {
    final rows = await session.execute(
      Sql.named('SELECT id::text AS id FROM auth_providers WHERE code = @code AND is_enabled = true'),
      parameters: {'code': 'local'},
    );
    _ensureFound(rows, 'No existe el proveedor local de autenticación.');
    return rows.first[0] as String;
  }
}

class ScanDocumentTypeBinding {
  const ScanDocumentTypeBinding({
    required this.documentTypeId,
    required this.attributesBySourceNodeAttributeId,
  });

  final String documentTypeId;
  final Map<String, GeneratedDocumentAttributeBinding> attributesBySourceNodeAttributeId;
}

class GeneratedDocumentAttributeBinding {
  const GeneratedDocumentAttributeBinding({
    required this.documentAttributeId,
    required this.dataType,
  });

  final String documentAttributeId;
  final String dataType;
}

class StoredPdfArtifact {
  const StoredPdfArtifact({
    required this.storagePath,
    required this.originalName,
    required this.extension,
    required this.sizeBytes,
  });

  final String storagePath;
  final String originalName;
  final String extension;
  final int sizeBytes;
}

class ParsedAttributeValue {
  const ParsedAttributeValue({this.valueText, this.valueNumber, this.valueDate, this.valueBoolean, this.valueJson});

  final String? valueText;
  final num? valueNumber;
  final String? valueDate;
  final bool? valueBoolean;
  final String? valueJson;
}

ParsedAttributeValue _parseAttributeValue(String dataType, String rawValue) {
  switch (dataType) {
    case 'string':
    case 'list':
      return ParsedAttributeValue(valueText: rawValue);
    case 'integer':
      return ParsedAttributeValue(valueNumber: int.parse(rawValue));
    case 'decimal':
      return ParsedAttributeValue(valueNumber: num.parse(rawValue));
    case 'date':
      DateTime.parse(rawValue);
      return ParsedAttributeValue(valueDate: rawValue);
    case 'boolean':
      final normalized = rawValue.toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'si' || normalized == 'sí') {
        return const ParsedAttributeValue(valueBoolean: true);
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return const ParsedAttributeValue(valueBoolean: false);
      }
      throw const ApiError(400, 'El valor boolean debe ser true/false, 1/0, si/no.');
    case 'json':
      return ParsedAttributeValue(valueJson: jsonEncode(jsonDecode(rawValue)));
    default:
      throw ApiError(400, 'Tipo de dato no soportado: $dataType');
  }
}

Response _jsonResponse(Object body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: const {HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'},
  );
}

Future<Map<String, dynamic>> _readJsonMap(Request request) async {
  final text = await request.readAsString();
  if (text.trim().isEmpty) {
    return <String, dynamic>{};
  }
  final decoded = jsonDecode(text);
  if (decoded is! Map) {
    throw const ApiError(400, 'El body debe ser un objeto JSON.');
  }
  return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
}

String _requiredString(Map<String, dynamic> body, String key) {
  final value = _optionalString(body, key);
  if (value == null || value.isEmpty) {
    throw ApiError(400, 'Falta $key.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _readDocumentAttributeValues(Map<String, dynamic> body) {
  final value = body['attributeValues'];
  if (value is! Map) {
    return const {};
  }
  return Map<String, dynamic>.from(value.cast<String, dynamic>());
}

List<String> _readStringList(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
}

int _parseInt(Object? value, {required int fallback}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _parseNullableInt(Object? value) {
  final parsed = int.tryParse(value?.toString().trim() ?? '');
  return parsed;
}

String? _nullIfBlank(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void _ensureFound(Result result, String message) {
  if (result.isEmpty) {
    throw ApiError(404, message);
  }
}

String _slugify(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'item' : normalized;
}

String _contentDispositionName(String fileName) {
  final cleaned = fileName.replaceAll('"', '').trim();
  return cleaned.isEmpty ? 'documento.pdf' : cleaned;
}

Map<String, dynamic> _rowMap(ResultRow row) {
  return row.toColumnMap().map((key, value) => MapEntry(key.toString(), value));
}

Object? _columnValue(Map<String, dynamic> row, String key) {
  if (row.containsKey(key)) {
    return row[key];
  }
  final lowercase = key.toLowerCase();
  if (row.containsKey(lowercase)) {
    return row[lowercase];
  }
  return null;
}

String _requiredColumnString(Map<String, dynamic> row, String key) {
  final value = _columnValue(row, key);
  if (value == null) {
    throw StateError('Falta la columna $key en el resultado SQL.');
  }
  return value.toString();
}

bool _columnBool(Map<String, dynamic> row, String key) {
  final value = _columnValue(row, key);
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 't';
}

int _columnInt(Map<String, dynamic> row, String key) {
  final value = _columnValue(row, key);
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _basename(String path) {
  final parts = path.replaceAll('\\', '/').split('/').where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? path : parts.last;
}

String? _requestIp(Request request) {
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.trim().isNotEmpty) {
    return forwarded.split(',').first.trim();
  }
  final connectionInfo = request.context['shelf.io.connection_info'];
  if (connectionInfo is HttpConnectionInfo) {
    return connectionInfo.remoteAddress.address;
  }
  return null;
}

Middleware _cors() {
  const headers = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'access-control-allow-headers': 'origin, content-type, accept, authorization',
  };
  return (inner) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await inner(request);
      return response.change(headers: {...response.headers, ...headers});
    };
  };
}

Middleware _errors() {
  return (inner) {
    return (request) async {
      try {
        return await inner(request);
      } on ApiError catch (error) {
        return _jsonResponse({'error': error.message}, statusCode: error.statusCode);
      } on FormatException catch (error) {
        return _jsonResponse({'error': error.message}, statusCode: 400);
      } catch (error, stackTrace) {
        stderr.writeln(error);
        stderr.writeln(stackTrace);
        return _jsonResponse({'error': _formatError(error)}, statusCode: 500);
      }
    };
  };
}

String _formatError(Object error) {
  final message = error.toString();
  return message.startsWith('Exception: ') ? message.substring('Exception: '.length) : message;
}

class LoginResult {
  const LoginResult({
    required this.userId,
    required this.sessionId,
    required this.token,
    required this.loginName,
  });

  final String userId;
  final String sessionId;
  final String token;
  final String loginName;
}

class AuthenticatedRequest {
  const AuthenticatedRequest({
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.isPlatformAdmin,
  });

  final String sessionId;
  final String userId;
  final String displayName;
  final bool isPlatformAdmin;
}

class AuditSpec {
  const AuditSpec({
    required this.actionCode,
    required this.accessKind,
    required this.resourceType,
    this.resourceId,
    this.details = const <String, dynamic>{},
  });

  final String actionCode;
  final String accessKind;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic> details;
}

class ApiError implements Exception {
  const ApiError(this.statusCode, this.message);

  final int statusCode;
  final String message;
}
