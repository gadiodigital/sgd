/// Represents one workflow task shown in the dedicated workflow workspace.
final class WorkflowTaskItem {
  const WorkflowTaskItem({
    required this.id,
    required this.documentId,
    required this.title,
    required this.notes,
    required this.assignedToUserId,
    required this.status,
    required this.dueAtLabel,
    required this.isOverdue,
  });

  final String id;
  final String documentId;
  final String title;
  final String? notes;
  final String? assignedToUserId;
  final String status;
  final String dueAtLabel;
  final bool isOverdue;

  bool get canComplete => status == 'OPEN';
}
