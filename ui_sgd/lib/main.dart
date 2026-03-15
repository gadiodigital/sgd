import 'dart:convert';

import 'package:flutter/material.dart';

import 'local_api_runtime_stub.dart'
    if (dart.library.io) 'local_api_runtime_io.dart';
import 'scan_center_page.dart';
import 'sgd_api_client.dart';

void main() => runApp(const UiSgdApp());

class UiSgdApp extends StatelessWidget {
  const UiSgdApp({
    super.key,
    this.api,
  });

  final SgdApiClient? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ui-sgd',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: AppShell(api: api ?? SgdApiClient()),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.api,
  });

  final SgdApiClient api;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AuthSessionState? session;
  bool loggingIn = false;
  String? loginError;
  bool attemptedAutoStart = false;

  Future<void> login(String loginName, String password) async {
    setState(() {
      loggingIn = true;
      loginError = null;
    });
    try {
      final response = await widget.api.login(loginName: loginName, password: password);
      final token = (response['token'] ?? '').toString();
      widget.api.setAuthToken(token);
      await _applySession(response, token: token);
    } catch (error) {
      if (_shouldAutoStartApi(error) && !attemptedAutoStart) {
        attemptedAutoStart = true;
        final started = await startLocalApiServer();
        if (started) {
          for (var attempt = 0; attempt < 5; attempt++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            try {
              final response = await widget.api.login(loginName: loginName, password: password);
              final token = (response['token'] ?? '').toString();
              widget.api.setAuthToken(token);
              await _applySession(response, token: token);
              return;
            } catch (_) {
              // The backend may still be booting.
            }
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() => loginError = _friendlyAuthError(error));
    } finally {
      if (mounted) {
        setState(() => loggingIn = false);
      }
    }
  }

  Future<void> _applySession(Map<String, dynamic> payload, {required String token}) async {
    if (!mounted) {
      return;
    }
    setState(() {
      session = AuthSessionState.fromJson(payload, token: token);
      loginError = null;
    });
  }

  Future<void> refreshSession() async {
    final token = widget.api.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      final response = await widget.api.fetchMe();
      if (!mounted) {
        return;
      }
      setState(() => session = AuthSessionState.fromJson(response, token: token));
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        await logout();
        return;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (widget.api.authToken != null) {
        await widget.api.logout();
      }
    } catch (_) {
      // Even if logout fails remotely, the local session should be cleared.
    }
    widget.api.setAuthToken(null);
    if (!mounted) {
      return;
    }
    setState(() {
      session = null;
      loginError = null;
    });
  }

  bool _shouldAutoStartApi(Object error) {
    final text = _errorText(error).toLowerCase();
    return text.contains('127.0.0.1:8081') &&
        (text.contains('connection refused') || text.contains('rechazó la conexión') || text.contains('socketexception'));
  }

  String _friendlyAuthError(Object error) {
    if (_shouldAutoStartApi(error)) {
      final command = localApiStartCommand();
      final commandText = command == null ? '' : '\n\nComando sugerido:\n$command';
      return 'No se pudo conectar con la API local SGD en http://127.0.0.1:8081.'
          '\n\nLa UI ahora necesita que `sgd_api` esté levantada para autenticar usuarios.'
          '$commandText';
    }
    return _errorText(error);
  }

  String _errorText(Object error) => error is ApiException ? error.message : error.toString();

  @override
  Widget build(BuildContext context) {
    final currentSession = session;
    if (currentSession == null) {
      return LoginView(
        loading: loggingIn,
        errorText: loginError,
        onLogin: login,
      );
    }
    return HomePage(
      api: widget.api,
      session: currentSession,
      onLogoutRequested: logout,
      onRefreshSession: refreshSession,
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.loading,
    required this.errorText,
    required this.onLogin,
  });

  final bool loading;
  final String? errorText;
  final Future<void> Function(String loginName, String password) onLogin;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController loginController;
  late final TextEditingController passwordController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loginController = TextEditingController(text: 'admin');
    passwordController = TextEditingController(text: 'admin');
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    await widget.onLogin(loginController.text.trim(), passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Ingreso', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Las credenciales locales de prueba ya vienen precargadas para desarrollo.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: loginController,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      textInputAction: TextInputAction.next,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa usuario.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => submit(),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa contraseña.' : null,
                    ),
                    if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.errorText!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: widget.loading ? null : submit,
                      child: widget.loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Ingresar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum Section { proyectos, tipos, arbol, seguridad }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.api,
    required this.session,
    required this.onLogoutRequested,
    required this.onRefreshSession,
  });

  final SgdApiClient api;
  final AuthSessionState session;
  final Future<void> Function() onLogoutRequested;
  final Future<void> Function() onRefreshSession;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final projects = <Project>[];
  final types = <NodeTypeItem>[];
  final documentTypes = <DocumentTypeItem>[];
  final rules = <RuleItem>[];
  final nodes = <NodeItem>[];
  final securityPermissions = <PermissionDefinition>[];
  final projectProfiles = <ProjectProfileItem>[];
  final projectMemberships = <ProjectUserMembershipItem>[];
  Section section = Section.proyectos;
  String? currentProjectId;
  bool loading = true;
  bool saving = false;
  String? loadError;
  bool attemptedAutoStart = false;
  bool securityLoading = false;
  String? securityError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _reloadProjects();
  }

  Future<void> _reloadProjects({
    String? selectProjectId,
    bool keepCurrentSelection = true,
  }) async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final loadedProjects = (await widget.api.listProjects()).map(Project.fromJson).toList();
      if (!mounted) {
        return;
      }

      final nextProjectId = loadedProjects.isEmpty
          ? null
          : selectProjectId ??
              (keepCurrentSelection && loadedProjects.any((project) => project.id == currentProjectId)
                  ? currentProjectId
                  : loadedProjects.first.id);

      setState(() {
        projects
          ..clear()
          ..addAll(loadedProjects);
        currentProjectId = nextProjectId;
        if (nextProjectId == null) {
          types.clear();
          documentTypes.clear();
          rules.clear();
          nodes.clear();
          securityPermissions.clear();
          projectProfiles.clear();
          projectMemberships.clear();
          securityError = null;
        }
        _ensureSectionAvailable();
      });

      if (nextProjectId != null) {
        await _reloadCurrentProject(showLoader: false);
      }
    } catch (error) {
      if (_shouldAutoStartApi(error) && !attemptedAutoStart) {
        attemptedAutoStart = true;
        final started = await startLocalApiServer();
        if (started) {
          for (var attempt = 0; attempt < 5; attempt++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            try {
              await widget.api.listProjects();
              if (!mounted) {
                return;
              }
              await _reloadProjects(
                selectProjectId: selectProjectId,
                keepCurrentSelection: keepCurrentSelection,
              );
              return;
            } catch (_) {
              // The backend may still be booting.
            }
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        loadError = _friendlyLoadError(error);
        types.clear();
        documentTypes.clear();
        rules.clear();
        nodes.clear();
        securityPermissions.clear();
        projectProfiles.clear();
        projectMemberships.clear();
        securityError = null;
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _reloadCurrentProject({bool showLoader = true}) async {
    final projectId = currentProjectId;
    if (projectId == null) {
      return;
    }
    if (showLoader) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final snapshot = await widget.api.fetchProjectSnapshot(projectId);
      if (!mounted) {
        return;
      }
      setState(() {
        loadError = null;
        types
          ..clear()
          ..addAll(((snapshot['types'] as List?) ?? const []).map((item) => NodeTypeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
        documentTypes
          ..clear()
          ..addAll(((snapshot['documentTypes'] as List?) ?? const [])
              .map((item) => DocumentTypeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
        rules
          ..clear()
          ..addAll(((snapshot['rules'] as List?) ?? const []).map((item) => RuleItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
        nodes
          ..clear()
          ..addAll(((snapshot['nodes'] as List?) ?? const []).map((item) => NodeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
        if (!can('security.read')) {
          securityPermissions.clear();
          projectProfiles.clear();
          projectMemberships.clear();
          securityError = null;
        }
        _ensureSectionAvailable();
      });
      if (section == Section.seguridad && can('security.read')) {
        await _reloadSecurity(showLoader: false);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiException && error.statusCode == 401) {
        await widget.onLogoutRequested();
        return;
      }
      setState(() => loadError = _errorText(error));
    } finally {
      if (showLoader && mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _reloadSecurity({bool showLoader = true}) async {
    final projectId = currentProjectId;
    if (projectId == null || !can('security.read', projectId)) {
      return;
    }
    if (showLoader) {
      setState(() {
        securityLoading = true;
        securityError = null;
      });
    }
    try {
      final payload = await widget.api.fetchProjectSecurity(projectId);
      if (!mounted) {
        return;
      }
      setState(() {
        securityError = null;
        securityPermissions
          ..clear()
          ..addAll(((payload['permissions'] as List?) ?? const [])
              .map((item) => PermissionDefinition.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
        projectProfiles
          ..clear()
          ..addAll(((payload['profiles'] as List?) ?? const [])
              .map((item) => ProjectProfileItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
        projectMemberships
          ..clear()
          ..addAll(((payload['memberships'] as List?) ?? const [])
              .map((item) => ProjectUserMembershipItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>()))));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiException && error.statusCode == 401) {
        await widget.onLogoutRequested();
        return;
      }
      setState(() => securityError = _errorText(error));
    } finally {
      if (showLoader && mounted) {
        setState(() => securityLoading = false);
      }
    }
  }

  Future<void> _mutate(
    Future<void> Function() action, {
    String? successMessage,
    String? selectProjectId,
    Section? nextSection,
    bool refreshSession = false,
  }) async {
    try {
      setState(() => saving = true);
      await action();
      if (refreshSession) {
        await widget.onRefreshSession();
      }
      await _reloadProjects(
        selectProjectId: selectProjectId,
        keepCurrentSelection: selectProjectId == null,
      );
      if (!mounted) {
        return;
      }
      if (nextSection != null) {
        setState(() => section = nextSection);
      }
      if (successMessage != null && successMessage.isNotEmpty) {
        snack(successMessage);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiException && error.statusCode == 401) {
        await widget.onLogoutRequested();
        return;
      }
      snack(_errorText(error));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _selectProject(String projectId, {Section? nextSection}) async {
    setState(() {
      currentProjectId = projectId;
      if (nextSection != null) {
        section = nextSection;
      }
      _ensureSectionAvailable();
    });
    await _reloadCurrentProject();
  }

  Project? get currentProject {
    for (final item in projects) {
      if (item.id == currentProjectId) {
        return item;
      }
    }
    return null;
  }

  CurrentUser get currentUser => widget.session.user;

  List<String> permissionCodesForProject(String? projectId) {
    if (currentUser.isPlatformAdmin) {
      return widget.session.allPermissionCodes;
    }
    if (projectId == null) {
      return const [];
    }
    for (final membership in widget.session.memberships) {
      if (membership.projectId == projectId) {
        return membership.permissionCodes;
      }
    }
    return const [];
  }

  bool can(String permissionCode, [String? projectId]) {
    if (currentUser.isPlatformAdmin) {
      return true;
    }
    return permissionCodesForProject(projectId ?? currentProjectId).contains(permissionCode);
  }

  List<Section> get availableSections {
    final items = <Section>[Section.proyectos];
    if (currentProjectId != null && can('types.read')) {
      items.add(Section.tipos);
    }
    if (currentProjectId != null && can('hierarchy.read')) {
      items.add(Section.arbol);
    }
    if (currentProjectId != null && can('security.read')) {
      items.add(Section.seguridad);
    }
    return items;
  }

  void _ensureSectionAvailable() {
    final options = availableSections;
    if (!options.contains(section)) {
      section = options.first;
    }
  }

  Section preferredSectionForProject(String projectId) {
    if (can('types.read', projectId)) {
      return Section.tipos;
    }
    if (can('hierarchy.read', projectId)) {
      return Section.arbol;
    }
    if (can('security.read', projectId)) {
      return Section.seguridad;
    }
    return Section.proyectos;
  }

  List<NodeTypeItem> get projectTypes => _sorted(types.where((t) => t.projectId == currentProjectId).toList(), (a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.name.compareTo(b.name));
  List<DocumentTypeItem> get projectDocumentTypes =>
      _sorted(documentTypes.where((t) => t.projectId == currentProjectId).toList(), (a, b) => a.name.compareTo(b.name));
  List<RuleItem> get projectRules => rules.where((r) => r.projectId == currentProjectId).toList();
  List<NodeItem> get projectNodes => _sorted(nodes.where((n) => n.projectId == currentProjectId).toList(), (a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.name.compareTo(b.name));

  List<T> _sorted<T>(List<T> items, int Function(T a, T b) sorter) {
    items.sort(sorter);
    return items;
  }

  static const iconChoices = <String, IconData>{
    'folder': Icons.folder,
    'inventory_2': Icons.inventory_2,
    'description': Icons.description,
    'archive': Icons.archive,
    'business': Icons.business,
    'badge': Icons.badge,
    'gavel': Icons.gavel,
    'receipt_long': Icons.receipt_long,
  };

  static const attributeDataTypes = <String>[
    'string',
    'integer',
    'decimal',
    'date',
    'boolean',
    'list',
    'json',
  ];

  void snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String _errorText(Object error) => error is ApiException ? error.message : error.toString();
  bool _shouldAutoStartApi(Object error) {
    final text = _errorText(error).toLowerCase();
    return text.contains('127.0.0.1:8081') &&
        (text.contains('connection refused') || text.contains('rechazó la conexión') || text.contains('socketexception'));
  }

  String _friendlyLoadError(Object error) {
    if (_shouldAutoStartApi(error)) {
      final command = localApiStartCommand();
      final commandText = command == null ? '' : '\n\nComando sugerido:\n$command';
      return 'No se pudo conectar con la API local SGD en http://127.0.0.1:8081.'
          '\n\nLa UI ahora necesita que `sgd_api` esté levantada para leer y guardar datos.'
          '$commandText';
    }
    return _errorText(error);
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  void _focusNext(BuildContext context) => FocusScope.of(context).nextFocus();
  IconData iconFor(String key) => iconChoices[key] ?? Icons.folder;
  String attributeTypeLabel(String dataType) => switch (dataType) {
        'string' => 'string',
        'integer' => 'integer',
        'decimal' => 'decimal',
        'date' => 'date',
        'boolean' => 'boolean',
        'list' => 'list (combo)',
        'json' => 'json',
        _ => dataType,
      };
  String attributeValueLabel(AttributeItem attr, String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return '-';
    }
    if (attr.dataType != 'list') {
      return rawValue;
    }
    for (final option in attr.options) {
      if (option.code == rawValue) {
        return option.label;
      }
    }
    return rawValue;
  }
  bool _hasAttributeValue(String? rawValue) => rawValue != null && rawValue.trim().isNotEmpty;
  String attributeSummary(AttributeItem attr) {
    final parts = <String>[attributeTypeLabel(attr.dataType)];
    if (attr.dataType == 'list') {
      parts.add(attr.options.isEmpty ? 'sin opciones' : '${attr.options.length} opciones');
      return parts.join(' • ');
    }
    if (attr.extension.isNotEmpty) {
      parts.add('ext ${attr.extension}');
    }
    if (attr.regex.isNotEmpty) {
      parts.add('regex');
    }
    return parts.join(' • ');
  }
  TextInputType keyboardTypeForAttribute(String dataType) => switch (dataType) {
        'integer' => TextInputType.number,
        'decimal' => const TextInputType.numberWithOptions(decimal: true),
        _ => TextInputType.text,
      };
  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $label.';
    }
    return null;
  }

  String? _validateProjectSlug(String? value, String? excludeProjectId) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa slug.';
    }
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(text)) {
      return 'Usa minúsculas, números y guiones.';
    }
    if (projects.any((project) => project.slug == text && project.id != excludeProjectId)) {
      return 'Ese slug ya existe.';
    }
    return null;
  }

  String? _validateIdentifierCode(String? value, {String label = 'código'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa $label.';
    }
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text)) {
      return 'Usa letras, números, guion o guion bajo.';
    }
    return null;
  }

  String? _validateLoginName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa usuario.';
    }
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(text)) {
      return 'Usa minúsculas, números, punto, guion o guion bajo.';
    }
    return null;
  }

  String? _validateOrder(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa orden.';
    }
    final parsed = int.tryParse(text);
    if (parsed == null) {
      return 'Debe ser un número entero.';
    }
    if (parsed < 0) {
      return 'No puede ser negativo.';
    }
    return null;
  }

  bool _isValidRegex(String value) {
    try {
      RegExp(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _validateAttributeRawValue(AttributeItem attr, String value) {
    if (value.isEmpty) {
      return null;
    }
    switch (attr.dataType) {
      case 'integer':
        return int.tryParse(value) == null ? 'Debe ser un entero.' : null;
      case 'decimal':
        return num.tryParse(value) == null ? 'Debe ser un decimal válido.' : null;
      case 'date':
        return DateTime.tryParse(value) == null ? 'Usa una fecha válida, por ejemplo 2026-03-15.' : null;
      case 'boolean':
        final normalized = value.toLowerCase();
        return const {'true', 'false', '1', '0', 'si', 'sí', 'no'}.contains(normalized)
            ? null
            : 'Usa true/false, 1/0 o si/no.';
      case 'json':
        try {
          jsonDecode(value);
          return null;
        } catch (_) {
          return 'Ingresa JSON válido.';
        }
      default:
        if (attr.extension.isNotEmpty) {
          final maxLength = int.tryParse(attr.extension);
          if (maxLength != null && value.length > maxLength) {
            return 'Máximo $maxLength caracteres.';
          }
        }
        if (attr.regex.isNotEmpty && !RegExp(attr.regex).hasMatch(value)) {
          return 'No cumple la validación.';
        }
        return null;
    }
  }

  NodeTypeItem? typeById(String id) {
    for (final item in projectTypes) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  NodeItem? nodeById(String id) {
    for (final item in projectNodes) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
  List<NodeItem> childrenOf(String? parentId) => projectNodes.where((n) => n.parentId == parentId).toList();
  List<NodeTypeItem> childTypesOf(String parentTypeId) {
    final ids = projectRules.where((r) => r.parentTypeId == parentTypeId).map((r) => r.childTypeId).toSet();
    return projectTypes.where((t) => ids.contains(t.id)).toList();
  }

  Future<void> addProject([Project? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final slug = TextEditingController(text: existing?.slug ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          if (!(formKey.currentState?.validate() ?? false)) {
            return;
          }
          Navigator.pop(dialogContext, {
            'name': name.text.trim(),
            'slug': slug.text.trim(),
            'description': description.text.trim(),
          });
        }

        return AlertDialog(
          title: Text(existing == null ? 'Nuevo proyecto' : 'Editar proyecto'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _focusNext(dialogContext),
                    validator: (value) => _validateRequired(value, 'nombre'),
                  ),
                  TextFormField(
                    controller: slug,
                    decoration: const InputDecoration(labelText: 'Slug'),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => submit(),
                    validator: (value) => _validateProjectSlug(value, existing?.id),
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(onPressed: submit, child: const Text('Guardar')),
          ],
        );
      },
    );
    if (data == null) return;
    if (existing == null) {
      try {
        setState(() => saving = true);
        final createdId = await widget.api.createProject({
          'name': data['name'],
          'slug': data['slug'],
          'description': data['description'],
        });
        await _reloadProjects(selectProjectId: createdId);
        if (!mounted) {
          return;
        }
        setState(() => section = Section.tipos);
      } catch (error) {
        if (mounted) {
          snack(_errorText(error));
        }
      } finally {
        if (mounted) {
          setState(() => saving = false);
        }
      }
      return;
    }
    await _mutate(() {
      return widget.api.updateProject(existing.id, {
        'name': data['name'],
        'slug': data['slug'],
        'description': data['description'],
      });
    }, selectProjectId: existing.id);
  }

  Future<void> addOrEditProfile([ProjectProfileItem? existing]) async {
    if (currentProject == null) return snack('Selecciona un proyecto.');
    final code = TextEditingController(text: existing?.code ?? '');
    final name = TextEditingController(text: existing?.name ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    var isActive = existing?.isActive ?? true;
    final selectedPermissions = <String>{...(existing?.permissionCodes ?? securityPermissions.map((item) => item.code))};
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setInner) {
          void submit() {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.pop(dialogContext, {
              'code': code.text.trim(),
              'name': name.text.trim(),
              'description': description.text.trim(),
              'isActive': isActive,
              'permissionCodes': selectedPermissions.toList()..sort(),
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'Nuevo perfil' : 'Editar perfil'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: code,
                        enabled: existing?.isSystem != true,
                        decoration: const InputDecoration(labelText: 'Código'),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final base = _validateIdentifierCode(value, label: 'código del perfil');
                          if (base != null) {
                            return base;
                          }
                          final text = value!.trim();
                          if (projectProfiles.any((profile) => profile.code == text && profile.id != existing?.id)) {
                            return 'Ese código ya existe.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        textInputAction: TextInputAction.next,
                        validator: (value) => _validateRequired(value, 'nombre'),
                      ),
                      TextFormField(
                        controller: description,
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        minLines: 2,
                        maxLines: 3,
                      ),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (value) => setInner(() => isActive = value),
                        title: const Text('Perfil activo'),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Permisos', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 8),
                      ...securityPermissions.map((permission) => CheckboxListTile(
                            value: selectedPermissions.contains(permission.code),
                            title: Text(permission.name),
                            subtitle: Text('${permission.code} • ${permission.accessKind}'),
                            onChanged: (value) => setInner(() {
                              if (value == true) {
                                selectedPermissions.add(permission.code);
                              } else {
                                selectedPermissions.remove(permission.code);
                              }
                            }),
                          )),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(onPressed: submit, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (data == null) return;
    if (existing == null) {
      await _mutate(() async {
        await widget.api.createProjectProfile(currentProjectId!, data);
        await _reloadSecurity(showLoader: false);
      }, selectProjectId: currentProjectId, refreshSession: true, nextSection: Section.seguridad);
      return;
    }
    await _mutate(() async {
      await widget.api.updateProjectProfile(currentProjectId!, existing.id, data);
      await _reloadSecurity(showLoader: false);
    }, selectProjectId: currentProjectId, refreshSession: true, nextSection: Section.seguridad);
  }

  Future<void> addOrEditMembership([ProjectUserMembershipItem? existing]) async {
    if (currentProject == null) return snack('Selecciona un proyecto.');
    final displayName = TextEditingController(text: existing?.displayName ?? '');
    final loginName = TextEditingController(text: existing?.loginName ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var profileId = existing?.profileId ?? (projectProfiles.isNotEmpty ? projectProfiles.first.id : '');
    var membershipActive = existing?.isActive ?? true;
    var userActive = existing?.userActive ?? true;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setInner) {
          void submit() {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.pop(dialogContext, {
              'displayName': displayName.text.trim(),
              'loginName': loginName.text.trim(),
              'email': email.text.trim(),
              'password': password.text,
              'profileId': profileId,
              'isActive': membershipActive,
              'userActive': userActive,
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'Nuevo acceso' : 'Editar acceso'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: displayName,
                        decoration: const InputDecoration(labelText: 'Nombre visible'),
                        textInputAction: TextInputAction.next,
                        validator: (value) => _validateRequired(value, 'nombre visible'),
                      ),
                      TextFormField(
                        controller: loginName,
                        enabled: existing == null,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        textInputAction: TextInputAction.next,
                        validator: _validateLoginName,
                      ),
                      TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        textInputAction: TextInputAction.next,
                      ),
                      TextFormField(
                        controller: password,
                        decoration: InputDecoration(labelText: existing == null ? 'Contraseña' : 'Nueva contraseña'),
                        obscureText: true,
                        validator: (value) {
                          if (existing == null && (value == null || value.isEmpty)) {
                            return 'Ingresa contraseña.';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: profileId.isEmpty ? null : profileId,
                        decoration: const InputDecoration(labelText: 'Perfil'),
                        items: projectProfiles.map((profile) => DropdownMenuItem(value: profile.id, child: Text(profile.name))).toList(),
                        onChanged: (value) => setInner(() => profileId = value ?? ''),
                        validator: (value) => value == null || value.isEmpty ? 'Selecciona perfil.' : null,
                      ),
                      SwitchListTile(
                        value: membershipActive,
                        onChanged: (value) => setInner(() => membershipActive = value),
                        title: const Text('Acceso activo en el proyecto'),
                      ),
                      SwitchListTile(
                        value: userActive,
                        onChanged: (value) => setInner(() => userActive = value),
                        title: const Text('Usuario activo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(onPressed: submit, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (data == null) return;
    if (existing == null) {
      await _mutate(() async {
        await widget.api.createProjectMembership(currentProjectId!, data);
        await _reloadSecurity(showLoader: false);
      }, selectProjectId: currentProjectId, refreshSession: true, nextSection: Section.seguridad);
      return;
    }
    await _mutate(() async {
      await widget.api.updateProjectMembership(currentProjectId!, existing.userId, data);
      await _reloadSecurity(showLoader: false);
    }, selectProjectId: currentProjectId, refreshSession: true, nextSection: Section.seguridad);
  }

  Future<void> addType([NodeTypeItem? existing]) async {
    if (currentProject == null) return snack('Selecciona un proyecto.');
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final order = TextEditingController(text: '${existing?.order ?? 10}');
    final formKey = GlobalKey<FormState>();
    var root = existing?.root ?? false;
    var acceptsDocs = existing?.acceptsDocs ?? true;
    var iconKey = existing?.iconKey ?? 'folder';
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setInner) {
          void submit() {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.pop(dialogContext, {
              'name': name.text.trim(),
              'code': code.text.trim(),
              'description': description.text.trim(),
              'root': root,
              'docs': acceptsDocs,
              'iconKey': iconKey,
              'order': int.parse(order.text.trim()),
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'Nuevo tipo' : 'Editar tipo'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _focusNext(dialogContext),
                    validator: (value) => _validateRequired(value, 'nombre'),
                  ),
                  TextFormField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Código'),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _focusNext(dialogContext),
                    validator: (value) {
                      final base = _validateIdentifierCode(value);
                      if (base != null) {
                        return base;
                      }
                      final text = value!.trim();
                      if (projectTypes.any((type) => type.code == text && type.id != existing?.id)) {
                        return 'Ese código ya existe.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: order,
                    decoration: const InputDecoration(labelText: 'Orden'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _focusNext(dialogContext),
                    validator: _validateOrder,
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: iconKey,
                    decoration: const InputDecoration(labelText: 'Icono'),
                    items: iconChoices.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Icon(entry.value, size: 18),
                                  const SizedBox(width: 8),
                                  Text(entry.key),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setInner(() => iconKey = value ?? 'folder'),
                  ),
                  SwitchListTile(value: root, onChanged: (v) => setInner(() => root = v), title: const Text('Puede ser raíz')),
                  SwitchListTile(value: acceptsDocs, onChanged: (v) => setInner(() => acceptsDocs = v), title: const Text('Acepta documentos')),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(onPressed: submit, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (data == null) return;
    if (existing == null) {
      await _mutate(() async {
        await widget.api.createNodeType(currentProjectId!, {
          'code': data['code'],
          'name': data['name'],
          'description': data['description'],
          'root': data['root'],
          'acceptsDocs': data['docs'],
          'iconKey': data['iconKey'],
          'order': data['order'],
        });
      }, selectProjectId: currentProjectId);
      return;
    }
    await _mutate(() {
      return widget.api.updateNodeType(currentProjectId!, existing.id, {
        'code': data['code'],
        'name': data['name'],
        'description': data['description'],
        'root': data['root'],
        'acceptsDocs': data['docs'],
        'iconKey': data['iconKey'],
        'order': data['order'],
      });
    }, selectProjectId: currentProjectId);
  }

  Future<void> addDocumentType([DocumentTypeItem? existing]) async {
    if (currentProject == null) return snack('Selecciona un proyecto.');
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, _) {
          void submit() {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.pop(dialogContext, {
              'name': name.text.trim(),
              'code': code.text.trim(),
              'description': description.text.trim(),
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'Nuevo tipo documental' : 'Editar tipo documental'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusNext(dialogContext),
                      validator: (value) => _validateRequired(value, 'nombre'),
                    ),
                    TextFormField(
                      controller: code,
                      decoration: const InputDecoration(labelText: 'Código'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusNext(dialogContext),
                      validator: (value) {
                        final base = _validateIdentifierCode(value);
                        if (base != null) {
                          return base;
                        }
                        final text = value!.trim();
                        if (projectDocumentTypes.any((type) => type.code == text && type.id != existing?.id)) {
                          return 'Ese código ya existe.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(onPressed: submit, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (data == null) return;
    if (existing == null) {
      await _mutate(() async {
        await widget.api.createDocumentType(currentProjectId!, data);
      }, selectProjectId: currentProjectId);
      return;
    }
    await _mutate(() async {
      await widget.api.updateDocumentType(currentProjectId!, existing.id, data);
    }, selectProjectId: currentProjectId);
  }

  Future<void> addRule() async {
    if (projectTypes.length < 2) return snack('Necesitas al menos dos tipos.');
    String parent = projectTypes.first.id;
    String child = projectTypes[1].id;
    final formKey = GlobalKey<FormState>();
    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setInner) {
          final childOptions = projectTypes.where((t) => t.id != parent).toList();
          if (childOptions.every((t) => t.id != child)) child = childOptions.first.id;
          void submit() {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.pop(dialogContext, {'parent': parent, 'child': child});
          }

          return AlertDialog(
            title: const Text('Nueva relación'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    initialValue: parent,
                    items: projectTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setInner(() => parent = v!),
                    validator: (_) => parent == child ? 'Padre e hijo deben ser distintos.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: child,
                    items: childOptions.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setInner(() => child = v!),
                    validator: (_) {
                      if (parent == child) {
                        return 'Padre e hijo deben ser distintos.';
                      }
                      if (projectRules.any((rule) => rule.parentTypeId == parent && rule.childTypeId == child)) {
                        return 'La relación ya existe.';
                      }
                      return null;
                    },
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(onPressed: submit, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (data == null) return;
    await _mutate(() {
      return widget.api.createRule(currentProjectId!, {
        'parentTypeId': data['parent'],
        'childTypeId': data['child'],
      });
    }, selectProjectId: currentProjectId);
  }

  Future<void> editAttributes(NodeTypeItem type) async {
    final attrs = List<AttributeItem>.from(type.attributes);
    Future<void> openAttributeForm([AttributeItem? existing]) async {
      final name = TextEditingController(text: existing?.name ?? '');
      final code = TextEditingController(text: existing?.code ?? '');
      final extension = TextEditingController(text: existing?.extension ?? '');
      final regex = TextEditingController(text: existing?.regex ?? '');
      final attributeFormKey = GlobalKey<FormState>();
      String dataType = existing?.dataType ?? 'string';
      final options = List<AttributeOptionItem>.from(existing?.options ?? const []);
      final data = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setInner) {
            Future<void> openOptionForm([AttributeOptionItem? existingOption]) async {
              final code = TextEditingController(text: existingOption?.code ?? '');
              final label = TextEditingController(text: existingOption?.label ?? '');
              final optionFormKey = GlobalKey<FormState>();
              final optionData = await showDialog<Map<String, String>>(
                context: context,
                builder: (optionContext) {
                  void submit() {
                    if (!(optionFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(optionContext, {
                      'label': label.text.trim(),
                      'code': code.text.trim(),
                    });
                  }

                  return AlertDialog(
                    title: Text(existingOption == null ? 'Nueva opción' : 'Editar opción'),
                    content: SizedBox(
                      width: 360,
                      child: Form(
                        key: optionFormKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: label,
                              decoration: const InputDecoration(labelText: 'Etiqueta visible'),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _focusNext(optionContext),
                              validator: (value) => _validateRequired(value, 'etiqueta'),
                            ),
                            TextFormField(
                              controller: code,
                              decoration: const InputDecoration(labelText: 'Código interno'),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => submit(),
                              validator: (value) {
                                final base = _validateIdentifierCode(value);
                                if (base != null) {
                                  return base;
                                }
                                final text = value!.trim();
                                if (options.any((item) => item.code == text && item.id != existingOption?.id)) {
                                  return 'Ese código ya existe.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(optionContext), child: const Text('Cancelar')),
                      FilledButton(onPressed: submit, child: const Text('Guardar')),
                    ],
                  );
                },
              );
              if (optionData == null) {
                return;
              }
              setInner(() {
                final option = AttributeOptionItem(
                  id: existingOption?.id ?? _id(),
                  code: optionData['code']!,
                  label: optionData['label']!,
                );
                if (existingOption == null) {
                  options.add(option);
                } else {
                  options[options.indexWhere((item) => item.id == existingOption.id)] = option;
                }
              });
            }

            return AlertDialog(
              title: Text(existing == null ? 'Nuevo atributo' : 'Editar atributo'),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: attributeFormKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _focusNext(context),
                          validator: (value) => _validateRequired(value, 'nombre'),
                        ),
                        TextFormField(
                          controller: code,
                          decoration: const InputDecoration(
                            labelText: 'Código',
                            helperText: 'Debe ser único dentro del proyecto.',
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _focusNext(context),
                          validator: (value) {
                            final base = _validateIdentifierCode(value);
                            if (base != null) {
                              return base;
                            }
                            final text = value!.trim();
                            final duplicatedInCurrentType = attrs.any((item) => item.code == text && item.id != existing?.id);
                            final duplicatedInOtherTypes = projectTypes
                                .where((item) => item.id != type.id)
                                .expand((item) => item.attributes)
                                .any((item) => item.code == text);
                            if (duplicatedInCurrentType || duplicatedInOtherTypes) {
                              return 'Ese código ya existe en el proyecto.';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: dataType,
                          decoration: const InputDecoration(labelText: 'Tipo de dato'),
                          items: attributeDataTypes
                              .map((item) => DropdownMenuItem(value: item, child: Text(attributeTypeLabel(item))))
                              .toList(),
                          onChanged: (value) => setInner(() => dataType = value ?? 'string'),
                        ),
                        if (dataType == 'string')
                          TextFormField(
                            controller: extension,
                            decoration: const InputDecoration(
                              labelText: 'Largo máximo',
                              helperText: 'Si queda vacío, la UI no valida longitud.',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return null;
                              }
                              final parsed = int.tryParse(text);
                              if (parsed == null || parsed <= 0) {
                                return 'Debe ser un entero positivo.';
                              }
                              return null;
                            },
                          ),
                        if (dataType != 'list')
                          TextFormField(
                            controller: regex,
                            decoration: const InputDecoration(
                              labelText: 'Validación regex',
                              helperText: 'Se usa al cargar valores en la UI.',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return null;
                              }
                              return _isValidRegex(text) ? null : 'La expresión regular no es válida.';
                            },
                          ),
                        if (dataType == 'list') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Text('Opciones del combo')),
                              FilledButton.tonalIcon(
                                onPressed: () => openOptionForm(),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (options.isEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Este combo todavía no tiene opciones.'),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final option = options[index];
                                  return ListTile(
                                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    title: Text(option.label),
                                    subtitle: Text(option.code),
                                    trailing: Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          onPressed: () => openOptionForm(option),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          onPressed: () => setInner(() => options.removeAt(index)),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (!(attributeFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    if (dataType == 'list' && options.isEmpty) {
                      snack('El atributo lista necesita al menos una opción.');
                      return;
                    }
                    Navigator.pop(context, {
                      'name': name.text.trim(),
                      'code': code.text.trim(),
                      'dataType': dataType,
                      'extension': dataType == 'string' ? extension.text.trim() : '',
                      'regex': dataType == 'list' ? '' : regex.text.trim(),
                      'options': List<AttributeOptionItem>.from(options),
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        ),
      );
      if (data == null) {
        return;
      }
      final attribute = AttributeItem(
        id: existing?.id ?? _id(),
        name: data['name'],
        code: data['code'],
        dataType: data['dataType'],
        extension: data['extension'],
        regex: data['regex'],
        options: List<AttributeOptionItem>.from(data['options'] as List<AttributeOptionItem>),
      );
      if (existing == null) {
        attrs.add(attribute);
      } else {
        attrs[attrs.indexWhere((item) => item.id == existing.id)] = attribute;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) => AlertDialog(
          title: Text('Atributos de ${type.name}'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await openAttributeForm();
                      setInner(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo atributo'),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: attrs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final attr = attrs[i];
                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        title: Text(attr.name),
                        subtitle: Text('${attr.code} • ${attributeSummary(attr)}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(onPressed: () async { await openAttributeForm(attr); setInner(() {}); }, icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () => setInner(() => attrs.removeAt(i)), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.api.syncNodeTypeAttributes(
                    type.projectId,
                    type.id,
                    attrs.map((item) => item.toJson()).toList(),
                  );
                  await _reloadCurrentProject(showLoader: false);
                } catch (error) {
                  if (mounted) {
                    snack(_errorText(error));
                  }
                  return;
                }
                if (!mounted || !context.mounted) {
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> editDocumentAttributes(DocumentTypeItem type) async {
    final attrs = List<AttributeItem>.from(type.attributes);

    Future<void> openAttributeForm([AttributeItem? existing]) async {
      final name = TextEditingController(text: existing?.name ?? '');
      final code = TextEditingController(text: existing?.code ?? '');
      final extension = TextEditingController(text: existing?.extension ?? '');
      final regex = TextEditingController(text: existing?.regex ?? '');
      final attributeFormKey = GlobalKey<FormState>();
      String dataType = existing?.dataType ?? 'string';
      final options = List<AttributeOptionItem>.from(existing?.options ?? const []);
      final data = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setInner) {
            Future<void> openOptionForm([AttributeOptionItem? existingOption]) async {
              final code = TextEditingController(text: existingOption?.code ?? '');
              final label = TextEditingController(text: existingOption?.label ?? '');
              final optionFormKey = GlobalKey<FormState>();
              final optionData = await showDialog<Map<String, String>>(
                context: context,
                builder: (optionContext) {
                  void submit() {
                    if (!(optionFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(optionContext, {
                      'label': label.text.trim(),
                      'code': code.text.trim(),
                    });
                  }

                  return AlertDialog(
                    title: Text(existingOption == null ? 'Nueva opción' : 'Editar opción'),
                    content: SizedBox(
                      width: 360,
                      child: Form(
                        key: optionFormKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: label,
                              decoration: const InputDecoration(labelText: 'Etiqueta visible'),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _focusNext(optionContext),
                              validator: (value) => _validateRequired(value, 'etiqueta'),
                            ),
                            TextFormField(
                              controller: code,
                              decoration: const InputDecoration(labelText: 'Código interno'),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => submit(),
                              validator: (value) {
                                final base = _validateIdentifierCode(value);
                                if (base != null) {
                                  return base;
                                }
                                final text = value!.trim();
                                if (options.any((item) => item.code == text && item.id != existingOption?.id)) {
                                  return 'Ese código ya existe.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(optionContext), child: const Text('Cancelar')),
                      FilledButton(onPressed: submit, child: const Text('Guardar')),
                    ],
                  );
                },
              );
              if (optionData == null) {
                return;
              }
              setInner(() {
                final option = AttributeOptionItem(
                  id: existingOption?.id ?? _id(),
                  code: optionData['code']!,
                  label: optionData['label']!,
                );
                if (existingOption == null) {
                  options.add(option);
                } else {
                  options[options.indexWhere((item) => item.id == existingOption.id)] = option;
                }
              });
            }

            return AlertDialog(
              title: Text(existing == null ? 'Nuevo atributo documental' : 'Editar atributo documental'),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: attributeFormKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _focusNext(context),
                          validator: (value) => _validateRequired(value, 'nombre'),
                        ),
                        TextFormField(
                          controller: code,
                          decoration: const InputDecoration(
                            labelText: 'Código',
                            helperText: 'Debe ser único dentro del proyecto para atributos documentales.',
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _focusNext(context),
                          validator: (value) {
                            final base = _validateIdentifierCode(value);
                            if (base != null) {
                              return base;
                            }
                            final text = value!.trim();
                            final duplicatedInCurrentType = attrs.any((item) => item.code == text && item.id != existing?.id);
                            final duplicatedInOtherTypes = projectDocumentTypes
                                .where((item) => item.id != type.id)
                                .expand((item) => item.attributes)
                                .any((item) => item.code == text);
                            if (duplicatedInCurrentType || duplicatedInOtherTypes) {
                              return 'Ese código ya existe en el proyecto.';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: dataType,
                          decoration: const InputDecoration(labelText: 'Tipo de dato'),
                          items: attributeDataTypes
                              .map((item) => DropdownMenuItem(value: item, child: Text(attributeTypeLabel(item))))
                              .toList(),
                          onChanged: (value) => setInner(() => dataType = value ?? 'string'),
                        ),
                        if (dataType == 'string')
                          TextFormField(
                            controller: extension,
                            decoration: const InputDecoration(
                              labelText: 'Largo máximo',
                              helperText: 'Si queda vacío, la UI no valida longitud.',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return null;
                              }
                              final parsed = int.tryParse(text);
                              if (parsed == null || parsed <= 0) {
                                return 'Debe ser un entero positivo.';
                              }
                              return null;
                            },
                          ),
                        if (dataType != 'list')
                          TextFormField(
                            controller: regex,
                            decoration: const InputDecoration(
                              labelText: 'Validación regex',
                              helperText: 'Se usa al cargar valores documentales en la UI.',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return null;
                              }
                              return _isValidRegex(text) ? null : 'La expresión regular no es válida.';
                            },
                          ),
                        if (dataType == 'list') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Text('Opciones del combo')),
                              FilledButton.tonalIcon(
                                onPressed: () => openOptionForm(),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (options.isEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Este combo todavía no tiene opciones.'),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final option = options[index];
                                  return ListTile(
                                    tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    title: Text(option.label),
                                    subtitle: Text(option.code),
                                    trailing: Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          onPressed: () => openOptionForm(option),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          onPressed: () => setInner(() => options.removeAt(index)),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (!(attributeFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    if (dataType == 'list' && options.isEmpty) {
                      snack('El atributo lista necesita al menos una opción.');
                      return;
                    }
                    Navigator.pop(context, {
                      'name': name.text.trim(),
                      'code': code.text.trim(),
                      'dataType': dataType,
                      'extension': dataType == 'string' ? extension.text.trim() : '',
                      'regex': dataType == 'list' ? '' : regex.text.trim(),
                      'options': List<AttributeOptionItem>.from(options),
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        ),
      );
      if (data == null) {
        return;
      }
      final attribute = AttributeItem(
        id: existing?.id ?? _id(),
        name: data['name'],
        code: data['code'],
        dataType: data['dataType'],
        extension: data['extension'],
        regex: data['regex'],
        options: List<AttributeOptionItem>.from(data['options'] as List<AttributeOptionItem>),
      );
      if (existing == null) {
        attrs.add(attribute);
      } else {
        attrs[attrs.indexWhere((item) => item.id == existing.id)] = attribute;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) => AlertDialog(
          title: Text('Atributos documentales de ${type.name}'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await openAttributeForm();
                      setInner(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo atributo'),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: attrs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final attr = attrs[i];
                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        title: Text(attr.name),
                        subtitle: Text('${attr.code} • ${attributeSummary(attr)}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(onPressed: () async { await openAttributeForm(attr); setInner(() {}); }, icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () => setInner(() => attrs.removeAt(i)), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.api.syncDocumentTypeAttributes(
                    type.projectId,
                    type.id,
                    attrs.map((item) => item.toJson()).toList(),
                  );
                  await _reloadCurrentProject(showLoader: false);
                } catch (error) {
                  if (mounted) {
                    snack(_errorText(error));
                  }
                  return;
                }
                if (!mounted || !context.mounted) {
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addNode([NodeItem? parent, NodeItem? existing]) async {
    if (currentProject == null) return snack('Selecciona un proyecto.');
    final available = parent == null ? projectTypes.where((t) => t.root).toList() : childTypesOf(parent.typeId);
    if (available.isEmpty) return snack(parent == null ? 'No hay tipos raíz.' : 'No hay hijos permitidos.');
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final order = TextEditingController(text: '${existing?.order ?? 10}');
    final formKey = GlobalKey<FormState>();
    String typeId = existing?.typeId ?? available.first.id;
    final controllers = <String, TextEditingController>{};
    final selectedListValues = <String, String>{};
    for (final type in available) {
      for (final attr in type.attributes) {
        final initialValue = existing?.values[attr.id] ?? '';
        if (attr.dataType == 'list') {
          selectedListValues[attr.id] = initialValue;
        } else {
          controllers[attr.id] = TextEditingController(text: initialValue);
        }
      }
    }
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setInner) {
          void submit() {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            final selectedType = available.firstWhere((t) => t.id == typeId);
            final values = <String, String>{};
            for (final attr in selectedType.attributes) {
              final value = attr.dataType == 'list'
                  ? (selectedListValues[attr.id] ?? '').trim()
                  : controllers[attr.id]!.text.trim();
              if (value.isNotEmpty) {
                values[attr.id] = value;
              }
            }
            Navigator.pop(dialogContext, {
              'typeId': typeId,
              'name': name.text.trim(),
              'code': code.text.trim(),
              'description': description.text.trim(),
              'values': values,
              'order': int.parse(order.text.trim()),
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'Nuevo nodo' : 'Editar nodo'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<String>(
                      initialValue: typeId,
                      items: available.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                      onChanged: (v) => setInner(() => typeId = v!),
                    ),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusNext(dialogContext),
                      validator: (value) {
                        final base = _validateRequired(value, 'nombre');
                        if (base != null) {
                          return base;
                        }
                        final text = value!.trim();
                        if (projectNodes.any((node) => node.parentId == (existing?.parentId ?? parent?.id) && node.name == text && node.id != existing?.id)) {
                          return 'Ya existe un nodo hermano con ese nombre.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: code,
                      decoration: const InputDecoration(labelText: 'Código'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusNext(dialogContext),
                    ),
                    TextFormField(
                      controller: order,
                      decoration: const InputDecoration(labelText: 'Orden'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusNext(dialogContext),
                      validator: _validateOrder,
                    ),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ...available.firstWhere((t) => t.id == typeId).attributes.map((attr) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: attr.dataType == 'list'
                              ? DropdownButtonFormField<String>(
                                  initialValue: attr.options.any((option) => option.code == selectedListValues[attr.id]) ? selectedListValues[attr.id] : null,
                                  decoration: InputDecoration(
                                    labelText: '${attr.name} (${attributeTypeLabel(attr.dataType)})',
                                    helperText: attr.options.isEmpty ? 'Primero define opciones en el tipo.' : null,
                                  ),
                                  items: attr.options
                                      .map((option) => DropdownMenuItem(value: option.code, child: Text('${option.label} (${option.code})')))
                                      .toList(),
                                  onChanged: attr.options.isEmpty ? null : (value) => setInner(() => selectedListValues[attr.id] = value ?? ''),
                                  validator: (_) {
                                    final value = (selectedListValues[attr.id] ?? '').trim();
                                    if (value.isNotEmpty && !attr.options.any((option) => option.code == value)) {
                                      return 'Selecciona una opción válida.';
                                    }
                                    return null;
                                  },
                                )
                              : TextFormField(
                                  controller: controllers[attr.id],
                                  keyboardType: keyboardTypeForAttribute(attr.dataType),
                                  decoration: InputDecoration(
                                    labelText: '${attr.name} (${attributeTypeLabel(attr.dataType)})',
                                    helperText: [
                                      if (attr.extension.isNotEmpty) 'ext ${attr.extension}',
                                      if (attr.regex.isNotEmpty) 'regex ${attr.regex}',
                                    ].join(' • '),
                                  ),
                                  validator: (value) => _validateAttributeRawValue(attr, value?.trim() ?? ''),
                                ),
                        )),
                  ]),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(onPressed: submit, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (data == null) return;
    final payload = {
      'typeId': data['typeId'],
      'parentId': existing?.parentId ?? parent?.id,
      'code': data['code'],
      'name': data['name'],
      'description': data['description'],
      'values': Map<String, String>.from(data['values']),
      'order': data['order'],
    };
    if (existing == null) {
      await _mutate(() async {
        await widget.api.createNode(currentProjectId!, payload);
      }, selectProjectId: currentProjectId);
      return;
    }
    await _mutate(() => widget.api.updateNode(currentProjectId!, existing.id, payload), selectProjectId: currentProjectId);
  }

  @override
  Widget build(BuildContext context) {
    final project = currentProject;
    final destinations = availableSections;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ui-sgd'),
        actions: [
          if (saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          if (project != null) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text(project.name))),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  onPressed: () => widget.onLogoutRequested(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
              builder: (context, controller, _) => TextButton.icon(
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(widget.session.user.displayName),
              ),
            ),
          ),
        ],
      ),
      body: Row(children: [
        NavigationRail(
          selectedIndex: destinations.indexOf(section),
          onDestinationSelected: (i) async {
            final next = destinations[i];
            setState(() => section = next);
            if (next == Section.seguridad) {
              await _reloadSecurity();
            }
          },
          labelType: NavigationRailLabelType.all,
          destinations: destinations
              .map((item) => switch (item) {
                    Section.proyectos => const NavigationRailDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: Text('Proyectos')),
                    Section.tipos => const NavigationRailDestination(icon: Icon(Icons.account_tree_outlined), selectedIcon: Icon(Icons.account_tree), label: Text('Tipos')),
                    Section.arbol => const NavigationRailDestination(icon: Icon(Icons.schema_outlined), selectedIcon: Icon(Icons.schema), label: Text('Jerarquía')),
                    Section.seguridad => const NavigationRailDestination(icon: Icon(Icons.lock_outline), selectedIcon: Icon(Icons.lock), label: Text('Accesos')),
                  })
              .toList(),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: Padding(padding: const EdgeInsets.all(24), child: _view())),
      ]),
    );
  }

  Widget _header(String title, String subtitle, String button, VoidCallback? onPressed) => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), Text(subtitle)])),
        if (onPressed != null) ...[
          const SizedBox(width: 20),
          FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.add), label: Text(button)),
        ],
      ]);

  Widget _empty(String title, String text, String button, VoidCallback? onPressed) => Card(child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.layers_clear_outlined, size: 48), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center), if (onPressed != null) ...[const SizedBox(height: 20), FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.add), label: Text(button))]]))));

  Widget _view() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null && projects.isEmpty) {
      return _empty('No se pudo cargar', loadError!, 'Reintentar', () => _bootstrap());
    }

    if (section == Section.proyectos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            'Proyectos',
            'Cada proyecto queda aislado y tiene su propia jerarquía.',
            'Nuevo proyecto',
            currentUser.isPlatformAdmin ? () => addProject() : null,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: projects.isEmpty
                ? _empty(
                    'No hay proyectos',
                    currentUser.isPlatformAdmin ? 'Crea uno para empezar.' : 'Todavía no tienes proyectos asignados.',
                    'Crear proyecto',
                    currentUser.isPlatformAdmin ? () => addProject() : null,
                  )
                : ListView.separated(
                    itemCount: projects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final p = projects[i];
                      final active = p.id == currentProjectId;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          onTap: () => _selectProject(p.id, nextSection: preferredSectionForProject(p.id)),
                          title: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              if (active) const Chip(label: Text('Activo')),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('slug: ${p.slug}'),
                              if (p.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(p.description),
                              ],
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              if (can('project.write', p.id))
                                IconButton(
                                  onPressed: () => addProject(p),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              if (can('project.write', p.id))
                                IconButton(
                                  onPressed: () => _removeProject(p),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    if (currentProject == null) return _empty('Selecciona un proyecto', 'Todo el ABM depende del proyecto actual.', 'Ir a proyectos', () => setState(() => section = Section.proyectos));

    if (section == Section.tipos) {
      if (!can('types.read')) {
        return _empty('Sin acceso', 'Tu perfil no puede ver los tipos de este proyecto.', 'Volver', () => setState(() => section = Section.proyectos));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            'Contenedores del proyecto',
            'Define tipos de contenedor, tipos documentales, atributos y relaciones para ${currentProject?.name}.',
            'Nuevo contenedor',
            can('types.write') ? () => addType() : null,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tipos de contenedor',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: can('types.write') ? () => addType() : null,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Agregar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (projectTypes.isEmpty)
                                _empty(
                                  'No hay contenedores',
                                  'Crea tipos como caja, carpeta o expediente.',
                                  'Crear contenedor',
                                  can('types.write') ? () => addType() : null,
                                )
                              else
                                ...projectTypes.map((t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(18),
                                          title: Row(
                                            children: [
                                              Icon(iconFor(t.iconKey), size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(t.name)),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(t.code),
                                              if (t.description.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(t.description),
                                              ],
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Chip(label: Text(t.root ? 'Raíz' : 'No raíz')),
                                                  Chip(label: Text(t.acceptsDocs ? 'Acepta docs' : 'Solo estructura')),
                                                  Chip(label: Text('Atributos: ${t.attributes.length}')),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Wrap(
                                            spacing: 6,
                                            children: [
                                              if (can('types.write'))
                                                IconButton(
                                                  onPressed: () => editAttributes(t),
                                                  icon: const Icon(Icons.tune_outlined),
                                                ),
                                              if (can('types.write'))
                                                IconButton(
                                                  onPressed: () => addType(t),
                                                  icon: const Icon(Icons.edit_outlined),
                                                ),
                                              if (can('types.write'))
                                                IconButton(
                                                  onPressed: () => _removeType(t),
                                                  icon: const Icon(Icons.delete_outline),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tipos documentales',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: can('types.write') ? () => addDocumentType() : null,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Agregar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Definen los atributos propios del documento que se carga o escanea.'),
                              const SizedBox(height: 16),
                              if (projectDocumentTypes.isEmpty)
                                _empty(
                                  'No hay tipos documentales',
                                  'Define al menos uno para capturar atributos documentales propios.',
                                  'Crear tipo documental',
                                  can('types.write') ? () => addDocumentType() : null,
                                )
                              else
                                ...projectDocumentTypes.map((t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(18),
                                          title: Text(t.name),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(t.code),
                                              if (t.description.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(t.description),
                                              ],
                                              const SizedBox(height: 8),
                                              Chip(label: Text('Atributos: ${t.attributes.length}')),
                                            ],
                                          ),
                                          trailing: Wrap(
                                            spacing: 6,
                                            children: [
                                              if (can('types.write'))
                                                IconButton(
                                                  onPressed: () => editDocumentAttributes(t),
                                                  icon: const Icon(Icons.fact_check_outlined),
                                                ),
                                              if (can('types.write'))
                                                IconButton(
                                                  onPressed: () => addDocumentType(t),
                                                  icon: const Icon(Icons.edit_outlined),
                                                ),
                                              if (can('types.write'))
                                                IconButton(
                                                  onPressed: () => _removeDocumentType(t),
                                                  icon: const Icon(Icons.delete_outline),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Relaciones padre-hijo')),
                              FilledButton.tonalIcon(
                                onPressed: can('types.write') ? addRule : null,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: projectRules.isEmpty
                                ? const Center(child: Text('Sin reglas todavía.'))
                                : ListView.separated(
                                    itemCount: projectRules.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, i) {
                                      final r = projectRules[i];
                                      return ListTile(
                                        tileColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        title: Text(
                                          '${typeById(r.parentTypeId)?.name ?? 'Tipo'} -> ${typeById(r.childTypeId)?.name ?? 'Tipo'}',
                                        ),
                                        trailing: can('types.write')
                                            ? IconButton(
                                                onPressed: () => _removeRule(r),
                                                icon: const Icon(Icons.delete_outline),
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (section == Section.seguridad) {
      if (!can('security.read')) {
        return _empty('Sin acceso', 'Tu perfil no puede administrar accesos en este proyecto.', 'Volver', () => setState(() => section = Section.proyectos));
      }
      if (securityLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (securityError != null) {
        return _empty('No se pudo cargar seguridad', securityError!, 'Reintentar', () => _reloadSecurity());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            'Accesos del proyecto',
            'Configura perfiles, permisos y usuarios para ${currentProject?.name}.',
            'Nuevo acceso',
            can('security.write') ? () => addOrEditMembership() : null,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Perfiles del proyecto')),
                              FilledButton.tonalIcon(
                                onPressed: can('security.write') ? () => addOrEditProfile() : null,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: projectProfiles.isEmpty
                                ? const Center(child: Text('Sin perfiles.'))
                                : ListView.separated(
                                    itemCount: projectProfiles.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) {
                                      final profile = projectProfiles[i];
                                      return ListTile(
                                        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        title: Text(profile.name),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 6),
                                            Text('${profile.code} • ${profile.permissionCodes.length} permisos'),
                                            if (profile.description.isNotEmpty) Text(profile.description),
                                          ],
                                        ),
                                        trailing: Wrap(
                                          spacing: 4,
                                          children: [
                                            if (can('security.write'))
                                              IconButton(
                                                onPressed: () => addOrEditProfile(profile),
                                                icon: const Icon(Icons.edit_outlined),
                                              ),
                                            if (can('security.write') && !profile.isSystem)
                                              IconButton(
                                                onPressed: () => _removeProfile(profile),
                                                icon: const Icon(Icons.delete_outline),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Usuarios del proyecto'),
                          const SizedBox(height: 16),
                          Expanded(
                            child: projectMemberships.isEmpty
                                ? const Center(child: Text('Sin usuarios asignados.'))
                                : ListView.separated(
                                    itemCount: projectMemberships.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) {
                                      final membership = projectMemberships[i];
                                      return ListTile(
                                        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        title: Text(membership.displayName),
                                        subtitle: Text('${membership.loginName} • ${membership.profileName}${membership.isActive ? '' : ' • acceso inactivo'}'),
                                        trailing: can('security.write')
                                            ? IconButton(
                                                onPressed: () => addOrEditMembership(membership),
                                                icon: const Icon(Icons.edit_outlined),
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!can('hierarchy.read')) {
      return _empty('Sin acceso', 'Tu perfil no puede ver la jerarquía de este proyecto.', 'Volver', () => setState(() => section = Section.proyectos));
    }
    final roots = childrenOf(null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('Jerarquía documental', 'Carga la estructura real de ${currentProject?.name}.', 'Agregar raíz', can('hierarchy.write') ? () => addNode() : null),
      const SizedBox(height: 20),
      Expanded(child: roots.isEmpty ? _empty('No hay nodos raíz', 'Necesitas al menos un tipo marcado como raíz.', 'Agregar raíz', can('hierarchy.write') ? () => addNode() : null) : Card(child: Padding(padding: const EdgeInsets.all(16), child: ListView(children: roots.map((n) => _nodeCard(n, true)).toList())))),
    ]);
  }

  Widget _nodeCard(NodeItem node, bool rootCard) {
    final kids = childrenOf(node.id);
    final type = typeById(node.typeId);
    final missingAttributes = type == null
        ? 0
        : type.attributes.where((attr) => !_hasAttributeValue(node.values[attr.id])).length;
    return Card(
      margin: EdgeInsets.only(left: rootCard ? 0 : 20, bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: rootCard,
        title: Row(
          children: [
            Icon(iconFor(type?.iconKey ?? 'folder'), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(node.name)),
          ],
        ),
        subtitle: Text([
          node.code.isEmpty ? '(sin código)' : node.code,
          type?.name ?? 'Tipo',
          'nivel ${node.depth}',
          if (type != null && type.attributes.isNotEmpty)
            missingAttributes == 0 ? 'atributos completos' : '$missingAttributes sin valor',
        ].join(' • ')),
        trailing: SizedBox(
          child: Wrap(
            spacing: 0,
            children: [
              if ((type?.acceptsDocs ?? false) && (can('documents.read') || can('documents.write')))
                IconButton(
                  onPressed: () => _openAcquisition(node),
                  icon: const Icon(Icons.document_scanner_outlined),
                ),
              if (can('hierarchy.write'))
                IconButton(
                  onPressed: () => addNode(node, null),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              if (can('hierarchy.write'))
                IconButton(
                  onPressed: () => addNode(nodeById(node.parentId ?? ''), node),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (can('hierarchy.write'))
                IconButton(
                  onPressed: () => _removeNode(node),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
        children: [
          if (node.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(alignment: Alignment.centerLeft, child: Text(node.description)),
            ),
          if (type != null && type.attributes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missingAttributes == 0
                        ? 'Atributos del tipo'
                        : 'Atributos del tipo • $missingAttributes sin cargar',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: type.attributes.map((attr) {
                      final rawValue = node.values[attr.id];
                      final hasValue = _hasAttributeValue(rawValue);
                      return Chip(
                        avatar: Icon(
                          hasValue ? Icons.check_circle_outline : Icons.error_outline,
                          size: 18,
                          color: hasValue ? Colors.green.shade700 : Colors.orange.shade800,
                        ),
                        backgroundColor: hasValue
                            ? Colors.green.withValues(alpha: 0.10)
                            : Colors.orange.withValues(alpha: 0.14),
                        side: BorderSide(
                          color: hasValue
                              ? Colors.green.withValues(alpha: 0.28)
                              : Colors.orange.withValues(alpha: 0.32),
                        ),
                        label: Text(
                          hasValue
                              ? '${attr.name}: ${attributeValueLabel(attr, rawValue)}'
                              : '${attr.name}: Sin valor',
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          if (kids.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Sin hijos cargados todavía.')),
            )
          else
            ...kids.map((k) => _nodeCard(k, false)),
        ],
      ),
    );
  }

  Future<void> _openAcquisition(NodeItem node) async {
    final currentProject = this.currentProject;
    final type = typeById(node.typeId);
    if (currentProject == null || type == null) {
      snack('Falta contexto para abrir el centro de escaneo.');
      return;
    }
    if (!can('documents.read') && !can('documents.write')) {
      snack('Tu perfil no tiene acceso documental en este proyecto.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanCenterPage(
          api: widget.api,
          projectId: currentProject.id,
          projectName: currentProject.name,
          nodeId: node.id,
          nodeName: node.name,
          nodeCode: node.code,
          nodeTypeName: type.name,
          canReadDocuments: can('documents.read'),
          canWriteDocuments: can('documents.write'),
          fallbackAttributes: type.attributes
              .map(
                (attr) => ScanAttributeDefinition(
                  id: attr.id,
                  name: attr.name,
                  code: attr.code,
                  dataType: attr.dataType,
                  extension: attr.extension,
                  regex: attr.regex,
                  options: attr.options
                      .map((option) => ScanAttributeOption(code: option.code, label: option.label))
                      .toList(),
                ),
              )
              .toList(),
          documentTypes: projectDocumentTypes
              .map(
                (documentType) => ScanDocumentTypeDefinition(
                  id: documentType.id,
                  name: documentType.name,
                  code: documentType.code,
                  description: documentType.description,
                  attributes: documentType.attributes
                      .map(
                        (attr) => ScanAttributeDefinition(
                          id: attr.id,
                          name: attr.name,
                          code: attr.code,
                          dataType: attr.dataType,
                          extension: attr.extension,
                          regex: attr.regex,
                          options: attr.options
                              .map((option) => ScanAttributeOption(code: option.code, label: option.label))
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _removeProject(Project p) async {
    await _mutate(() => widget.api.deleteProject(p.id));
  }

  Future<void> _removeType(NodeTypeItem t) async {
    if (projectNodes.any((n) => n.typeId == t.id)) return snack('Ese tipo ya tiene nodos.');
    await _mutate(() => widget.api.deleteNodeType(t.projectId, t.id), selectProjectId: currentProjectId);
  }

  Future<void> _removeDocumentType(DocumentTypeItem t) async {
    await _mutate(() => widget.api.deleteDocumentType(t.projectId, t.id), selectProjectId: currentProjectId);
  }

  Future<void> _removeProfile(ProjectProfileItem profile) async {
    await _mutate(() async {
      await widget.api.deleteProjectProfile(currentProjectId!, profile.id);
      await _reloadSecurity(showLoader: false);
    }, selectProjectId: currentProjectId, refreshSession: true, nextSection: Section.seguridad);
  }

  Future<void> _removeRule(RuleItem r) async {
    if (projectNodes.any((n) {
      final parent = n.parentId == null ? null : nodeById(n.parentId!);
      return parent != null && parent.typeId == r.parentTypeId && n.typeId == r.childTypeId;
    })) {
      return snack('La regla ya se usa en el árbol.');
    }
    await _mutate(() => widget.api.deleteRule(r.projectId, r.parentTypeId, r.childTypeId), selectProjectId: currentProjectId);
  }

  Future<void> _removeNode(NodeItem n) async {
    if (projectNodes.any((x) => x.parentId == n.id)) return snack('El nodo tiene hijos.');
    await _mutate(() => widget.api.deleteNode(n.projectId, n.id), selectProjectId: currentProjectId);
  }
}

class Project {
  Project({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'].toString(),
        name: json['name'].toString(),
        slug: json['slug'].toString(),
        description: (json['description'] ?? '').toString(),
      );

  final String id;
  final String name;
  final String slug;
  final String description;
}

class NodeTypeItem {
  NodeTypeItem({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    required this.root,
    required this.acceptsDocs,
    required this.iconKey,
    required this.attributes,
    required this.order,
  });

  factory NodeTypeItem.fromJson(Map<String, dynamic> json) => NodeTypeItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        root: json['root'] == true,
        acceptsDocs: (json['acceptsDocs'] ?? json['acceptsdocs']) == true,
        iconKey: (json['iconKey'] ?? json['iconkey'] ?? 'folder').toString(),
        attributes: ((json['attributes'] as List?) ?? const [])
            .map((item) => AttributeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final bool root;
  final bool acceptsDocs;
  final String iconKey;
  final List<AttributeItem> attributes;
  final int order;
}

class DocumentTypeItem {
  DocumentTypeItem({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    required this.attributes,
  });

  factory DocumentTypeItem.fromJson(Map<String, dynamic> json) => DocumentTypeItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        attributes: ((json['attributes'] as List?) ?? const [])
            .map((item) => AttributeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
      );

  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final List<AttributeItem> attributes;
}

class RuleItem {
  RuleItem({
    required this.id,
    required this.projectId,
    required this.parentTypeId,
    required this.childTypeId,
  });

  factory RuleItem.fromJson(Map<String, dynamic> json) => RuleItem(
        id: (json['id'] ?? '${json['parentTypeId'] ?? json['parenttypeid']}|${json['childTypeId'] ?? json['childtypeid']}').toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        parentTypeId: (json['parentTypeId'] ?? json['parenttypeid']).toString(),
        childTypeId: (json['childTypeId'] ?? json['childtypeid']).toString(),
      );

  final String id;
  final String projectId;
  final String parentTypeId;
  final String childTypeId;
}

class NodeItem {
  NodeItem({
    required this.id,
    required this.projectId,
    required this.typeId,
    required this.parentId,
    required this.code,
    required this.name,
    required this.description,
    required this.values,
    required this.depth,
    required this.order,
  });

  factory NodeItem.fromJson(Map<String, dynamic> json) => NodeItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        typeId: (json['typeId'] ?? json['typeid']).toString(),
        parentId: ((json['parentId'] ?? json['parentid']) as String?)?.isEmpty == true ? null : (json['parentId'] ?? json['parentid'])?.toString(),
        code: (json['code'] ?? '').toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        values: ((json['values'] as Map?) ?? const {})
            .map((key, value) => MapEntry(key.toString(), value.toString())),
        depth: (json['depth'] as num?)?.toInt() ?? 0,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String projectId;
  final String typeId;
  final String? parentId;
  final String code;
  final String name;
  final String description;
  final Map<String, String> values;
  final int depth;
  final int order;
}

class AttributeItem {
  AttributeItem({
    required this.id,
    required this.name,
    required this.code,
    required this.dataType,
    required this.extension,
    required this.regex,
    required this.options,
  });

  factory AttributeItem.fromJson(Map<String, dynamic> json) => AttributeItem(
        id: json['id'].toString(),
        name: json['name'].toString(),
        code: json['code'].toString(),
        dataType: (json['dataType'] ?? json['datatype']).toString(),
        extension: (json['extension'] ?? '').toString(),
        regex: (json['regex'] ?? '').toString(),
        options: ((json['options'] as List?) ?? const [])
            .map((item) => AttributeOptionItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
      );

  final String id;
  final String name;
  final String code;
  final String dataType;
  final String extension;
  final String regex;
  final List<AttributeOptionItem> options;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'dataType': dataType,
        'extension': extension,
        'regex': regex,
        'options': options.map((item) => item.toJson()).toList(),
      };
}

class AttributeOptionItem {
  const AttributeOptionItem({
    required this.id,
    required this.code,
    required this.label,
  });

  factory AttributeOptionItem.fromJson(Map<String, dynamic> json) => AttributeOptionItem(
        id: json['id'].toString(),
        code: json['code'].toString(),
        label: json['label'].toString(),
      );

  final String id;
  final String code;
  final String label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'label': label,
      };
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.loginName,
    required this.isPlatformAdmin,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        id: json['id'].toString(),
        displayName: (json['displayName'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        loginName: (json['loginName'] ?? '').toString(),
        isPlatformAdmin: json['isPlatformAdmin'] == true,
      );

  final String id;
  final String displayName;
  final String email;
  final String loginName;
  final bool isPlatformAdmin;
}

class ProjectMembershipAccess {
  const ProjectMembershipAccess({
    required this.projectId,
    required this.profileId,
    required this.profileCode,
    required this.profileName,
    required this.permissionCodes,
  });

  factory ProjectMembershipAccess.fromJson(Map<String, dynamic> json) => ProjectMembershipAccess(
        projectId: json['projectId'].toString(),
        profileId: json['profileId'].toString(),
        profileCode: json['profileCode'].toString(),
        profileName: json['profileName'].toString(),
        permissionCodes: ((json['permissionCodes'] as List?) ?? const []).map((item) => item.toString()).toList(),
      );

  final String projectId;
  final String profileId;
  final String profileCode;
  final String profileName;
  final List<String> permissionCodes;
}

class AuthSessionState {
  const AuthSessionState({
    required this.token,
    required this.user,
    required this.memberships,
    required this.allPermissionCodes,
  });

  factory AuthSessionState.fromJson(Map<String, dynamic> json, {required String token}) => AuthSessionState(
        token: token,
        user: CurrentUser.fromJson(Map<String, dynamic>.from((json['user'] as Map).cast<String, dynamic>())),
        memberships: ((json['memberships'] as List?) ?? const [])
            .map((item) => ProjectMembershipAccess.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
        allPermissionCodes: ((json['allPermissions'] as List?) ?? const []).map((item) => item.toString()).toList(),
      );

  final String token;
  final CurrentUser user;
  final List<ProjectMembershipAccess> memberships;
  final List<String> allPermissionCodes;
}

class PermissionDefinition {
  const PermissionDefinition({
    required this.code,
    required this.name,
    required this.description,
    required this.accessKind,
  });

  factory PermissionDefinition.fromJson(Map<String, dynamic> json) => PermissionDefinition(
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        accessKind: (json['accessKind'] ?? json['accesskind'] ?? '').toString(),
      );

  final String code;
  final String name;
  final String description;
  final String accessKind;
}

class ProjectProfileItem {
  const ProjectProfileItem({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
    required this.permissionCodes,
  });

  factory ProjectProfileItem.fromJson(Map<String, dynamic> json) => ProjectProfileItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        isSystem: (json['isSystem'] ?? json['issystem']) == true,
        isActive: (json['isActive'] ?? json['isactive']) != false,
        permissionCodes: ((json['permissionCodes'] as List?) ?? const []).map((item) => item.toString()).toList(),
      );

  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final bool isSystem;
  final bool isActive;
  final List<String> permissionCodes;
}

class ProjectUserMembershipItem {
  const ProjectUserMembershipItem({
    required this.userId,
    required this.profileId,
    required this.profileCode,
    required this.profileName,
    required this.displayName,
    required this.loginName,
    required this.email,
    required this.isActive,
    this.userActive = true,
  });

  factory ProjectUserMembershipItem.fromJson(Map<String, dynamic> json) => ProjectUserMembershipItem(
        userId: (json['userId'] ?? json['userid']).toString(),
        profileId: (json['profileId'] ?? json['profileid']).toString(),
        profileCode: (json['profileCode'] ?? json['profilecode']).toString(),
        profileName: (json['profileName'] ?? json['profilename']).toString(),
        displayName: (json['displayName'] ?? json['displayname']).toString(),
        loginName: (json['loginName'] ?? json['loginname']).toString(),
        email: (json['email'] ?? '').toString(),
        isActive: (json['isActive'] ?? json['isactive']) != false,
        userActive: (json['userActive'] ?? json['useractive']) != false,
      );

  final String userId;
  final String profileId;
  final String profileCode;
  final String profileName;
  final String displayName;
  final String loginName;
  final String email;
  final bool isActive;
  final bool userActive;
}
