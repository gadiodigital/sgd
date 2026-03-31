/// Represents a document available to create a workflow task from the app.
final class WorkflowDocumentOption {
  const WorkflowDocumentOption({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}
