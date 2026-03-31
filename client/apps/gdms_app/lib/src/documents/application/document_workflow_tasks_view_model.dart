import 'dart:collection';

import 'package:core/core.dart';
import 'package:feature_workflow/feature_workflow.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../../infrastructure/repositories/api_repository_formatters.dart';

/// Loads workflow tasks linked to the selected document.
final class DocumentWorkflowTasksViewModel extends ViewModel {
  DocumentWorkflowTasksViewModel(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  List<WorkflowTaskItem> _tasks = const [];

  UnmodifiableListView<WorkflowTaskItem> get tasks => UnmodifiableListView(_tasks);

  Future<void> load(String documentId) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return;
    }

    try {
      await run(() async {
        final response = await _apiClient.getList(
          '/api/tenants/${session.tenantId}/workflow/tasks',
        );
        _tasks = response
            .cast<Map<String, dynamic>>()
            .where((item) => item['documentId'] == documentId)
            .map(_mapTask)
            .toList(growable: false);
        setMessage(
          _tasks.isEmpty
              ? 'No hay tareas de workflow para este documento.'
              : 'Workflow documental cargado.',
        );
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<void> completeTask(String taskId, String documentId) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return;
    }

    try {
      await run(() async {
        await _apiClient.postNoContent(
          '/api/tenants/${session.tenantId}/workflow/tasks/$taskId/complete',
          const {},
        );
        await load(documentId);
        setMessage('Tarea documental completada correctamente.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  WorkflowTaskItem _mapTask(Map<String, dynamic> json) {
    final dueAtRaw = json['dueAtUtc'] as String?;
    final dueAt = dueAtRaw == null ? null : DateTime.tryParse(dueAtRaw)?.toUtc();
    final today = DateTime.now();
    return WorkflowTaskItem(
      id: json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      title: json['title'] as String? ?? 'Tarea',
      notes: json['notes'] as String?,
      assignedToUserId: json['assignedToUserId'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      dueAtLabel: dueAt == null
          ? 'Sin vencimiento'
          : ApiRepositoryFormatters.formatShortDate(dueAt),
      isOverdue:
          dueAt != null &&
          (json['status'] as String? ?? 'OPEN') == 'OPEN' &&
          dueAt.toLocal().isBefore(DateTime(today.year, today.month, today.day)),
    );
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo cargar el workflow del documento.';
  }
}
