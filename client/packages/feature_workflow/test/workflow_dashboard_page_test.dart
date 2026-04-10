import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra alterna solo mias selecciona crea y completa tareas',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DashboardWorkflowRepository();
      final viewModel = WorkflowViewModel(repository);
      WorkflowTaskItem? selectedTask;
      var createTapped = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: WorkflowDashboardPage(
              viewModel: viewModel,
              onCreateRequested: (_) async => createTapped++,
              onTaskSelected: (_, task) async {
                selectedTask = task;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Workflow'), findsOneWidget);
      expect(repository.loadOnlyMineCalls, [false]);
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('3 visibles de 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'contrato');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Abiertas'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('No hay tareas para los filtros actuales.'), findsOneWidget);

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));

      await tester.tap(find.widgetWithText(FilterChip, 'Solo mis tareas'));
      await tester.pumpAndSettle();
      expect(repository.loadOnlyMineCalls, [false, true]);
      expect(find.byType(ListTile), findsNWidgets(2));

      await tester.tap(find.text('Crear tarea'));
      await tester.pumpAndSettle();
      expect(createTapped, 1);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Documento').first);
      await tester.pumpAndSettle();
      expect(selectedTask?.id, 'task-1');

      await tester.tap(find.widgetWithText(FilledButton, 'Completar').first);
      await tester.pumpAndSettle();

      expect(repository.completedTaskIds, ['task-1']);
      expect(repository.loadOnlyMineCalls, [false, true, true]);
      expect(viewModel.message, 'Tarea completada correctamente.');
    },
  );
}

final class _DashboardWorkflowRepository implements WorkflowRepository {
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
