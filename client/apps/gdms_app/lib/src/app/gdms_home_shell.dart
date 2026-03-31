import 'package:flutter/material.dart';

import '../auth/application/app_session_view_model.dart';
import 'shell_content.dart';
import 'shell_destination.dart';

/// Hosts the primary navigation shell of the GDMS application.
class GdmsHomeShell extends StatefulWidget {
  const GdmsHomeShell({
    required this.sessionViewModel,
    required this.authPage,
    required this.documentsPage,
    required this.notificationsPage,
    required this.configPage,
    required this.integrationsPage,
    required this.reportsPage,
    required this.searchPage,
    required this.signaturePage,
    required this.legalPage,
    required this.realEstatePage,
    required this.corporatePage,
    required this.auditPage,
    required this.workflowPage,
    required this.recordsPage,
    required this.adminPage,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final Widget authPage;
  final Widget documentsPage;
  final Widget notificationsPage;
  final Widget configPage;
  final Widget integrationsPage;
  final Widget reportsPage;
  final Widget searchPage;
  final Widget signaturePage;
  final Widget legalPage;
  final Widget realEstatePage;
  final Widget corporatePage;
  final Widget auditPage;
  final Widget workflowPage;
  final Widget recordsPage;
  final Widget adminPage;

  @override
  State<GdmsHomeShell> createState() => _GdmsHomeShellState();
}

class _GdmsHomeShellState extends State<GdmsHomeShell> {
  static const _wideLayoutBreakpoint = 980.0;
  var _selectedIndex = 0;

  late List<ShellDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = [
      ShellDestination(
        label: 'Acceso',
        icon: Icons.verified_user_outlined,
        selectedIcon: Icons.verified_user,
        child: widget.authPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Documentos',
        icon: Icons.folder_copy_outlined,
        selectedIcon: Icons.folder_copy,
        child: widget.documentsPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        child: widget.notificationsPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Config',
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune,
        child: widget.configPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Integraciones',
        icon: Icons.hub_outlined,
        selectedIcon: Icons.hub,
        child: widget.integrationsPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Reportes',
        icon: Icons.assessment_outlined,
        selectedIcon: Icons.assessment,
        child: widget.reportsPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Búsqueda',
        icon: Icons.manage_search_outlined,
        selectedIcon: Icons.manage_search,
        child: widget.searchPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Firma',
        icon: Icons.draw_outlined,
        selectedIcon: Icons.draw,
        child: widget.signaturePage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Legal',
        icon: Icons.balance_outlined,
        selectedIcon: Icons.balance,
        child: widget.legalPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Inmobiliario',
        icon: Icons.apartment_outlined,
        selectedIcon: Icons.apartment,
        child: widget.realEstatePage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Corporativo',
        icon: Icons.business_center_outlined,
        selectedIcon: Icons.business_center,
        child: widget.corporatePage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Auditoría',
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
        child: widget.auditPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Workflow',
        icon: Icons.alt_route_outlined,
        selectedIcon: Icons.alt_route,
        child: widget.workflowPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Records',
        icon: Icons.gavel_outlined,
        selectedIcon: Icons.gavel,
        child: widget.recordsPage,
        sessionViewModel: widget.sessionViewModel,
      ),
      ShellDestination(
        label: 'Admin',
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings,
        child: widget.adminPage,
        sessionViewModel: widget.sessionViewModel,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.sessionViewModel.identity;
    final tenantCode = widget.sessionViewModel.session?.tenantCode ?? 'GDMS';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;

        return Scaffold(
          appBar: AppBar(
            title: const Text('GDMS Argentina'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    identity == null
                        ? 'Sin identidad'
                        : '${identity.fullName} · $tenantCode',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesion',
                onPressed: widget.sessionViewModel.signOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SafeArea(
            child: isWide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onDestinationSelected,
                        labelType: NavigationRailLabelType.all,
                        destinations: _destinations
                            .map(
                              (destination) => NavigationRailDestination(
                                icon: Icon(destination.icon),
                                selectedIcon: Icon(destination.selectedIcon),
                                label: Text(destination.label),
                              ),
                            )
                            .toList(),
                      ),
                      Expanded(child: ShellContent(destination: _current)),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: ShellContent(destination: _current)),
                    ],
                  ),
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: _destinations
                      .map(
                        (destination) => NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  ShellDestination get _current => _destinations[_selectedIndex];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }
}
