import 'package:flutter_test/flutter_test.dart';

import 'package:feature_workflow/feature_workflow.dart';

void main() {
  test('loads workflow overview data', () async {
    final viewModel = WorkflowViewModel(_FakeWorkflowRepository());

    await viewModel.load();

    expect(viewModel.overview?.openTasks, 2);
    expect(viewModel.overview?.tasks.length, 2);
    expect(viewModel.filteredTasks.length, 2);

    viewModel.updateStatusFilter('COMPLETED');
    expect(viewModel.filteredTasks.single.status, 'COMPLETED');

    viewModel.clearFilters();
    viewModel.updateQuery('contrato');
    expect(viewModel.filteredTasks.single.title, 'Aprobar contrato');
  });
}

final class _FakeWorkflowRepository implements WorkflowRepository {
  @override
  Future<void> completeTask(String taskId) async {}

  @override
  Future<WorkflowOverview> loadOverview({required bool onlyMine}) async {
    return const WorkflowOverview(
      onlyMine: false,
      openTasks: 2,
      completedTasks: 1,
      overdueTasks: 1,
      tasks: [
        WorkflowTaskItem(
          id: '1',
          documentId: 'doc-1',
          title: 'Aprobar contrato',
          notes: 'Revisar antes de firmar',
          assignedToUserId: 'user-1',
          status: 'OPEN',
          dueAtLabel: 'Hoy',
          isOverdue: false,
        ),
        WorkflowTaskItem(
          id: '2',
          documentId: 'doc-2',
          title: 'Cerrar circuito',
          notes: 'Tarea ya completada',
          assignedToUserId: 'user-2',
          status: 'COMPLETED',
          dueAtLabel: 'Ayer',
          isOverdue: false,
        ),
      ],
    );
  }
}
