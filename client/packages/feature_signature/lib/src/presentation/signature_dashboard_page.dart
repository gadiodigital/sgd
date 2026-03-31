import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../application/signature_view_model.dart';
import '../domain/signature_envelope_item.dart';

/// Renders the document signature dashboard.
class SignatureDashboardPage extends StatefulWidget {
  const SignatureDashboardPage({
    required this.viewModel,
    this.onCreateRequested,
    this.onEnvelopeSelected,
    super.key,
  });

  final SignatureViewModel viewModel;
  final Future<void> Function(BuildContext context)? onCreateRequested;
  final Future<void> Function(BuildContext context, SignatureEnvelopeItem item)?
      onEnvelopeSelected;

  @override
  State<SignatureDashboardPage> createState() => _SignatureDashboardPageState();
}

class _SignatureDashboardPageState extends State<SignatureDashboardPage> {
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
        final filteredEnvelopes = widget.viewModel.filteredEnvelopes;
        if (overview == null && widget.viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Firma',
              subtitle:
                  'Solicitudes de firma electronica o digital por documento.',
            ),
            const SizedBox(height: 16),
            if (widget.viewModel.message != null)
              GdmsStatusBadge(
                label: widget.viewModel.message!,
                tone: widget.viewModel.isBusy
                    ? GdmsStatusTone.info
                    : GdmsStatusTone.neutral,
              ),
            const SizedBox(height: 16),
            if (overview != null) ...[
              _SignatureMetricsRow(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Filtros',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar firmante',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: widget.viewModel.updateQuery,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip('ALL', 'Todas'),
                        _buildStatusChip('PENDING', 'Pendientes'),
                        _buildStatusChip('COMPLETED', 'Completadas'),
                        _buildStatusChip('CANCELLED', 'Canceladas'),
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
              if (widget.onCreateRequested != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => widget.onCreateRequested!(context),
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Solicitar firma'),
                  ),
                ),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Solicitudes recientes',
                subtitle:
                    '${filteredEnvelopes.length} visibles de ${overview.envelopes.length}',
                child: filteredEnvelopes.isEmpty
                    ? const Text('No hay solicitudes de firma registradas.')
                    : Column(
                        children: filteredEnvelopes
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SignatureEnvelopeTile(
                                  item: item,
                                  isBusy: widget.viewModel.isBusy,
                                  onOpenDocument: widget.onEnvelopeSelected == null
                                      ? null
                                      : () => widget.onEnvelopeSelected!(
                                            context,
                                            item,
                                          ),
                                  onComplete: () => widget.viewModel
                                      .completeSignature(item.id),
                                  onCancel: () => _openCancelDialog(
                                    context,
                                    item,
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

class _SignatureMetricsRow extends StatelessWidget {
  const _SignatureMetricsRow({required this.viewModel});
  final SignatureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Pendientes',
            value: '${viewModel.filteredPendingRequests}',
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Firmadas',
            value: '${viewModel.filteredSignedRequests}',
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Digitales',
            value: '${viewModel.filteredDigitalRequests}',
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}

class _SignatureEnvelopeTile extends StatelessWidget {
  const _SignatureEnvelopeTile({
    required this.item,
    required this.isBusy,
    required this.onComplete,
    required this.onCancel,
    this.onOpenDocument,
  });

  final SignatureEnvelopeItem item;
  final bool isBusy;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback? onOpenDocument;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpenDocument,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(item.signerDisplayName),
      subtitle: Text(
        '${item.signerEmail} · ${item.signatureLevel} · ${item.providerCode} · ${item.dueAtLabel}',
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GdmsStatusBadge(
            label: item.status,
            tone: item.canComplete
                ? GdmsStatusTone.warning
                : GdmsStatusTone.success,
          ),
          if (onOpenDocument != null)
            OutlinedButton(
              onPressed: onOpenDocument,
              child: const Text('Documento'),
            ),
          if (item.canComplete)
            FilledButton(
              onPressed: isBusy ? null : onComplete,
              child: const Text('Completar'),
            ),
          if (item.canCancel)
            OutlinedButton(
              onPressed: isBusy ? null : onCancel,
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }
}

extension on _SignatureDashboardPageState {
  FilterChip _buildStatusChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: widget.viewModel.statusFilter == value,
      onSelected: (_) => widget.viewModel.updateStatusFilter(value),
    );
  }

  void _clearFilters() {
    _queryController.clear();
    widget.viewModel.clearFilters();
  }
  Future<void> _openCancelDialog(
    BuildContext context,
    SignatureEnvelopeItem item,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar solicitud de firma'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Describí el motivo de cancelación',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar solicitud'),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (confirmed != true || reason.length < 5) {
      return;
    }

    await widget.viewModel.cancelSignature(item.id, reason);
  }
}
