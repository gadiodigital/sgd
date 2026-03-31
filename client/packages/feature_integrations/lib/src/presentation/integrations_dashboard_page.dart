import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/integrations_view_model.dart';
import '../domain/integration_status_item.dart';

/// Renders the current status of configured infrastructure integrations.
class IntegrationsDashboardPage extends StatefulWidget {
  const IntegrationsDashboardPage({
    required this.viewModel,
    this.onItemSelected,
    super.key,
  });

  final IntegrationsViewModel viewModel;
  final Future<void> Function(BuildContext context, IntegrationStatusItem item)?
      onItemSelected;

  @override
  State<IntegrationsDashboardPage> createState() =>
      _IntegrationsDashboardPageState();
}

class _IntegrationsDashboardPageState extends State<IntegrationsDashboardPage> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.viewModel.query);
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
        final items = widget.viewModel.visibleItems;
        if (overview == null && widget.viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Integraciones',
              subtitle: 'Estado de conectividad y configuración operativa.',
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
              _IntegrationsFiltersSection(
                viewModel: widget.viewModel,
                queryController: _queryController,
              ),
              const SizedBox(height: 16),
              _IntegrationsMetricsRow(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Integraciones configuradas',
                child: items.isEmpty
                    ? const Text('No hay integraciones visibles para los filtros actuales.')
                    : Column(
                        children: items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _IntegrationStatusTile(
                                  item: item,
                                  onTap: widget.onItemSelected == null
                                      ? null
                                      : () => widget.onItemSelected!(context, item),
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

class _IntegrationsMetricsRow extends StatelessWidget {
  const _IntegrationsMetricsRow({required this.viewModel});

  final IntegrationsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Ready',
            value: '${viewModel.visibleReadyCount}',
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Warnings',
            value: '${viewModel.visibleWarningCount}',
            color: const Color(0xFFEF6C00),
          ),
        ),
      ],
    );
  }
}

class _IntegrationsFiltersSection extends StatelessWidget {
  const _IntegrationsFiltersSection({
    required this.viewModel,
    required this.queryController,
  });

  final IntegrationsViewModel viewModel;
  final TextEditingController queryController;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Explorar integraciones',
      subtitle: 'Filtra por texto, categoría o estado para aislar señales operativas.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              controller: queryController,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                hintText: 'Código, nombre o detalle',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: viewModel.updateQuery,
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              key: ValueKey(viewModel.categoryFilter),
              initialValue: viewModel.categoryFilter,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todas')),
                ...viewModel.availableCategories.map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ],
              onChanged: (value) => viewModel.updateCategoryFilter(value ?? ''),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              key: ValueKey(viewModel.statusFilter),
              initialValue: viewModel.statusFilter,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos')),
                ...viewModel.availableStatuses.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ),
                ),
              ],
              onChanged: (value) => viewModel.updateStatusFilter(value ?? ''),
            ),
          ),
          TextButton(
            onPressed: () {
              queryController.clear();
              viewModel.clearFilters();
            },
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}

class _IntegrationStatusTile extends StatelessWidget {
  const _IntegrationStatusTile({
    required this.item,
    this.onTap,
  });

  final IntegrationStatusItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(item.displayName),
      subtitle: Text('${item.category} · ${item.detail}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GdmsStatusBadge(
            label: item.status,
            tone: item.status == 'READY'
                ? GdmsStatusTone.success
                : item.status == 'EMULATOR'
                ? GdmsStatusTone.info
                : GdmsStatusTone.warning,
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
    );
  }
}
