import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/real_estate_dashboard_view_model.dart';
import '../domain/real_estate_dashboard_overview.dart';
import '../domain/real_estate_file_item.dart';

/// Renders the real-estate vertical dashboard for property operators.
class RealEstateDashboardPage extends StatefulWidget {
  const RealEstateDashboardPage({
    required this.viewModel,
    this.onCreateRequested,
    this.onFileSelected,
    super.key,
  });

  final RealEstateDashboardViewModel viewModel;
  final Future<void> Function(BuildContext context)? onCreateRequested;
  final Future<void> Function(BuildContext context, RealEstateFileItem item)?
  onFileSelected;

  @override
  State<RealEstateDashboardPage> createState() =>
      _RealEstateDashboardPageState();
}

class _RealEstateDashboardPageState extends State<RealEstateDashboardPage> {
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
              title: 'Sector Inmobiliario',
              subtitle: 'Legajos, contratos y alertas operativas para inmobiliarias.',
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
                  icon: const Icon(Icons.apartment_outlined),
                  label: const Text('Crear legajo'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (overview != null) ...[
              _RealEstateMetricsRow(overview: overview),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Legajos y alertas',
                child: overview.files.isEmpty
                    ? const Text('No hay legajos destacados para mostrar.')
                    : Column(
                        children: overview.files
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
                                  onTap: widget.onFileSelected == null ||
                                          item.id.isEmpty
                                      ? null
                                      : () => widget.onFileSelected!(
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

class _RealEstateMetricsRow extends StatelessWidget {
  const _RealEstateMetricsRow({required this.overview});

  final RealEstateDashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Legajos activos',
            value: '${overview.activeFiles}',
            color: const Color(0xFF00695C),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Aprobaciones',
            value: '${overview.pendingApprovals}',
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Alertas compliance',
            value: '${overview.complianceAlerts}',
            color: const Color(0xFFEF6C00),
          ),
        ),
      ],
    );
  }
}
