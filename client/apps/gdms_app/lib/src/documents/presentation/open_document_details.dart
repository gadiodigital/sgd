import 'package:feature_documents/feature_documents.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import 'document_details_dialog.dart';

/// Opens the document details dialog after resolving the document from the API.
Future<void> openDocumentDetailsById({
  required BuildContext context,
  required AppSessionViewModel sessionViewModel,
  required String documentId,
  String? fallbackTitle,
  String? fallbackStatus,
}) async {
  final session = sessionViewModel.session;
  if (session == null) {
    return;
  }

  final response = await sessionViewModel.apiClient.getObject(
    '/api/tenants/${session.tenantId}/documents/$documentId',
  );
  if (!context.mounted) {
    return;
  }

  final createdAtRaw = response['createdAtUtc'] as String?;
  final updatedAtLabel = createdAtRaw == null
      ? 'Sin fecha'
      : createdAtRaw.split('T').first;

  await showDialog<void>(
    context: context,
    builder: (_) => DocumentDetailsDialog(
      apiClient: sessionViewModel.apiClient,
      sessionViewModel: sessionViewModel,
      document: DocumentRecord(
        id: response['id'] as String? ?? documentId,
        title: response['title'] as String? ?? fallbackTitle ?? 'Documento',
        typeLabel: response['documentTypeCode'] as String? ?? 'DOCUMENTO',
        classificationLabel:
            response['documentTypeCode'] as String? ?? 'DOCUMENTO',
        statusLabel: response['status'] as String? ?? fallbackStatus ?? 'ACTIVE',
        ownerLabel: session.tenantCode,
        updatedAtLabel: updatedAtLabel,
        onLegalHold: false,
      ),
    ),
  );
}
