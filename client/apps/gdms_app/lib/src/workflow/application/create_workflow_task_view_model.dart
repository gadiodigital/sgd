import 'dart:collection';

import 'package:core/core.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../domain/workflow_document_option.dart';
import '../domain/workflow_user_option.dart';

/// Loads document options and creates workflow tasks from the app layer.
final class CreateWorkflowTaskViewModel extends ViewModel {
  CreateWorkflowTaskViewModel(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  List<WorkflowDocumentOption> _documents = const [];
  List<WorkflowUserOption> _users = const [];

  UnmodifiableListView<WorkflowDocumentOption> get documents =>
      UnmodifiableListView(_documents);
  UnmodifiableListView<WorkflowUserOption> get users =>
      UnmodifiableListView(_users);

  Future<void> loadDocuments() async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      setMessage('No hay una sesión activa para crear tareas.');
      return;
    }

    try {
      await run(() async {
        final response = await _apiClient.getList('/api/tenants/$tenantId/documents');
        _documents = response.cast<Map<String, dynamic>>().map((item) {
          return WorkflowDocumentOption(
            id: item['id'] as String? ?? '',
            title: item['title'] as String? ?? 'Documento sin título',
          );
        }).toList(growable: false);
        setMessage('Documentos disponibles cargados.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<void> loadUsers() async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      setMessage('No hay una sesión activa para crear tareas.');
      return;
    }

    try {
      await run(() async {
        final response = await _apiClient.getList('/api/tenants/$tenantId/users');
        _users = response.cast<Map<String, dynamic>>().map((item) {
          return WorkflowUserOption(
            id: item['id'] as String? ?? '',
            fullName: item['fullName'] as String? ?? 'Usuario',
          );
        }).where((item) => item.id.isNotEmpty).toList(growable: false);
        setMessage('Usuarios disponibles cargados.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<bool> createTask({
    required String documentId,
    required String title,
    String? notes,
    String? dueDate,
    String? assignedToUserId,
  }) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      setMessage('No hay una sesión activa para crear tareas.');
      return false;
    }

    try {
      await run(() async {
        await _apiClient.postObject('/api/tenants/$tenantId/workflow/tasks', {
          'documentId': documentId,
          'title': title.trim(),
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
          'assignedToUserId': assignedToUserId?.trim().isEmpty == true
              ? null
              : assignedToUserId?.trim(),
          'dueAtUtc': _normalizeDueDate(dueDate),
        });
        setMessage('Tarea creada correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  String? _normalizeDueDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return '${text}T00:00:00Z';
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo crear la tarea de workflow.';
  }
}
