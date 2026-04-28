import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';

/// Displays the shared operating context at the top of the app shell.
class ShellBanner extends StatelessWidget {
  const ShellBanner({required this.sessionViewModel, super.key});

  final AppSessionViewModel sessionViewModel;

  @override
  Widget build(BuildContext context) {
    final session = sessionViewModel.session;
    final tenantLabel = session == null
        ? 'Sin organización activa'
        : '${session.tenantName} (${session.tenantCode})';

    return GdmsSectionCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _BannerCopy(
            tenantLabel: tenantLabel,
            apiBaseUrl: sessionViewModel.apiBaseUrl,
          ),
          const GdmsStatusBadge(
            label: 'PostgreSQL + Firebase + .NET 10',
            tone: GdmsStatusTone.info,
          ),
          const GdmsStatusBadge(
            label: 'WCAG 2.2 AA',
            tone: GdmsStatusTone.success,
          ),
        ],
      ),
    );
  }
}

class _BannerCopy extends StatelessWidget {
  const _BannerCopy({required this.tenantLabel, required this.apiBaseUrl});

  final String tenantLabel;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nucleo ECM seguro para Argentina',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Organización activa: $tenantLabel\n'
            'API: $apiBaseUrl\n'
            'La interfaz ya consume o prepara consumo real del backend para '
            'identidad, documentos, records y gobierno.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
