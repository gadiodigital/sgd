import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/corporate_dashboard_view_model.dart';
import '../domain/corporate_dashboard_overview.dart';
import '../domain/corporate_record_item.dart';

/// Renders the corporate vertical dashboard for enterprise records.
class CorporateDashboardPage extends StatefulWidget {
  const CorporateDashboardPage({
    required this.viewModel,
    this.onCreateRequested,
    this.onRecordSelected,
    super.key,
  });

  final CorporateDashboardViewModel viewModel;
  final Future<void> Function(BuildContext context)? onCreateRequested;
  final Future<void> Function(BuildContext context, CorporateRecordItem item)?
  onRecordSelected;

  @override
  State<CorporateDashboardPage> createState() => _CorporateDashboardPageState();
}

class _CorporateDashboardPageState extends State<CorporateDashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final overview = widget.viewModel.overview;
        if (overview == null && widget.viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Sector Corporativo',
              subtitle: 'Contratos, gobierno interno y alertas de control documental.',
            ),
            const SizedBox(height: 16),
            if (widget.viewModel.message != null)
              GdmsStatusBadge(
                label: widget.viewModel.message!,
                tone: widget.viewModel.state == ViewState.error
                    ? GdmsStatusTone.critical
                    : GdmsStatusTone.info,
              ),
            if (widget.onCreateRequested != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => widget.onCreateRequested!(context),
                  icon: const Icon(Icons.business_center_outlined),
                  label: const Text('Crear legajo'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (overview != null) ...[
              _CorporateMetricsRow(overview: overview),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Registros y alertas',
                child: overview.records.isEmpty
                    ? const Text('No hay registros destacados para mostrar.')
                    : Column(
                        children: overview.records
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  title: Text(item.title),
                                  subtitle: Text(item.subtitle),
                                  onTap: widget.onRecordSelected == null ||
                                          item.id.isEmpty
                                      ? null
                                      : () => widget.onRecordSelected!(
                                          context,
                                          item,
                                        ),
                                  trailing: GdmsStatusBadge(
                                    label: item.status,
                                    tone: item.status == 'CRITICAL'
                                        ? GdmsStatusTone.critical
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

class _CorporateMetricsRow extends StatelessWidget {
  const _CorporateMetricsRow({required this.overview});

  final CorporateDashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Contratos activos',
            value: '${overview.activeContracts}',
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Gobierno pendiente',
            value: '${overview.pendingGovernanceTasks}',
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Alertas de control',
            value: '${overview.controlAlerts}',
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}
