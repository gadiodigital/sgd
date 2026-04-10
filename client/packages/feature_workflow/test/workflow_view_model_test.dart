import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load sincroniza overview y filtros por query, estado y onlyMine', () async {
    final repository = _RecordingWorkflowRepository();
    final viewModel = WorkflowViewModel(repository);

    await viewModel.load();

    expect(repository.loadOnlyMineCalls, [false]);
    expect(viewModel.overview?.openTasks, 2);
    expect(viewModel.filteredTasks.length, 3);
    expect(viewModel.filteredOpenTasks, 2);
    expect(viewModel.filteredCompletedTasks, 1);
    expect(viewModel.filteredOverdueTasks, 1);
    expect(viewModel.message, 'Workflow sincronizado.');

    viewModel.updateQuery('contrato');
    expect(viewModel.filteredTasks.map((item) => item.id), ['task-1']);

    viewModel.updateQuery('');
    viewModel.updateStatusFilter('COMPLETED');
    expect(viewModel.filteredTasks.map((item) => item.id), ['task-2']);

    viewModel.clearFilters();
    viewModel.updateOnlyMine(true);
    await viewModel.load();
    expect(repository.loadOnlyMineCalls, [false, true]);
    expect(viewModel.message, 'Mis tareas sincronizadas.');
  });

  test('completeTask recarga overview y publica mensaje de exito', () async {
    final repository = _RecordingWorkflowRepository();
    final viewModel = WorkflowViewModel(repository);

    await viewModel.load();
    await viewModel.completeTask('task-1');

    expect(repository.completedTaskIds, ['task-1']);
    expect(repository.loadOnlyMineCalls, [false, false]);
    expect(viewModel.message, 'Tarea completada correctamente.');
  });
}

final class _RecordingWorkflowRepository implements WorkflowRepository {
  final List<bool> loadOnlyMineCalls = <bool>[];
  final List<String> completedTaskIds = <String>[];

  @override
  Future<void> completeTask(String taskId) async {
    completedTaskIds.add(taskId);
  }

  @override
  Future<WorkflowOverview> loadOverview({required bool onlyMine}) async {
    loadOnlyMineCalls.add(onlyMine);
    return WorkflowOverview(
      onlyMine: onlyMine,
      openTasks: 2,
      completedTasks: 1,
      overdueTasks: 1,
      tasks: onlyMine ? _onlyMineTasks : _allTasks,
    );
  }

  static const List<WorkflowTaskItem> _allTasks = [
    WorkflowTaskItem(
      id: 'task-1',
      documentId: 'doc-1',
      title: 'Aprobar contrato',
      notes: 'Revisar antes de firmar',
      assignedToUserId: 'user-1',
      status: 'OPEN',
      dueAtLabel: 'Hoy',
      isOverdue: false,
    ),
    WorkflowTaskItem(
      id: 'task-2',
      documentId: 'doc-2',
      title: 'Cerrar circuito',
      notes: 'Tarea ya completada',
      assignedToUserId: 'user-2',
      status: 'COMPLETED',
      dueAtLabel: 'Ayer',
      isOverdue: false,
    ),
    WorkflowTaskItem(
      id: 'task-3',
      documentId: 'doc-3',
      title: 'Escalar vencimiento',
      notes: 'Pendiente hace 48h',
      assignedToUserId: 'user-1',
      status: 'OPEN',
      dueAtLabel: 'Vencida',
      isOverdue: true,
    ),
  ];

  static const List<WorkflowTaskItem> _onlyMineTasks = [
    WorkflowTaskItem(
      id: 'task-1',
      documentId: 'doc-1',
      title: 'Aprobar contrato',
      notes: 'Revisar antes de firmar',
      assignedToUserId: 'user-1',
      status: 'OPEN',
      dueAtLabel: 'Hoy',
      isOverdue: false,
    ),
    WorkflowTaskItem(
      id: 'task-3',
      documentId: 'doc-3',
      title: 'Escalar vencimiento',
      notes: 'Pendiente hace 48h',
      assignedToUserId: 'user-1',
      status: 'OPEN',
      dueAtLabel: 'Vencida',
      isOverdue: true,
    ),
  ];
}
