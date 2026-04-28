import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/admin_overview_view_model.dart';
import '../domain/admin_audit_event.dart';
import '../domain/admin_overview.dart';
import '../domain/admin_tenant_summary.dart';
import '../infrastructure/demo_admin_repository.dart';

/// Displays organization governance and security health indicators.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    AdminOverviewViewModel? viewModel,
    Future<void> Function(BuildContext context)? onManageUsersRequested,
    Future<void> Function(
      BuildContext context,
      AdminMetricItem metric,
      AdminOverview overview,
    )?
    onMetricSelected,
    Future<void> Function(BuildContext context, AdminAuditEvent event)?
    onEventSelected,
    Future<void> Function(BuildContext context, GovernanceTask task)?
    onTaskSelected,
    Future<void> Function(BuildContext context, AdminTenantSummary tenant)?
    onTenantSelected,
  }) : _viewModel = viewModel,
       _onManageUsersRequested = onManageUsersRequested,
       _onMetricSelected = onMetricSelected,
       _onEventSelected = onEventSelected,
       _onTaskSelected = onTaskSelected,
       _onTenantSelected = onTenantSelected;

  final AdminOverviewViewModel? _viewModel;
  final Future<void> Function(BuildContext context)? _onManageUsersRequested;
  final Future<void> Function(
    BuildContext context,
    AdminMetricItem metric,
    AdminOverview overview,
  )?
  _onMetricSelected;
  final Future<void> Function(BuildContext context, AdminAuditEvent event)?
  _onEventSelected;
  final Future<void> Function(BuildContext context, GovernanceTask task)?
  _onTaskSelected;
  final Future<void> Function(BuildContext context, AdminTenantSummary tenant)?
  _onTenantSelected;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminOverviewViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget._viewModel ?? AdminOverviewViewModel(DemoAdminRepository());
    _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final overview = _viewModel.overview;

        if (overview == null && _viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (overview == null) {
          return const SizedBox.shrink();
        }

        final metrics =
            [
                  AdminMetricItem(
                    label: 'Organización activa',
                    value: overview.activeTenants,
                    colorHex: Theme.of(context).colorScheme.primary.toARGB32(),
                    kind: AdminMetricKind.activeTenants,
                  ),
                  const AdminMetricItem(
                    label: 'Provisioning pendiente',
                    value: 0,
                    colorHex: 0xFFC4811C,
                    kind: AdminMetricKind.pendingProvisioning,
                  ),
                  AdminMetricItem(
                    label: 'Failed logins 24h',
                    value: overview.failedLogins24h,
                    colorHex: Theme.of(context).colorScheme.error.toARGB32(),
                    kind: AdminMetricKind.failedLogins24h,
                  ),
                  const AdminMetricItem(
                    label: 'Alertas de storage',
                    value: 0,
                    colorHex: 0xFF1E8A5B,
                    kind: AdminMetricKind.storageAlerts,
                  ),
                ]
                .map((item) {
                  return item.kind == AdminMetricKind.pendingProvisioning
                      ? AdminMetricItem(
                          label: item.label,
                          value: overview.pendingProvisioning,
                          colorHex: item.colorHex,
                          kind: item.kind,
                        )
                      : item.kind == AdminMetricKind.storageAlerts
                      ? AdminMetricItem(
                          label: item.label,
                          value: overview.storageAlerts,
                          colorHex: item.colorHex,
                          kind: item.kind,
                        )
                      : item;
                })
                .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GdmsPageHeader(
              title: 'Administracion y gobierno',
              subtitle:
                  'Controla la organización, postura de seguridad y pendientes '
                  'operativos de la plataforma documental.',
              trailing: _buildHeaderActions(context),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: metrics
                  .map((metric) => _buildMetricTile(context, metric, overview))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Backlog operativo',
              subtitle: _viewModel.message,
              child: Column(
                children: overview.tasks
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: widget._onTaskSelected == null
                              ? null
                              : () => widget._onTaskSelected!(context, task),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(task.title),
                          subtitle: Text(task.ownerLabel),
                          trailing: GdmsStatusBadge(
                            label: task.priorityLabel,
                            tone: task.priorityLabel == 'Alta'
                                ? GdmsStatusTone.critical
                                : GdmsStatusTone.warning,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Organización configurada',
              child: Column(
                children: overview.tenants
                    .map(
                      (tenant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: widget._onTenantSelected == null
                              ? null
                              : () =>
                                    widget._onTenantSelected!(context, tenant),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(tenant.name),
                          subtitle: Text('${tenant.code} · ${tenant.sector}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tenant.createdAtLabel),
                              if (widget._onTenantSelected != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Actividad reciente',
              child: Column(
                children: overview.recentEvents
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: widget._onEventSelected == null
                              ? null
                              : () => widget._onEventSelected!(context, event),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(_formatEventTitle(event)),
                          subtitle: Text(
                            '${event.tenantCode} · ${event.occurredAtLabel}',
                          ),
                          trailing: GdmsStatusBadge(
                            label: event.severity,
                            tone: event.severity == 'CRITICAL'
                                ? GdmsStatusTone.critical
                                : event.severity == 'WARNING'
                                ? GdmsStatusTone.warning
                                : GdmsStatusTone.info,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatEventTitle(AdminAuditEvent event) {
    return event.eventType.replaceAll('_', ' ');
  }

  Widget? _buildHeaderActions(BuildContext context) {
    final hasManage = widget._onManageUsersRequested != null;
    if (!hasManage) {
      return null;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (hasManage)
          OutlinedButton.icon(
            onPressed: () => widget._onManageUsersRequested!(context),
            icon: const Icon(Icons.manage_accounts),
            label: const Text('Usuarios'),
          ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    AdminMetricItem metric,
    AdminOverview overview,
  ) {
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget._onMetricSelected == null
            ? null
            : () => widget._onMetricSelected!(context, metric, overview),
        child: GdmsMetricTile(
          label: metric.label,
          value: '${metric.value}',
          color: Color(metric.colorHex),
        ),
      ),
    );
  }
}
