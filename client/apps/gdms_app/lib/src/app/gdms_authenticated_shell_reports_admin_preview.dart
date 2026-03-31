import 'package:feature_admin/feature_admin.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';

import '../admin/presentation/admin_tenant_details_dialog.dart';
import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import '../infrastructure/repositories/api_admin_repository.dart';
import '../infrastructure/repositories/api_admin_tenant_details_repository.dart';
import '../notifications/presentation/module_preview_dialog.dart';
import 'gdms_authenticated_shell_admin_actions.dart';

Future<void> openReportsPlatformTenantsPreview(
  BuildContext context,
  PlatformReportMetricItem metric,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = AdminOverviewViewModel(
    ApiAdminRepository(sessionViewModel.apiClient, sessionViewModel),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: metric.label,
      child: AdminDashboardPage(
        viewModel: viewModel,
        onMetricSelected: (dialogContext, adminMetric, overview) {
          return openAdminMetricAction(
            dialogContext,
            adminMetric,
            overview,
            sessionViewModel,
            firebaseRuntimeState,
            showDialog,
          );
        },
        onEventSelected: (dialogContext, event) {
          return openAdminEventAction(
            dialogContext,
            event,
            sessionViewModel,
            showDialog,
          );
        },
        onTaskSelected: (dialogContext, task) {
          return openAdminTaskAction(
            dialogContext,
            task,
            sessionViewModel,
            firebaseRuntimeState,
            showDialog,
          );
        },
        onTenantSelected: (dialogContext, tenant) {
          return showDialog(
            dialogContext,
            (_) => AdminTenantDetailsDialog(
              repository: ApiAdminTenantDetailsRepository(
                sessionViewModel.apiClient,
                sessionViewModel,
              ),
              tenant: tenant,
            ),
          );
        },
      ),
    ),
  );
}
