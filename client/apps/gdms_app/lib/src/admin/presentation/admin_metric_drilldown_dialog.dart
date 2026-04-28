import 'package:design_system/design_system.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:flutter/material.dart';

/// Displays a local operational drill-down for admin KPIs.
class AdminMetricDrilldownDialog extends StatelessWidget {
  const AdminMetricDrilldownDialog({
    required this.title,
    required this.subtitle,
    required this.tenants,
    required this.tasks,
    this.events = const [],
    this.onTaskSelected,
    this.onTenantSelected,
    this.onEventSelected,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AdminTenantSummary> tenants;
  final List<GovernanceTask> tasks;
  final List<AdminAuditEvent> events;
  final Future<void> Function(BuildContext context, GovernanceTask task)?
  onTaskSelected;
  final Future<void> Function(BuildContext context, AdminTenantSummary tenant)?
  onTenantSelected;
  final Future<void> Function(BuildContext context, AdminAuditEvent event)?
  onEventSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GdmsPageHeader(
                title: title,
                subtitle: subtitle,
                trailing: IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    GdmsSectionCard(
                      title: 'Organización configurada',
                      subtitle:
                          'Alta inicial o configuración que requiere seguimiento.',
                      child: tenants.isEmpty
                          ? const Text(
                              'No hay datos de organización para revisar.',
                            )
                          : Column(
                              children: tenants
                                  .map(
                                    (tenant) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: ListTile(
                                        onTap: onTenantSelected == null
                                            ? null
                                            : () => onTenantSelected!(
                                                context,
                                                tenant,
                                              ),
                                        tileColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Text(tenant.name),
                                        subtitle: Text(
                                          '${tenant.code} · ${tenant.sector}',
                                        ),
                                        trailing: Text(tenant.createdAtLabel),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: 16),
                    GdmsSectionCard(
                      title: 'Backlog relacionado',
                      subtitle:
                          'Pendientes de plataforma asociados a activación y setup.',
                      child: tasks.isEmpty
                          ? const Text(
                              'No hay tareas relacionadas para mostrar.',
                            )
                          : Column(
                              children: tasks
                                  .map(
                                    (task) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: ListTile(
                                        onTap: onTaskSelected == null
                                            ? null
                                            : () => onTaskSelected!(
                                                context,
                                                task,
                                              ),
                                        tileColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                  .toList(growable: false),
                            ),
                    ),
                    if (events.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GdmsSectionCard(
                        title: 'Actividad reciente',
                        subtitle:
                            'Señales recientes para contextualizar el KPI.',
                        child: Column(
                          children: events
                              .map(
                                (event) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    onTap: onEventSelected == null
                                        ? null
                                        : () =>
                                              onEventSelected!(context, event),
                                    tileColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      event.eventType.replaceAll('_', ' '),
                                    ),
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
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
