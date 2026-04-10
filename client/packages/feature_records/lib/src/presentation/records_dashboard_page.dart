import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/records_view_model.dart';
import '../domain/records_overview.dart';
import '../infrastructure/demo_records_repository.dart';

/// Shows retention policies, legal holds and disposition candidates.
class RecordsDashboardPage extends StatefulWidget {
  const RecordsDashboardPage({
    super.key,
    RecordsViewModel? viewModel,
    Future<void> Function(BuildContext context, DispositionItem item)?
        onManageRequested,
    Future<void> Function(BuildContext context, DispositionItem item)?
        onItemSelected,
  }) : _viewModel = viewModel,
       _onManageRequested = onManageRequested,
       _onItemSelected = onItemSelected;

  final RecordsViewModel? _viewModel;
  final Future<void> Function(BuildContext context, DispositionItem item)?
      _onManageRequested;
  final Future<void> Function(BuildContext context, DispositionItem item)?
      _onItemSelected;

  @override
  State<RecordsDashboardPage> createState() => _RecordsDashboardPageState();
}

class _RecordsDashboardPageState extends State<RecordsDashboardPage> {
  late final RecordsViewModel _viewModel;
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _viewModel = widget._viewModel ?? RecordsViewModel(DemoRecordsRepository());
    _queryController = TextEditingController();
    _viewModel.load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
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

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Records y cumplimiento',
              subtitle:
                  'Administra retencion, legal hold y ejecucion controlada de '
                  'disposicion con trazabilidad probatoria.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Politicas activas',
                    value: '${overview.policiesInUse}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Legal holds',
                    value: '${overview.legalHoldsActive}',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Vence esta semana',
                    value: '${overview.dueThisWeek}',
                    color: const Color(0xFFC4811C),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Pendiente de revisar',
                    value: '${overview.pendingReview}',
                    color: const Color(0xFF1E8A5B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Filtros',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar documento o acción',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _viewModel.updateQuery,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQueueChip(RecordsQueueFilter.all, 'Todas'),
                      _buildQueueChip(
                        RecordsQueueFilter.legalHold,
                        'Con legal hold',
                      ),
                      _buildQueueChip(
                        RecordsQueueFilter.executable,
                        'Ejecutables',
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
              title: 'Cola de disposicion',
              subtitle:
                  '${_viewModel.filteredQueue.length} visibles de ${overview.dispositionQueue.length}',
              child: _viewModel.filteredQueue.isEmpty
                  ? const Text(
                      'No hay items de disposicion para los filtros actuales.',
                    )
                  : Column(
                      children: _viewModel.filteredQueue
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: widget._onItemSelected == null
                                    ? null
                                    : () =>
                                          widget._onItemSelected!(context, item),
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                title: Text(item.documentTitle),
                                subtitle: Text(
                                  'Vencimiento ${item.dueDateLabel}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    if (widget._onItemSelected != null)
                                      OutlinedButton(
                                        onPressed: _viewModel.isBusy
                                            ? null
                                            : () => widget._onItemSelected!(
                                                context,
                                                item,
                                              ),
                                        child: const Text('Documento'),
                                      ),
                                    if (widget._onManageRequested != null)
                                      OutlinedButton(
                                        onPressed: _viewModel.isBusy
                                            ? null
                                            : () => widget._onManageRequested!(
                                                context,
                                                item,
                                              ),
                                        child: const Text('Gestionar'),
                                      ),
                                    if (item.canExecute)
                                      FilledButton(
                                        onPressed: _viewModel.isBusy
                                            ? null
                                            : () => _confirmDisposition(item),
                                        child: const Text('Ejecutar'),
                                      ),
                                    GdmsStatusBadge(
                                      label: item.actionLabel,
                                      tone: item.hasLegalHold
                                          ? GdmsStatusTone.critical
                                          : GdmsStatusTone.warning,
                                    ),
                                    if (item.hasLegalHold)
                                      const GdmsStatusBadge(
                                        label: 'Legal hold',
                                        tone: GdmsStatusTone.critical,
                                      ),
                                  ],
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

  Future<void> _confirmDisposition(DispositionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar disposición'),
          content: Text(
            'Se ejecutará la acción ${item.actionLabel.toLowerCase()} '
            'sobre ${item.documentTitle}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _viewModel.executeDisposition(item.documentId);
    }
  }

  FilterChip _buildQueueChip(RecordsQueueFilter value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _viewModel.queueFilter == value,
      onSelected: (_) => _viewModel.updateQueueFilter(value),
    );
  }

  void _clearFilters() {
    _queryController.clear();
    _viewModel.clearFilters();
  }
}
