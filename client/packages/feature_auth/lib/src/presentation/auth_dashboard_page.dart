import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/auth_overview_view_model.dart';
import '../infrastructure/demo_session_overview_repository.dart';

/// Shows the current authentication, tenant and session controls overview.
class AuthDashboardPage extends StatefulWidget {
  const AuthDashboardPage({super.key, AuthOverviewViewModel? viewModel})
    : _viewModel = viewModel;

  final AuthOverviewViewModel? _viewModel;

  @override
  State<AuthDashboardPage> createState() => _AuthDashboardPageState();
}

class _AuthDashboardPageState extends State<AuthDashboardPage> {
  late final AuthOverviewViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget._viewModel ??
        AuthOverviewViewModel(DemoSessionOverviewRepository());
    _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final session = _viewModel.session;

        if (session == null && _viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (session == null) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Identidad y acceso',
              subtitle:
                  'Controla el contexto de sesion, MFA y privilegios activos '
                  'para operar con trazabilidad sobre el tenant.',
            ),
            const SizedBox(height: 24),
            GdmsSectionCard(
              title: 'Sesion operativa',
              subtitle: _viewModel.message,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  GdmsStatusBadge(
                    label: session.primaryRole,
                    tone: GdmsStatusTone.info,
                  ),
                  GdmsStatusBadge(
                    label: session.mfaEnabled ? 'MFA activo' : 'MFA pendiente',
                    tone: session.mfaEnabled
                        ? GdmsStatusTone.success
                        : GdmsStatusTone.warning,
                  ),
                  GdmsStatusBadge(
                    label: 'Tenant ${session.tenantCode}',
                    tone: GdmsStatusTone.neutral,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: session.userName,
              subtitle: session.email,
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Organizacion activa',
                    value: session.tenantName,
                  ),
                  _InfoRow(
                    label: 'Ultimo acceso',
                    value: session.lastLoginLabel,
                  ),
                  _InfoRow(
                    label: 'Rotacion de credencial',
                    value: '${session.passwordRotationDays} dias',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
