import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/legal_dashboard_view_model.dart';
import '../domain/legal_case_file_item.dart';
import '../domain/legal_dashboard_overview.dart';

/// Renders the legal vertical dashboard for law firms and legal teams.
class LegalDashboardPage extends StatefulWidget {
  const LegalDashboardPage({
    required this.viewModel,
    this.onCreateRequested,
    this.onCaseSelected,
    super.key,
  });

  final LegalDashboardViewModel viewModel;
  final Future<void> Function(BuildContext context)? onCreateRequested;
  final Future<void> Function(BuildContext context, LegalCaseFileItem caseFile)?
  onCaseSelected;

  @override
  State<LegalDashboardPage> createState() => _LegalDashboardPageState();
}

class _LegalDashboardPageState extends State<LegalDashboardPage> {
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
              title: 'Sector Legal',
              subtitle:
                  'Expedientes, evidencia, custodias y alertas de trabajo jurídico.',
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
                  icon: const Icon(Icons.library_add_outlined),
                  label: const Text('Crear expediente'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (overview != null) ...[
              _LegalMetricsRow(overview: overview),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Expedientes recientes',
                child: overview.caseFiles.isEmpty
                    ? const Text('No hay expedientes creados todavía.')
                    : Column(
                        children: overview.caseFiles
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
                                  onTap: widget.onCaseSelected == null
                                      ? null
                                      : () => widget.onCaseSelected!(
                                          context,
                                          item,
                                        ),
                                  trailing: GdmsStatusBadge(
                                    label: item.status,
                                    tone: item.status == 'CLOSED'
                                        ? GdmsStatusTone.neutral
                                        : GdmsStatusTone.info,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Asuntos y alertas',
                child: overview.matters.isEmpty
                    ? const Text('No hay asuntos destacados para mostrar.')
                    : Column(
                        children: overview.matters
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

class _LegalMetricsRow extends StatelessWidget {
  const _LegalMetricsRow({required this.overview});

  final LegalDashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Tareas abiertas',
            value: '${overview.openTasks}',
            color: const Color(0xFF283593),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Revisiones de evidencia',
            value: '${overview.dueEvidenceReviews}',
            color: const Color(0xFF8E24AA),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Incidentes seguridad',
            value: '${overview.failedLogins24h}',
            color: const Color(0xFFC62828),
          ),
        ),
      ],
    );
  }
}
