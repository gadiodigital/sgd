import 'package:core/core.dart';
import 'dart:collection';

import '../domain/workflow_overview.dart';
import '../domain/workflow_task_item.dart';
import '../domain/workflow_repository.dart';

/// Coordinates workflow dashboard state and task actions.
final class WorkflowViewModel extends ViewModel {
  WorkflowViewModel(this._repository);

  final WorkflowRepository _repository;
  WorkflowOverview? _overview;
  bool _onlyMine = false;
  String _query = '';
  String _statusFilter = 'ALL';

  WorkflowOverview? get overview => _overview;
  bool get onlyMine => _onlyMine;
  String get query => _query;
  String get statusFilter => _statusFilter;

  UnmodifiableListView<WorkflowTaskItem> get filteredTasks {
    final tasks = _overview?.tasks ?? const <WorkflowTaskItem>[];
    final normalizedQuery = _query.trim().toUpperCase();
    final filtered = tasks.where((task) {
      final matchesStatus = _statusFilter == 'ALL' || task.status == _statusFilter;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          task.title.toUpperCase().contains(normalizedQuery) ||
          (task.notes?.toUpperCase().contains(normalizedQuery) ?? false);
      return matchesStatus && matchesQuery;
    }).toList(growable: false);
    return UnmodifiableListView(filtered);
  }

  int get filteredOpenTasks =>
      filteredTasks.where((task) => task.status == 'OPEN').length;

  int get filteredCompletedTasks =>
      filteredTasks.where((task) => task.status == 'COMPLETED').length;

  int get filteredOverdueTasks =>
      filteredTasks.where((task) => task.isOverdue).length;

  void updateOnlyMine(bool value) {
    _onlyMine = value;
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = 'ALL';
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview(onlyMine: _onlyMine);
      setMessage(_onlyMine ? 'Mis tareas sincronizadas.' : 'Workflow sincronizado.');
    });
  }

  Future<void> completeTask(String taskId) async {
    await run(() async {
      await _repository.completeTask(taskId);
      _overview = await _repository.loadOverview(onlyMine: _onlyMine);
      setMessage('Tarea completada correctamente.');
    });
  }
}
