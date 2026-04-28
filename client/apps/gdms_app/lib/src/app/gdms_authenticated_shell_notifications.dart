import 'package:feature_audit/feature_audit.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:feature_records/feature_records.dart';
import 'package:feature_signature/feature_signature.dart';
import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../documents/presentation/open_document_details.dart';
import '../infrastructure/repositories/api_audit_repository.dart';
import '../infrastructure/repositories/api_records_repository.dart';
import '../infrastructure/repositories/api_signature_repository.dart';
import '../infrastructure/repositories/api_workflow_repository.dart';
import '../notifications/presentation/module_preview_dialog.dart';
import '../records/presentation/records_item_management_dialog.dart';

/// Builds the notifications workspace wiring for the authenticated shell.
Widget buildNotificationsPage({
  required NotificationsViewModel notificationsViewModel,
  required AppSessionViewModel sessionViewModel,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return NotificationsDashboardPage(
    viewModel: notificationsViewModel,
    onItemActionRequested: (context, item) {
      return switch (item.category) {
        'WORKFLOW' => _openWorkflowPreview(
          context,
          item,
          sessionViewModel,
          showDialog,
        ),
        'SIGNATURE' => _openSignaturePreview(
          context,
          item,
          sessionViewModel,
          showDialog,
        ),
        'RECORDS' => _openRecordsPreview(
          context,
          item,
          sessionViewModel,
          showDialog,
        ),
        'SECURITY' => _openAuditPreview(
          context,
          item,
          sessionViewModel,
          showDialog,
        ),
        _ => showDialog(
          context,
          (_) => AlertDialog(
            title: Text(item.title),
            content: Text('${item.category} · ${item.detail}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      };
    },
  );
}

Future<void> _openWorkflowPreview(
  BuildContext context,
  NotificationItem item,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel =
      WorkflowViewModel(
          ApiWorkflowRepository(sessionViewModel.apiClient, sessionViewModel),
        )
        ..updateStatusFilter('OPEN')
        ..updateQuery(item.title);
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: item.title,
      child: WorkflowDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> _openSignaturePreview(
  BuildContext context,
  NotificationItem item,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final status = item.title.toUpperCase().contains('CANCELADA')
      ? 'CANCELLED'
      : 'PENDING';
  final signerQuery = _suffixAfterColon(item.title);
  final viewModel = SignatureViewModel(
    ApiSignatureRepository(sessionViewModel.apiClient, sessionViewModel),
  )..updateStatusFilter(status);
  if (signerQuery.isNotEmpty) {
    viewModel.updateQuery(signerQuery);
  }
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: item.title,
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

Future<void> _openRecordsPreview(
  BuildContext context,
  NotificationItem item,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final documentQuery = _suffixAfterColon(item.title);
  final viewModel =
      RecordsViewModel(
        ApiRecordsRepository(sessionViewModel.apiClient, sessionViewModel),
      )..updateQueueFilter(
        item.detail.toUpperCase().contains('LEGAL HOLD')
            ? RecordsQueueFilter.legalHold
            : RecordsQueueFilter.executable,
      );
  if (documentQuery.isNotEmpty) {
    viewModel.updateQuery(documentQuery);
  }
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: item.title,
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

Future<void> _openAuditPreview(
  BuildContext context,
  NotificationItem item,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel =
      AuditOverviewViewModel(
          ApiAuditRepository(sessionViewModel.apiClient, sessionViewModel),
        )
        ..updateSeverityFilter(item.severity)
        ..updateQuery(
          item.title.toUpperCase().contains('INICIO DE SESIÓN')
              ? 'LOGIN_FAILED'
              : item.title.toUpperCase().replaceAll(' ', '_'),
        );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: item.title,
      child: AuditDashboardPage(viewModel: viewModel),
    ),
  );
}

String _suffixAfterColon(String value) {
  final separatorIndex = value.indexOf(':');
  if (separatorIndex < 0 || separatorIndex == value.length - 1) {
    return '';
  }

  return value.substring(separatorIndex + 1).trim();
}
