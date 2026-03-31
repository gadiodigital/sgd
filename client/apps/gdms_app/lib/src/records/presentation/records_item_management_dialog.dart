import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_records/feature_records.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../application/records_item_management_view_model.dart';

/// Shows retention and legal-hold actions for a selected disposition item.
class RecordsItemManagementDialog extends StatefulWidget {
  const RecordsItemManagementDialog({
    required this.apiClient,
    required this.sessionViewModel,
    required this.item,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;
  final DispositionItem item;

  @override
  State<RecordsItemManagementDialog> createState() =>
      _RecordsItemManagementDialogState();
}

class _RecordsItemManagementDialogState
    extends State<RecordsItemManagementDialog> {
  final _legalHoldReasonController = TextEditingController();
  late final RecordsItemManagementViewModel _viewModel;
  String? _selectedPolicyCode;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordsItemManagementViewModel(
      widget.apiClient,
      widget.sessionViewModel,
    );
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _legalHoldReasonController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GdmsPageHeader(
                      title: widget.item.documentTitle,
                      subtitle:
                          '${widget.item.actionLabel} · vence ${widget.item.dueDateLabel}',
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel.message != null)
                      GdmsStatusBadge(
                        label: _viewModel.message!,
                        tone: _viewModel.state == ViewState.error
                            ? GdmsStatusTone.critical
                            : GdmsStatusTone.info,
                      ),
                    const SizedBox(height: 16),
                    _buildRetentionPolicySection(),
                    const SizedBox(height: 16),
                    _buildCreateLegalHoldSection(),
                    const SizedBox(height: 16),
                    _buildLegalHoldsSection(),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRetentionPolicySection() {
    return GdmsSectionCard(
      title: 'Política de retención',
      subtitle: 'Aplicá una política activa al documento seleccionado.',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedPolicyCode),
            initialValue: _selectedPolicyCode,
            decoration: const InputDecoration(labelText: 'Política'),
            items: _viewModel.policies
                .map(
                  (policy) => DropdownMenuItem<String>(
                    value: policy.code,
                    child: Text(policy.displayLabel),
                  ),
                )
                .toList(growable: false),
            onChanged: _viewModel.isBusy
                ? null
                : (value) => setState(() => _selectedPolicyCode = value),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _viewModel.isBusy || _selectedPolicyCode == null
                  ? null
                  : _applyRetentionPolicy,
              child: const Text('Aplicar política'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateLegalHoldSection() {
    return GdmsSectionCard(
      title: 'Crear legal hold',
      subtitle: 'Bloquea la disposición automática mientras exista un motivo.',
      child: Column(
        children: [
          TextField(
            controller: _legalHoldReasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ejemplo: conservación probatoria por litigio',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _viewModel.isBusy ? null : _createLegalHold,
              child: const Text('Crear legal hold'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalHoldsSection() {
    return GdmsSectionCard(
      title: 'Legal holds',
      subtitle: 'Alta, estado y liberación de bloqueos legales.',
      child: _viewModel.legalHolds.isEmpty
          ? const Text('No existen legal holds para este documento.')
          : Column(
              children: _viewModel.legalHolds
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(item.reason),
                        subtitle: Text(item.isActive ? 'Activo' : 'Liberado'),
                        trailing: item.isActive
                            ? TextButton(
                                onPressed: _viewModel.isBusy
                                    ? null
                                    : () => _releaseLegalHold(item.id),
                                child: const Text('Liberar'),
                              )
                            : null,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Future<void> _loadData() async {
    await _viewModel.load(widget.item.documentId);
    if (!mounted || _viewModel.policies.isEmpty) return;
    setState(() {
      _selectedPolicyCode = _viewModel.policies.first.code;
    });
  }

  Future<void> _applyRetentionPolicy() async {
    final policyCode = _selectedPolicyCode;
    if (policyCode == null) return;
    await _viewModel.applyRetentionPolicy(
      documentId: widget.item.documentId,
      policyCode: policyCode,
    );
  }

  Future<void> _createLegalHold() async {
    final reason = _legalHoldReasonController.text.trim();
    if (reason.isEmpty) {
      _viewModel.setMessage('Ingresá un motivo para crear el legal hold.');
      return;
    }

    final created = await _viewModel.createLegalHold(
      documentId: widget.item.documentId,
      reason: reason,
    );
    if (created) {
      _legalHoldReasonController.clear();
    }
  }

  Future<void> _releaseLegalHold(String legalHoldId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Liberar legal hold'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo de liberación',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Liberar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (reason == null || reason.isEmpty) return;
    await _viewModel.releaseLegalHold(
      documentId: widget.item.documentId,
      legalHoldId: legalHoldId,
      reason: reason,
    );
  }
}
