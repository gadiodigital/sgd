import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/notifications_view_model.dart';
import '../domain/notification_category_actions.dart';
import '../domain/notification_item.dart';

/// Renders the tenant notifications inbox.
class NotificationsDashboardPage extends StatefulWidget {
  const NotificationsDashboardPage({
    required this.viewModel,
    this.onItemActionRequested,
    super.key,
  });

  final NotificationsViewModel viewModel;
  final Future<void> Function(BuildContext context, NotificationItem item)?
      onItemActionRequested;

  @override
  State<NotificationsDashboardPage> createState() =>
      _NotificationsDashboardPageState();
}

class _NotificationsDashboardPageState extends State<NotificationsDashboardPage> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final overview = widget.viewModel.overview;
        final filteredItems = widget.viewModel.filteredItems;
        if (overview == null && widget.viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Notifications',
              subtitle:
                  'Inbox operativo de tareas, records, firmas y alertas de seguridad.',
            ),
            const SizedBox(height: 16),
            if (widget.viewModel.message != null)
              GdmsStatusBadge(
                label: widget.viewModel.message!,
                tone: widget.viewModel.state == ViewState.error
                    ? GdmsStatusTone.critical
                    : GdmsStatusTone.info,
              ),
            const SizedBox(height: 16),
            if (overview != null) ...[
              _NotificationsMetricsRow(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Filtros',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar alerta',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: widget.viewModel.updateQuery,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSeverityChip('ALL', 'Todas'),
                        _buildSeverityChip('INFO', 'Info'),
                        _buildSeverityChip('WARNING', 'Warning'),
                        _buildSeverityChip('ERROR', 'Error'),
                        _buildSeverityChip('CRITICAL', 'Crítica'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todas las categorías'),
                          selected: widget.viewModel.categoryFilter == 'ALL',
                          onSelected: (_) =>
                              widget.viewModel.updateCategoryFilter('ALL'),
                        ),
                        ...widget.viewModel.availableCategories.map(
                          (category) => FilterChip(
                            label: Text(category),
                            selected:
                                widget.viewModel.categoryFilter == category,
                            onSelected: (_) =>
                                widget.viewModel.updateCategoryFilter(category),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Alertas recientes',
                subtitle:
                    '${filteredItems.length} visibles de ${overview.items.length}',
                child: filteredItems.isEmpty
                    ? const Text('No hay notificaciones pendientes por el momento.')
                    : Column(
                        children: filteredItems
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  onTap: widget.onItemActionRequested == null
                                      ? null
                                      : () => widget.onItemActionRequested!(
                                          context,
                                          item,
                                        ),
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  title: Text(item.title),
                                  subtitle: Text(
                                    '${item.category} · ${item.detail} · ${item.occurredAtLabel}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (widget.onItemActionRequested != null)
                                        OutlinedButton(
                                          onPressed: () =>
                                              widget.onItemActionRequested!(
                                                context,
                                                item,
                                              ),
                                          child: Text(
                                            NotificationCategoryActions.labelFor(
                                              item,
                                            ),
                                          ),
                                        ),
                                      GdmsStatusBadge(
                                        label: item.severity,
                                        tone: item.severity == 'CRITICAL'
                                            ? GdmsStatusTone.critical
                                            : GdmsStatusTone.warning,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _NotificationsMetricsRow extends StatelessWidget {
  const _NotificationsMetricsRow({required this.viewModel});

  final NotificationsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Inbox',
            value: '${viewModel.filteredItems.length}',
            color: const Color(0xFF3949AB),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Críticas',
            value: '${viewModel.filteredCriticalItems}',
            color: const Color(0xFFC62828),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Warnings',
            value: '${viewModel.filteredWarningItems}',
            color: const Color(0xFFEF6C00),
          ),
        ),
      ],
    );
  }
}

extension on _NotificationsDashboardPageState {
  FilterChip _buildSeverityChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: widget.viewModel.severityFilter == value,
      onSelected: (_) => widget.viewModel.updateSeverityFilter(value),
    );
  }

  void _clearFilters() {
    _queryController.clear();
    widget.viewModel.clearFilters();
  }
}
