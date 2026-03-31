import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/config_view_model.dart';
import '../domain/config_overview.dart';

/// Renders Firebase-backed dynamic config and user preference controls.
class ConfigDashboardPage extends StatefulWidget {
  const ConfigDashboardPage({
    required this.viewModel,
    super.key,
  });

  final ConfigViewModel viewModel;

  @override
  State<ConfigDashboardPage> createState() => _ConfigDashboardPageState();
}

class _ConfigDashboardPageState extends State<ConfigDashboardPage> {
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
              title: 'Config',
              subtitle: 'Remote Config no sensible y preferencias Firestore.',
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
              _ConfigMetricsRow(overview: overview),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Remote Config',
                child: Text(overview.bannerMessage),
              ),
              const SizedBox(height: 16),
              GdmsSectionCard(
                title: 'Preferencias',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(widget.viewModel.preferredLandingModule),
                      initialValue: widget.viewModel.preferredLandingModule,
                      decoration: const InputDecoration(
                        labelText: 'Módulo de aterrizaje preferido',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'documents', child: Text('Documentos')),
                        DropdownMenuItem(value: 'search', child: Text('Búsqueda')),
                        DropdownMenuItem(value: 'workflow', child: Text('Workflow')),
                        DropdownMenuItem(value: 'records', child: Text('Records')),
                        DropdownMenuItem(value: 'audit', child: Text('Auditoría')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          widget.viewModel.updatePreferredLandingModule(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: widget.viewModel.showComplianceTips,
                      onChanged: widget.viewModel.updateShowComplianceTips,
                      title: const Text('Mostrar tips de cumplimiento'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: widget.viewModel.isBusy
                            ? null
                            : widget.viewModel.savePreferences,
                        child: const Text('Guardar preferencias'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ConfigMetricsRow extends StatelessWidget {
  const _ConfigMetricsRow({required this.overview});

  final ConfigOverview overview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Remote Config',
            value: overview.remoteConfigAvailable ? 'Activo' : 'Fallback',
            color: const Color(0xFF1E88E5),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Firestore',
            value: overview.firestoreAvailable ? 'Activo' : 'Fallback',
            color: const Color(0xFF00897B),
          ),
        ),
        SizedBox(
          width: 220,
          child: GdmsMetricTile(
            label: 'Search limit',
            value: '${overview.searchResultLimit}',
            color: const Color(0xFF6D4C41),
          ),
        ),
      ],
    );
  }
}
