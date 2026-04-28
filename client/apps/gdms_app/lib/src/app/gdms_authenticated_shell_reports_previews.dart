import 'package:feature_audit/feature_audit.dart';
import 'package:feature_documents/feature_documents.dart';
import 'package:feature_records/feature_records.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:feature_signature/feature_signature.dart';
import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import '../documents/presentation/open_document_details.dart';
import '../infrastructure/repositories/api_audit_repository.dart';
import '../infrastructure/repositories/api_documents_repository.dart';
import '../infrastructure/repositories/api_records_repository.dart';
import '../infrastructure/repositories/api_signature_repository.dart';
import '../infrastructure/repositories/api_workflow_repository.dart';
import '../notifications/presentation/module_preview_dialog.dart';
import '../records/presentation/records_item_management_dialog.dart';
import 'gdms_authenticated_shell_reports_admin_preview.dart';

Future<void> openReportsPlatformMetricPreview(
  BuildContext context,
  PlatformReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return switch (metric.kind) {
    PlatformReportMetricKind.documents => _openDocumentsPreview(
      context,
      metric.label,
      sessionViewModel,
      showDialog,
    ),
    PlatformReportMetricKind.openWorkflowTasks => _openWorkflowPreview(
      context,
      metric.label,
      sessionViewModel,
      showDialog,
    ),
    PlatformReportMetricKind.pendingSignatures => _openSignaturePreview(
      context,
      metric.label,
      sessionViewModel,
      showDialog,
      status: 'PENDING',
    ),
    PlatformReportMetricKind.cancelledSignatures => _openSignaturePreview(
      context,
      metric.label,
      sessionViewModel,
      showDialog,
      status: 'CANCELLED',
    ),
    PlatformReportMetricKind.failedLoginsLast24Hours =>
      _openFailedLoginsPreview(
        context,
        metric.label,
        sessionViewModel,
        showDialog,
      ),
    PlatformReportMetricKind.tenants => openReportsPlatformTenantsPreview(
      context,
      metric,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
  };
}

Future<void> openReportsDocumentsPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return _openDocumentsPreview(context, title, sessionViewModel, showDialog);
}

Future<void> openReportsWorkflowPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return _openWorkflowPreview(context, title, sessionViewModel, showDialog);
}

Future<void> openReportsSignaturePreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog, {
  required String status,
}) {
  return _openSignaturePreview(
    context,
    title,
    sessionViewModel,
    showDialog,
    status: status,
  );
}

Future<void> openReportsFailedLoginsPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return _openFailedLoginsPreview(context, title, sessionViewModel, showDialog);
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

Future<void> _openWorkflowPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = WorkflowViewModel(
    ApiWorkflowRepository(sessionViewModel.apiClient, sessionViewModel),
  )..updateStatusFilter('OPEN');
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: WorkflowDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> _openSignaturePreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog, {
  required String status,
}) {
  final viewModel = SignatureViewModel(
    ApiSignatureRepository(sessionViewModel.apiClient, sessionViewModel),
  )..updateStatusFilter(status);
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: SignatureDashboardPage(
        viewModel: viewModel,
        onEnvelopeSelected: (dialogContext, envelope) {
          return openDocumentDetailsById(
            context: dialogContext,
            sessionViewModel: sessionViewModel,
            documentId: envelope.documentId,
            fallbackTitle: envelope.signerDisplayName,
            fallbackStatus: envelope.status,
          );
        },
      ),
    ),
  );
}

Future<void> _openFailedLoginsPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel =
      AuditOverviewViewModel(
          ApiAuditRepository(sessionViewModel.apiClient, sessionViewModel),
        )
        ..updateSeverityFilter('WARNING')
        ..updateQuery('LOGIN_FAILED');
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: AuditDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> openReportsComplianceMetricPreview(
  BuildContext context,
  ReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final filter = metric.label.toUpperCase().contains('LEGAL')
      ? RecordsQueueFilter.legalHold
      : RecordsQueueFilter.executable;
  final viewModel = RecordsViewModel(
    ApiRecordsRepository(sessionViewModel.apiClient, sessionViewModel),
  )..updateQueueFilter(filter);
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: metric.label,
      child: RecordsDashboardPage(
        viewModel: viewModel,
        onItemSelected: (dialogContext, dispositionItem) {
          return openDocumentDetailsById(
            context: dialogContext,
            sessionViewModel: sessionViewModel,
            documentId: dispositionItem.documentId,
            fallbackTitle: dispositionItem.documentTitle,
          );
        },
        onManageRequested: (dialogContext, dispositionItem) {
          return showDialog(
            dialogContext,
            (_) => RecordsItemManagementDialog(
              apiClient: sessionViewModel.apiClient,
              sessionViewModel: sessionViewModel,
              item: dispositionItem,
            ),
          );
        },
      ),
    ),
  );
}
