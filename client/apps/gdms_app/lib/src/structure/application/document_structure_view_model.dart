import 'dart:collection';
import 'dart:convert';

import 'package:core/core.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../domain/container_document_entry.dart';
import '../domain/container_node_entry.dart';
import '../domain/container_type_entry.dart';
import '../domain/container_type_rule_entry.dart';
import '../domain/document_link_option.dart';
import '../domain/structure_project_entry.dart';

final class DocumentStructureViewModel extends ViewModel {
  DocumentStructureViewModel(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  List<StructureProjectEntry> _projects = const [];
  List<ContainerTypeEntry> _containerTypes = const [];
  List<ContainerTypeRuleEntry> _rules = const [];
  List<ContainerNodeEntry> _containers = const [];
  List<ContainerDocumentEntry> _selectedContainerDocuments = const [];
  String? _selectedProjectId;
  String? _selectedContainerId;

  UnmodifiableListView<StructureProjectEntry> get projects =>
      UnmodifiableListView(_projects);
  UnmodifiableListView<ContainerTypeEntry> get containerTypes =>
      UnmodifiableListView(_containerTypes);
  UnmodifiableListView<ContainerTypeRuleEntry> get rules =>
      UnmodifiableListView(_rules);
  UnmodifiableListView<ContainerNodeEntry> get containers =>
      UnmodifiableListView(_containers);
  UnmodifiableListView<ContainerDocumentEntry> get selectedContainerDocuments =>
      UnmodifiableListView(_selectedContainerDocuments);
  String? get selectedProjectId => _selectedProjectId;
  String? get selectedContainerId => _selectedContainerId;

  StructureProjectEntry? get selectedProject => _projects
      .where((project) => project.id == _selectedProjectId)
      .firstOrNull;
  ContainerNodeEntry? get selectedContainer => _containers
      .where((container) => container.id == _selectedContainerId)
      .firstOrNull;

  Future<void> load() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return;
    }

