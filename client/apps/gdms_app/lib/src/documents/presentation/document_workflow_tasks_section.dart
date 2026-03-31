import 'package:design_system/design_system.dart';
import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';

/// Renders the workflow tasks associated with the current document.
class DocumentWorkflowTasksSection extends StatelessWidget {
  const DocumentWorkflowTasksSection({
    required this.tasks,
    required this.message,
    required this.isBusy,
    required this.onCreateRequested,
    required this.onCompleteRequested,
    super.key,
  });

  final List<WorkflowTaskItem> tasks;
  final String? message;
  final bool isBusy;
  final Future<void> Function() onCreateRequested;
  final Future<void> Function(WorkflowTaskItem task) onCompleteRequested;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Workflow documental',
      subtitle: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : onCreateRequested,
            icon: const Icon(Icons.add_task),
            label: const Text('Crear tarea'),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Text('No hay tareas asociadas a este documento.')
          else
            Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(task.title),
                        subtitle: Text(_buildSubtitle(task)),
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
                            if (task.canComplete)
                              FilledButton(
                                onPressed: isBusy
                                    ? null
                                    : () => onCompleteRequested(task),
                                child: const Text('Completar'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  String _buildSubtitle(WorkflowTaskItem task) {
    final parts = <String>[task.dueAtLabel];
    if (task.assignedToUserId != null && task.assignedToUserId!.isNotEmpty) {
      parts.add('Asignada');
    }
    if (task.notes != null && task.notes!.isNotEmpty) {
      parts.add(task.notes!);
    }

    return parts.join(' · ');
  }
}
