import 'workflow_task_item.dart';

/// Represents the current workflow dashboard snapshot.
final class WorkflowOverview {
  const WorkflowOverview({
    required this.onlyMine,
    required this.openTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.tasks,
  });

  final bool onlyMine;
  final int openTasks;
  final int completedTasks;
  final int overdueTasks;
  final List<WorkflowTaskItem> tasks;
}
