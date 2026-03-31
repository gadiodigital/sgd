/// Represents one user that can be selected as workflow assignee.
final class WorkflowUserOption {
  const WorkflowUserOption({
    required this.id,
    required this.fullName,
  });

  final String id;
  final String fullName;
}