    try {
      await run(() async {
        final projectJson = await _apiClient.getList(
          '/api/tenants/${session.tenantId}/structure/projects',
        );
        _projects = projectJson
            .cast<Map<String, dynamic>>()
            .map(StructureProjectEntry.fromJson)
            .toList(growable: false);
        if (_projects.isEmpty) {
          _selectedProjectId = null;
          _selectedContainerId = null;
          _containerTypes = const [];
          _rules = const [];
          _containers = const [];
          _selectedContainerDocuments = const [];
          setMessage('Crea un proyecto documental para comenzar.');
          return;
        }

        _selectedProjectId =
            _projects.any((item) => item.id == _selectedProjectId)
            ? _selectedProjectId
            : _projects.first.id;
        await _loadSelectedProjectDetails(session.tenantId);
        setMessage('Estructura documental cargada.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<void> selectProject(String projectId) async {
    _selectedProjectId = projectId;
    _selectedContainerId = null;
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      notifyListeners();
      return;
    }

    try {
      await run(() async {
        await _loadSelectedProjectDetails(session.tenantId);
        setMessage('Proyecto documental seleccionado.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<void> selectContainer(String? containerId) async {
    _selectedContainerId = containerId;
    _selectedContainerDocuments = const [];
    notifyListeners();
    if (containerId == null) {
      return;
    }
    await loadSelectedContainerDocuments();
  }

  Future<void> loadSelectedContainerDocuments() async {
    final session = _sessionViewModel.session;
    final projectId = _selectedProjectId;
    final containerId = _selectedContainerId;
    if (session == null || projectId == null || containerId == null) {
      return;
    }

    try {
      await run(() async {
        final payload = await _apiClient.getList(
          '/api/tenants/${session.tenantId}/structure/projects/$projectId/containers/$containerId/documents',
        );
        _selectedContainerDocuments = payload
            .cast<Map<String, dynamic>>()
            .map(ContainerDocumentEntry.fromJson)
            .toList(growable: false);
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<bool> createProject({
    required String code,
    required String name,
    String? description,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return false;
    }

    try {
      await run(() async {
        final created = await _apiClient.postObject(
          '/api/tenants/${session.tenantId}/structure/projects',
          {
            'code': code.trim(),
            'name': name.trim(),
            'description': description?.trim(),
          },
        );
        _selectedProjectId = created['id'] as String?;
      });
      await load();
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> createContainerType({
    required String code,
    required String name,
    required String iconKey,
    required bool isRootAllowed,
    required bool acceptsDocuments,
    required String metadataSchemaJson,
  }) async {
    final session = _sessionViewModel.session;
    final projectId = _selectedProjectId;
    if (session == null || projectId == null) {
      setMessage('Selecciona un proyecto documental.');
      return false;
    }

    try {
      final metadataSchema = _decodeObject(metadataSchemaJson);
      await run(() async {
        await _apiClient.postObject(
          '/api/tenants/${session.tenantId}/structure/projects/$projectId/container-types',
          {
            'code': code.trim(),
            'name': name.trim(),
            'iconKey': iconKey.trim(),
            'isRootAllowed': isRootAllowed,
            'acceptsDocuments': acceptsDocuments,
            'metadataSchema': metadataSchema,
          },
        );
      });
      await selectProject(projectId);
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> createRule({
    required String parentContainerTypeId,
    required String childContainerTypeId,
  }) async {
    final session = _sessionViewModel.session;
    final projectId = _selectedProjectId;
    if (session == null || projectId == null) {
      setMessage('Selecciona un proyecto documental.');
      return false;
    }

    try {
      await run(() async {
        await _apiClient.postObject(
          '/api/tenants/${session.tenantId}/structure/projects/$projectId/container-type-rules',
          {
            'parentContainerTypeId': parentContainerTypeId,
            'childContainerTypeId': childContainerTypeId,
          },
        );
      });
      await selectProject(projectId);
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> createContainer({
    required String containerTypeId,
    String? parentContainerId,
    required String code,
    required String name,
    required String metadataJson,
  }) async {
    final session = _sessionViewModel.session;
    final projectId = _selectedProjectId;
    if (session == null || projectId == null) {
      setMessage('Selecciona un proyecto documental.');
      return false;
    }

    try {
      final metadata = _decodeObject(metadataJson);
      await run(() async {
        final created = await _apiClient.postObject(
          '/api/tenants/${session.tenantId}/structure/projects/$projectId/containers',
          {
            'containerTypeId': containerTypeId,
            'parentContainerId': parentContainerId,
            'code': code.trim(),
            'name': name.trim(),
            'metadata': metadata,
          },
        );
        _selectedContainerId = created['id'] as String?;
      });
      await selectProject(projectId);
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<List<DocumentLinkOption>> loadDocumentOptions() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final payload = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/documents',
    );
    return payload
        .cast<Map<String, dynamic>>()
        .map(DocumentLinkOption.fromJson)
        .toList(growable: false);
  }

  Future<bool> attachDocument(String documentId) async {
    final session = _sessionViewModel.session;
    final projectId = _selectedProjectId;
    final containerId = _selectedContainerId;
    if (session == null || projectId == null || containerId == null) {
      setMessage('Selecciona un nodo que acepte documentos.');
      return false;
    }

    try {
      await run(() async {
        await _apiClient.postNoContent(
          '/api/tenants/${session.tenantId}/structure/projects/$projectId/containers/$containerId/documents',
          {'documentId': documentId},
        );
      });
      await loadSelectedContainerDocuments();
      setMessage('Documento vinculado al nodo.');
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  ContainerTypeEntry? findType(String id) =>
      _containerTypes.where((item) => item.id == id).firstOrNull;

  bool containerAcceptsDocuments(ContainerNodeEntry? container) {
    if (container == null) {
      return false;
    }
    return findType(container.containerTypeId)?.acceptsDocuments ?? false;
  }

  Future<void> _loadSelectedProjectDetails(String tenantId) async {
    final projectId = _selectedProjectId;
    if (projectId == null) {
      return;
    }

    final typeJson = await _apiClient.getList(
      '/api/tenants/$tenantId/structure/projects/$projectId/container-types',
    );
    final ruleJson = await _apiClient.getList(
      '/api/tenants/$tenantId/structure/projects/$projectId/container-type-rules',
    );
    final containerJson = await _apiClient.getList(
      '/api/tenants/$tenantId/structure/projects/$projectId/containers',
    );
    _containerTypes = typeJson
        .cast<Map<String, dynamic>>()
        .map(ContainerTypeEntry.fromJson)
        .toList(growable: false);
    _rules = ruleJson
        .cast<Map<String, dynamic>>()
        .map(ContainerTypeRuleEntry.fromJson)
        .toList(growable: false);
    _containers = containerJson
        .cast<Map<String, dynamic>>()
        .map(ContainerNodeEntry.fromJson)
        .toList(growable: false);
    if (_selectedContainerId != null &&
        !_containers.any((item) => item.id == _selectedContainerId)) {
      _selectedContainerId = null;
      _selectedContainerDocuments = const [];
    }
    if (_selectedContainerId != null) {
      final payload = await _apiClient.getList(
        '/api/tenants/$tenantId/structure/projects/$projectId/containers/$_selectedContainerId/documents',
      );
      _selectedContainerDocuments = payload
          .cast<Map<String, dynamic>>()
          .map(ContainerDocumentEntry.fromJson)
          .toList(growable: false);
    }
  }

  Map<String, Object?> _decodeObject(String rawJson) {
    final text = rawJson.trim().isEmpty ? '{}' : rawJson.trim();
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }
    throw const ApiException('El JSON debe ser un objeto.');
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'El JSON ingresado no tiene un formato válido.';
    }
    return 'No se pudo completar la operación de estructura documental.';
  }
}
