import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/audit_overview_view_model.dart';

/// Renders a dedicated audit workspace with recent platform or organization events.
class AuditDashboardPage extends StatefulWidget {
  const AuditDashboardPage({required this.viewModel, super.key});

  final AuditOverviewViewModel viewModel;

  @override
  State<AuditDashboardPage> createState() => _AuditDashboardPageState();
}

class _AuditDashboardPageState extends State<AuditDashboardPage> {
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
        final filteredEvents = widget.viewModel.filteredEvents;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Auditoría',
              subtitle: 'Trazabilidad reciente de plataforma y operaciones.',
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
            if (overview == null && widget.viewModel.isBusy)
              const Center(child: CircularProgressIndicator())
            else if (overview != null) ...[
              _AuditMetricsRow(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Filtros',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar evento u organización',
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
                        _buildSeverityChip('CRITICAL', 'Crítico'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todas las organizaciones'),
                          selected: widget.viewModel.tenantFilter == 'ALL',
                          onSelected: (_) =>
                              widget.viewModel.updateTenantFilter('ALL'),
                        ),
                        ...widget.viewModel.availableTenants.map(
                          (tenantCode) => FilterChip(
                            label: Text(tenantCode),
                            selected:
                                widget.viewModel.tenantFilter == tenantCode,
                            onSelected: (_) =>
                                widget.viewModel.updateTenantFilter(tenantCode),
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
                title: 'Eventos recientes',
                subtitle:
                    '${filteredEvents.length} visibles de ${overview.recentEvents.length}',
                child: Column(
                  children: filteredEvents
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(event.eventType),
                            subtitle: Text(
                              '${event.tenantCode} · ${event.occurredAtLabel}',
                            ),
                            trailing: GdmsStatusBadge(
                              label: event.severity,
                              tone: event.severity == 'INFO'
                                  ? GdmsStatusTone.info
                                  : GdmsStatusTone.warning,
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

class _AuditMetricsRow extends StatelessWidget {
  const _AuditMetricsRow({required this.viewModel});

  final AuditOverviewViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final total = viewModel.filteredEvents.length;
    final critical = viewModel.filteredCriticalEvents;
    final warnings = viewModel.filteredWarningEvents;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        GdmsMetricTile(
          label: 'Eventos',
          value: '$total',
          color: const Color(0xFF1B5E20),
        ),
        GdmsMetricTile(
          label: 'Críticos',
          value: '$critical',
          color: const Color(0xFFB71C1C),
        ),
        GdmsMetricTile(
          label: 'Warnings',
          value: '$warnings',
          color: const Color(0xFFF57F17),
        ),
      ],
    );
  }
}

extension on _AuditDashboardPageState {
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
