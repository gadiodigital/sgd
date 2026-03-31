import 'package:feature_workflow/feature_workflow.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Connects the workflow workspace to the GDMS backend API.
final class ApiWorkflowRepository implements WorkflowRepository {
  const ApiWorkflowRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<WorkflowOverview> loadOverview({required bool onlyMine}) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final response = await _apiClient.getList(
      '/api/tenants/${session.tenantId}/workflow/tasks?mine=$onlyMine',
    );
    final today = DateTime.now();
    final tasks = response.cast<Map<String, dynamic>>().map((item) {
      final dueAtRaw = item['dueAtUtc'] as String?;
      final dueAt = dueAtRaw == null ? null : DateTime.tryParse(dueAtRaw)?.toUtc();
      final isOverdue =
          dueAt != null &&
          (item['status'] as String? ?? 'OPEN') == 'OPEN' &&
          dueAt.toLocal().isBefore(DateTime(today.year, today.month, today.day));
      return WorkflowTaskItem(
        id: item['id'] as String? ?? '',
        documentId: item['documentId'] as String? ?? '',
        title: item['title'] as String? ?? 'Tarea sin título',
        notes: item['notes'] as String?,
        assignedToUserId: item['assignedToUserId'] as String?,
        status: item['status'] as String? ?? 'OPEN',
        dueAtLabel: dueAt == null
            ? 'Sin vencimiento'
            : ApiRepositoryFormatters.formatShortDate(dueAt),
        isOverdue: isOverdue,
      );
    }).toList(growable: false);

    final overdue = tasks.where((task) => task.isOverdue).length;

    return WorkflowOverview(
      onlyMine: onlyMine,
      openTasks: tasks.where((task) => task.status == 'OPEN').length,
      completedTasks: tasks.where((task) => task.status == 'COMPLETED').length,
      overdueTasks: overdue,
      tasks: tasks,
    );
  }

  @override
  Future<void> completeTask(String taskId) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postNoContent(
      '/api/tenants/$tenantId/workflow/tasks/$taskId/complete',
      const {},
    );
  }
}
