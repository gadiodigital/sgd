import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import 'gdms_authenticated_shell_reports_previews.dart';

/// Builds the reports workspace wiring for the authenticated shell.
Widget buildReportsPage({
  required ReportsViewModel reportsViewModel,
  required AppSessionViewModel sessionViewModel,
  required FirebaseRuntimeState firebaseRuntimeState,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
      showDialog,
}) {
  return ReportsDashboardPage(
    viewModel: reportsViewModel,
    onMetricSelected: (context, metric) {
      return switch (metric.lens) {
        ReportsLens.workflow => _openWorkflowMetricPreview(
          context,
          metric,
          sessionViewModel,
          showDialog,
        ),
        ReportsLens.signatures => _openSignatureMetricPreview(
          context,
          metric,
          sessionViewModel,
          showDialog,
        ),
        ReportsLens.compliance => _openComplianceMetricPreview(
          context,
          metric,
          sessionViewModel,
          showDialog,
        ),
        ReportsLens.security => _openSecurityMetricPreview(
          context,
          metric,
          sessionViewModel,
          showDialog,
        ),
        ReportsLens.all => openReportsDocumentsPreview(
          context,
          metric.label,
          sessionViewModel,
          showDialog,
        ),
      };
    },
    onPlatformMetricSelected: (context, metric) => openReportsPlatformMetricPreview(
      context,
      metric,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
  );
}

Future<void> _openWorkflowMetricPreview(
  BuildContext context,
  ReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return openReportsWorkflowPreview(
    context,
    metric.label,
    sessionViewModel,
    showDialog,
  );
}

Future<void> _openSignatureMetricPreview(
  BuildContext context,
  ReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final status = metric.label.toUpperCase().contains('CANCELADAS') ? 'CANCELLED' : 'PENDING';
  return openReportsSignaturePreview(
    context,
    metric.label,
    sessionViewModel,
    showDialog,
    status: status,
  );
}

Future<void> _openComplianceMetricPreview(
  BuildContext context,
  ReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return openReportsComplianceMetricPreview(
    context,
    metric,
    sessionViewModel,
    showDialog,
  );
}

Future<void> _openSecurityMetricPreview(
  BuildContext context,
  ReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return openReportsFailedLoginsPreview(
    context,
    metric.label,
    sessionViewModel,
    showDialog,
  );
}
