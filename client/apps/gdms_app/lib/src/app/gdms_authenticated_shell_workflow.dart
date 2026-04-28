import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../documents/presentation/open_document_details.dart';
import '../workflow/presentation/create_workflow_task_dialog.dart';

/// Builds the workflow workspace wiring for the authenticated shell.
Widget buildWorkflowPage({
  required AppSessionViewModel sessionViewModel,
  required WorkflowViewModel workflowViewModel,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return WorkflowDashboardPage(
    viewModel: workflowViewModel,
    onTaskSelected: (context, task) async {
      await openDocumentDetailsById(
        context: context,
        sessionViewModel: sessionViewModel,
        documentId: task.documentId,
        fallbackTitle: task.title,
        fallbackStatus: task.status,
      );
    },
    onCreateRequested: (pageContext) async {
      await showDialog(
        pageContext,
        (_) => CreateWorkflowTaskDialog(
          apiClient: sessionViewModel.apiClient,
          sessionViewModel: sessionViewModel,
          onCreated: workflowViewModel.load,
        ),
      );
      await workflowViewModel.load();
    },
  );
}
