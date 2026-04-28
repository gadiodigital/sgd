import 'package:feature_config/feature_config.dart';
import 'package:feature_documents/feature_documents.dart';
import 'package:feature_integrations/feature_integrations.dart';
import 'package:feature_search/feature_search.dart';
import 'package:feature_signature/feature_signature.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import '../documents/presentation/open_document_details.dart';
import '../infrastructure/repositories/api_documents_repository.dart';
import '../infrastructure/repositories/api_search_repository.dart';
import '../infrastructure/repositories/api_signature_repository.dart';
import '../infrastructure/repositories/firebase_config_repository.dart';
import '../notifications/presentation/module_preview_dialog.dart';

Widget buildIntegrationsPage({
  required IntegrationsViewModel integrationsViewModel,
  required AppSessionViewModel sessionViewModel,
  required FirebaseRuntimeState firebaseRuntimeState,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return IntegrationsDashboardPage(
    viewModel: integrationsViewModel,
    onItemSelected: (context, item) {
      return openIntegrationStatusAction(
        context: context,
        item: item,
        sessionViewModel: sessionViewModel,
        firebaseRuntimeState: firebaseRuntimeState,
        showDialog: showDialog,
      );
    },
  );
}

Future<void> openIntegrationStatusAction({
  required BuildContext context,
  required IntegrationStatusItem item,
  required AppSessionViewModel sessionViewModel,
  required FirebaseRuntimeState firebaseRuntimeState,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return switch (item.category) {
    'CONFIG' => _openConfigPreview(
      context,
      item.displayName,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
    'SIGNATURE' => _openSignaturePreview(
      context,
      item.displayName,
      sessionViewModel,
      showDialog,
    ),
    'STORAGE' => _openDocumentsPreview(
      context,
      item.displayName,
      sessionViewModel,
      showDialog,
    ),
    'DATABASE' => _openSearchPreview(
      context,
      item.displayName,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
    _ => _openStatusInfo(context, item, showDialog),
  };
}

Future<void> _openConfigPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = ConfigViewModel(
    FirebaseConfigRepository(firebaseRuntimeState, sessionViewModel),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: ConfigDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> _openSignaturePreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = SignatureViewModel(
    ApiSignatureRepository(sessionViewModel.apiClient, sessionViewModel),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: SignatureDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> _openDocumentsPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = DocumentsViewModel(
    ApiDocumentsRepository(sessionViewModel.apiClient, sessionViewModel),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: DocumentsDashboardPage(
        viewModel: viewModel,
        onDocumentSelected: (dialogContext, document) {
          return openDocumentDetailsById(
            context: dialogContext,
            sessionViewModel: sessionViewModel,
            documentId: document.id,
            fallbackTitle: document.title,
            fallbackStatus: document.statusLabel,
          );
        },
      ),
    ),
  );
}

Future<void> _openSearchPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = SearchViewModel(
    ApiSearchRepository(
      sessionViewModel.apiClient,
      sessionViewModel,
      firebaseRuntimeState,
    ),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: SearchDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> _openStatusInfo(
  BuildContext context,
  IntegrationStatusItem item,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return showDialog(
    context,
    (_) => AlertDialog(
      title: Text(item.displayName),
      content: Text('${item.category} · ${item.status}\n\n${item.detail}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
