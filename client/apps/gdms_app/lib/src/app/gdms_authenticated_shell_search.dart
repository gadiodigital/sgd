import 'package:feature_documents/feature_documents.dart';
import 'package:feature_search/feature_search.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../documents/presentation/document_details_dialog.dart';

Widget buildSearchPage({
  required AppSessionViewModel sessionViewModel,
  required SearchViewModel searchViewModel,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return SearchDashboardPage(
    viewModel: searchViewModel,
    onResultSelected: (pageContext, result) {
      return showDialog(
        pageContext,
        (_) => DocumentDetailsDialog(
          apiClient: sessionViewModel.apiClient,
          sessionViewModel: sessionViewModel,
          document: DocumentRecord(
            id: result.id,
            title: result.title,
            typeLabel: result.documentTypeCode,
            classificationLabel: result.documentTypeCode,
            statusLabel: result.status,
            ownerLabel: sessionViewModel.session?.tenantCode ?? 'GDMS',
            updatedAtLabel: result.updatedAtLabel,
            onLegalHold: false,
          ),
        ),
      );
    },
  );
}
