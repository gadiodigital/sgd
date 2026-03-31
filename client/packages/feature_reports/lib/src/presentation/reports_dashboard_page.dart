import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/reports_view_model.dart';

/// Renders the operational summary of the current tenant.
class ReportsDashboardPage extends StatefulWidget {
  const ReportsDashboardPage({
    required this.viewModel,
    this.onMetricSelected,
    this.onPlatformMetricSelected,
    super.key,
  });

  final ReportsViewModel viewModel;
  final Future<void> Function(BuildContext context, ReportMetricItem metric)?
      onMetricSelected;
  final Future<void> Function(
    BuildContext context,
    PlatformReportMetricItem metric,
  )?
  onPlatformMetricSelected;

  @override
  State<ReportsDashboardPage> createState() => _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends State<ReportsDashboardPage> {
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
              title: 'Reportes',
              subtitle: 'Resumen operativo consolidado del tenant actual.',
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
              _ReportsLensSection(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              _ReportsMetricsGrid(
                viewModel: widget.viewModel,
                onMetricSelected: widget.onMetricSelected,
              ),
              if (widget.viewModel.visiblePlatformMetrics.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PlatformReportsSection(
                  viewModel: widget.viewModel,
                  onMetricSelected: widget.onPlatformMetricSelected,
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _ReportsLensSection extends StatelessWidget {
  const _ReportsLensSection({required this.viewModel});

  final ReportsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Lentes operativas',
      subtitle: 'Enfoca los KPIs por cumplimiento, workflow, firma o seguridad.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip(context, ReportsLens.all, 'Todos'),
          _buildChip(context, ReportsLens.compliance, 'Cumplimiento'),
          _buildChip(context, ReportsLens.workflow, 'Workflow'),
          _buildChip(context, ReportsLens.signatures, 'Firmas'),
          _buildChip(context, ReportsLens.security, 'Seguridad'),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, ReportsLens lens, String label) {
    return FilterChip(
      label: Text(label),
      selected: viewModel.selectedLens == lens,
      onSelected: (_) => viewModel.updateLens(lens),
    );
  }
}

class _PlatformReportsSection extends StatelessWidget {
  const _PlatformReportsSection({
    required this.viewModel,
    this.onMetricSelected,
  });

  final ReportsViewModel viewModel;
  final Future<void> Function(
    BuildContext context,
    PlatformReportMetricItem metric,
  )?
  onMetricSelected;

  @override
  Widget build(BuildContext context) {
    final metrics = viewModel.visiblePlatformMetrics;
    return GdmsSectionCard(
      title: 'Vista de plataforma',
      subtitle: 'Visible solo para perfiles PLATFORM_ADMIN.',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: metrics
            .map(
              (metric) => _buildTile(
                context,
                metric,
                metric.label,
                metric.value,
                Color(metric.colorHex),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    PlatformReportMetricItem metric,
    String label,
    int value,
    Color color,
  ) {
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onMetricSelected == null
            ? null
            : () => onMetricSelected!(context, metric),
        child: GdmsMetricTile(label: label, value: '$value', color: color),
      ),
    );
  }
}

class _ReportsMetricsGrid extends StatelessWidget {
  const _ReportsMetricsGrid({
    required this.viewModel,
    this.onMetricSelected,
  });

  final ReportsViewModel viewModel;
  final Future<void> Function(BuildContext context, ReportMetricItem metric)?
      onMetricSelected;

  @override
  Widget build(BuildContext context) {
    final metrics = viewModel.visibleOperationalMetrics;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map(
            (metric) => _buildTile(
              context,
              metric,
              metric.label,
              metric.value,
              Color(metric.colorHex),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTile(
    BuildContext context,
    ReportMetricItem metric,
    String label,
    int value,
    Color color,
  ) {
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onMetricSelected == null
            ? null
            : () => onMetricSelected!(context, metric),
        child: GdmsMetricTile(label: label, value: '$value', color: color),
      ),
    );
  }
}
