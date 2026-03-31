import 'workflow_overview.dart';

/// Defines the read/write contract for the workflow workspace.
abstract interface class WorkflowRepository {
  Future<WorkflowOverview> loadOverview({required bool onlyMine});
  Future<void> completeTask(String taskId);
}
