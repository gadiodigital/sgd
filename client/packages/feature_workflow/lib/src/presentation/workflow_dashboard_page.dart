import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/workflow_view_model.dart';
import '../domain/workflow_task_item.dart';

/// Renders document workflow tasks and approval actions.
class WorkflowDashboardPage extends StatefulWidget {
  const WorkflowDashboardPage({
    required this.viewModel,
    this.onCreateRequested,
    this.onTaskSelected,
    super.key,
  });

  final WorkflowViewModel viewModel;
  final Future<void> Function(BuildContext context)? onCreateRequested;
  final Future<void> Function(BuildContext context, WorkflowTaskItem task)?
      onTaskSelected;

  @override
  State<WorkflowDashboardPage> createState() => _WorkflowDashboardPageState();
}

class _WorkflowDashboardPageState extends State<WorkflowDashboardPage> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final overview = widget.viewModel.overview;
        final filteredTasks = widget.viewModel.filteredTasks;
        if (overview == null && widget.viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (overview == null) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Workflow',
              subtitle:
                  'Aprobaciones y tareas documentales simples de la organización.',
            ),
            const SizedBox(height: 16),
            if (widget.viewModel.message != null)
              GdmsStatusBadge(
                label: widget.viewModel.message!,
                tone: widget.viewModel.isBusy
                    ? GdmsStatusTone.info
                    : GdmsStatusTone.neutral,
              ),
            const SizedBox(height: 16),
            _WorkflowMetricsRow(viewModel: widget.viewModel),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Filtros',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar tarea',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: widget.viewModel.updateQuery,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Solo mis tareas'),
                        selected: widget.viewModel.onlyMine,
                        onSelected: (value) async {
                          widget.viewModel.updateOnlyMine(value);
                          await widget.viewModel.load();
                        },
                      ),
                      _buildStatusChip('ALL', 'Todas'),
                      _buildStatusChip('OPEN', 'Abiertas'),
                      _buildStatusChip('COMPLETED', 'Completadas'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.onCreateRequested != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => widget.onCreateRequested!(context),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Crear tarea'),
                ),
              ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Tareas recientes',
              subtitle:
                  '${filteredTasks.length} visibles de ${overview.tasks.length}',
              child: filteredTasks.isEmpty
                  ? const Text('No hay tareas para los filtros actuales.')
                  : Column(
                      children: filteredTasks
                          .map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _WorkflowTaskTile(
                                task: task,
                                isBusy: widget.viewModel.isBusy,
                                onOpenDocument:
                                    widget.onTaskSelected == null
                                    ? null
                                    : () =>
                                          widget.onTaskSelected!(context, task),
                                onComplete: () =>
                                    widget.viewModel.completeTask(task.id),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkflowMetricsRow extends StatelessWidget {
  const _WorkflowMetricsRow({required this.viewModel});

  final WorkflowViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Abiertas',
            value: '${viewModel.filteredOpenTasks}',
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Completadas',
            value: '${viewModel.filteredCompletedTasks}',
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Vencidas',
            value: '${viewModel.filteredOverdueTasks}',
            color: const Color(0xFFC62828),
          ),
        ),
      ],
    );
  }
}

class _WorkflowTaskTile extends StatelessWidget {
  const _WorkflowTaskTile({
    required this.task,
    required this.isBusy,
    required this.onComplete,
    this.onOpenDocument,
  });

  final WorkflowTaskItem task;
  final bool isBusy;
  final VoidCallback onComplete;
  final VoidCallback? onOpenDocument;

  String _buildSubtitle() {
    final parts = <String>[task.dueAtLabel];
    if (task.assignedToUserId != null && task.assignedToUserId!.isNotEmpty) {
      parts.add('Asignada');
    }
    if (task.isOverdue) {
      parts.add('Vencida');
    }
    if (task.notes != null && task.notes!.isNotEmpty) {
      parts.add(task.notes!);
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpenDocument,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(task.title),
      subtitle: Text(_buildSubtitle()),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GdmsStatusBadge(
            label: task.status,
            tone: task.canComplete
                ? GdmsStatusTone.warning
                : GdmsStatusTone.info,
          ),
          if (onOpenDocument != null)
            OutlinedButton(
              onPressed: onOpenDocument,
              child: const Text('Documento'),
            ),
          if (task.canComplete)
            FilledButton(
              onPressed: isBusy ? null : onComplete,
              child: const Text('Completar'),
            ),
        ],
      ),
    );
  }
}

extension on _WorkflowDashboardPageState {
  FilterChip _buildStatusChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: widget.viewModel.statusFilter == value,
      onSelected: (_) => widget.viewModel.updateStatusFilter(value),
    );
  }

  void _clearFilters() {
    _queryController.clear();
    widget.viewModel.clearFilters();
  }
}
