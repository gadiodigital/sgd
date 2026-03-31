import 'package:feature_documents/feature_documents.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../documents/presentation/document_details_dialog.dart';
import '../documents/presentation/upload_document_dialog.dart';

Widget buildDocumentsPage({
  required AppSessionViewModel sessionViewModel,
  required DocumentsViewModel documentsViewModel,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return DocumentsDashboardPage(
    viewModel: documentsViewModel,
    onUploadRequested: (pageContext) async {
      await showDialog(
        pageContext,
        (_) => UploadDocumentDialog(
          apiClient: sessionViewModel.apiClient,
          sessionViewModel: sessionViewModel,
          onUploaded: documentsViewModel.load,
        ),
      );
      await documentsViewModel.load();
    },
    onScanRequested: (pageContext) async {
      await showDialog(
        pageContext,
        (_) => UploadDocumentDialog(
          apiClient: sessionViewModel.apiClient,
          sessionViewModel: sessionViewModel,
          onUploaded: documentsViewModel.load,
          startWithScanner: true,
        ),
      );
      await documentsViewModel.load();
    },
    onDocumentSelected: (pageContext, document) {
      return showDialog(
        pageContext,
        (_) => DocumentDetailsDialog(
          apiClient: sessionViewModel.apiClient,
          sessionViewModel: sessionViewModel,
          document: document,
        ),
      );
    },
  );
}
