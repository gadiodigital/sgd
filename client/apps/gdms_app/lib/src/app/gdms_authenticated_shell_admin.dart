import 'package:feature_admin/feature_admin.dart';
import 'package:flutter/material.dart';

import '../admin/presentation/admin_tenant_details_dialog.dart';
import '../admin/presentation/identity_management_dialog.dart';
import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import '../infrastructure/repositories/api_admin_tenant_details_repository.dart';
import 'gdms_authenticated_shell_admin_actions.dart';

/// Builds the admin workspace wiring for the authenticated shell.
Widget buildAdminPage({
  required AppSessionViewModel sessionViewModel,
  required FirebaseRuntimeState firebaseRuntimeState,
  required AdminOverviewViewModel adminViewModel,
  required Future<void> Function(BuildContext context, WidgetBuilder builder)
  showDialog,
}) {
  return AdminDashboardPage(
    viewModel: adminViewModel,
    onMetricSelected: (pageContext, metric, overview) {
      return openAdminMetricAction(
        pageContext,
        metric,
        overview,
        sessionViewModel,
        firebaseRuntimeState,
        showDialog,
      );
    },
    onEventSelected: (pageContext, event) {
      return openAdminEventAction(
        pageContext,
        event,
        sessionViewModel,
        showDialog,
      );
    },
    onTaskSelected: (pageContext, task) {
      return openAdminTaskAction(
        pageContext,
        task,
        sessionViewModel,
        firebaseRuntimeState,
        showDialog,
      );
    },
    onTenantSelected: sessionViewModel.identity?.isPlatformAdmin == true
        ? (pageContext, tenant) {
            return showDialog(
              pageContext,
              (_) => AdminTenantDetailsDialog(
                repository: ApiAdminTenantDetailsRepository(
                  sessionViewModel.apiClient,
                  sessionViewModel,
                ),
                tenant: tenant,
              ),
            );
          }
        : null,
    onManageUsersRequested:
        sessionViewModel.identity?.canManageTenantUsers == true
        ? (pageContext) {
            return showDialog(
              pageContext,
              (_) => IdentityManagementDialog(
                apiClient: sessionViewModel.apiClient,
                sessionViewModel: sessionViewModel,
              ),
            );
          }
        : null,
  );
}
