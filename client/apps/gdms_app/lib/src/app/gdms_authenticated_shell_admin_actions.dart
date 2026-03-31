import 'package:feature_admin/feature_admin.dart';
import 'package:feature_audit/feature_audit.dart';
import 'package:feature_integrations/feature_integrations.dart';
import 'package:flutter/material.dart';

import '../admin/presentation/admin_metric_drilldown_dialog.dart';
import '../admin/presentation/admin_tenant_details_dialog.dart';
import '../admin/presentation/identity_management_dialog.dart';
import '../auth/application/app_session_view_model.dart';
import '../config/application/firebase_runtime_state.dart';
import '../infrastructure/repositories/api_admin_tenant_details_repository.dart';
import '../infrastructure/repositories/api_audit_repository.dart';
import '../infrastructure/repositories/api_integrations_repository.dart';
import '../notifications/presentation/module_preview_dialog.dart';
import 'gdms_authenticated_shell_integrations.dart';

Future<void> openAdminMetricAction(
  BuildContext context,
  AdminMetricItem metric,
  AdminOverview overview,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return switch (metric.kind) {
    AdminMetricKind.failedLogins24h => _openFailedLoginsPreview(
      context,
      metric.label,
      sessionViewModel,
      showDialog,
    ),
    AdminMetricKind.activeTenants => _openActiveTenantsPreview(
      context,
      metric,
      overview,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
    AdminMetricKind.pendingProvisioning => _openProvisioningPreview(
      context,
      metric,
      overview,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
    AdminMetricKind.storageAlerts => _openStorageAlertsPreview(
      context,
      metric.label,
      sessionViewModel,
      firebaseRuntimeState,
      showDialog,
    ),
  };
}

Future<void> openAdminEventAction(
  BuildContext context,
  AdminAuditEvent event,
  AppSessionViewModel sessionViewModel,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = AuditOverviewViewModel(
    ApiAuditRepository(sessionViewModel.apiClient, sessionViewModel),
  )
    ..updateQuery(event.eventType)
    ..updateSeverityFilter(event.severity == 'INFO' ? '' : event.severity);
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: event.eventType.replaceAll('_', ' '),
      child: AuditDashboardPage(viewModel: viewModel),
    ),
  );
}

Future<void> openAdminTaskAction(
  BuildContext context,
  GovernanceTask task,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final normalizedTitle = task.title.toUpperCase();
  if (normalizedTitle.contains('LOGIN') || normalizedTitle.contains('JWT')) {
    final viewModel = AuditOverviewViewModel(
      ApiAuditRepository(sessionViewModel.apiClient, sessionViewModel),
    )
      ..updateSeverityFilter('WARNING')
      ..updateQuery('LOGIN');
    return showDialog(
      context,
      (_) => ModulePreviewDialog(
        title: task.title,
        child: AuditDashboardPage(viewModel: viewModel),
      ),
    );
  }

  if (normalizedTitle.contains('PERMISOS') ||
      normalizedTitle.contains('USUARIO') ||
      normalizedTitle.contains('OFFICER')) {
    return showDialog(
      context,
      (_) => IdentityManagementDialog(
        apiClient: sessionViewModel.apiClient,
        sessionViewModel: sessionViewModel,
      ),
    );
  }

  final viewModel = IntegrationsViewModel(
    ApiIntegrationsRepository(sessionViewModel.apiClient, sessionViewModel),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: task.title,
      child: IntegrationsDashboardPage(
        viewModel: viewModel,
        onItemSelected: (dialogContext, item) {
          return openIntegrationStatusAction(
            context: dialogContext,
            item: item,
            sessionViewModel: sessionViewModel,
            firebaseRuntimeState: firebaseRuntimeState,
            showDialog: showDialog,
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
  final viewModel = AuditOverviewViewModel(
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

Future<void> _openActiveTenantsPreview(
  BuildContext context,
  AdminMetricItem metric,
  AdminOverview overview,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  return showDialog(
    context,
    (_) => AdminMetricDrilldownDialog(
      title: metric.label,
      subtitle:
          'KPI actual: ${metric.value}. Explora tenants activos y señales recientes de gobierno.',
      tenants: overview.tenants,
      tasks: overview.tasks,
      events: overview.recentEvents,
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
    ),
  );
}

Future<void> _openProvisioningPreview(
  BuildContext context,
  AdminMetricItem metric,
  AdminOverview overview,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final relevantTasks = overview.tasks
      .where(
        (task) =>
            task.ownerLabel == 'Plataforma' ||
            task.ownerLabel == 'Arquitectura',
      )
      .toList(growable: false);
  return showDialog(
    context,
    (_) => AdminMetricDrilldownDialog(
      title: metric.label,
      subtitle:
          'KPI actual: ${metric.value}. Revisa nuevas altas y backlog de activación.',
      tenants: overview.tenants,
      tasks: relevantTasks,
      events: overview.recentEvents,
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
    ),
  );
}

Future<void> _openStorageAlertsPreview(
  BuildContext context,
  String title,
  AppSessionViewModel sessionViewModel,
  FirebaseRuntimeState firebaseRuntimeState,
  Future<void> Function(BuildContext context, WidgetBuilder builder) showDialog,
) {
  final viewModel = IntegrationsViewModel(
    ApiIntegrationsRepository(sessionViewModel.apiClient, sessionViewModel),
  );
  return showDialog(
    context,
    (_) => ModulePreviewDialog(
      title: title,
      child: IntegrationsDashboardPage(
        viewModel: viewModel,
        onItemSelected: (dialogContext, item) {
          return openIntegrationStatusAction(
            context: dialogContext,
            item: item,
            sessionViewModel: sessionViewModel,
            firebaseRuntimeState: firebaseRuntimeState,
            showDialog: showDialog,
          );
        },
      ),
    ),
  );
}
