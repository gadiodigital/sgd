import 'package:feature_admin/feature_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renderiza acciones y dispara callbacks de metricas backlog organizaciones y eventos',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DashboardAdminRepository();
      final viewModel = AdminOverviewViewModel(repository);
      AdminMetricItem? selectedMetric;
      AdminOverview? selectedMetricOverview;
      GovernanceTask? selectedTask;
      AdminTenantSummary? selectedTenant;
      AdminAuditEvent? selectedEvent;
      var manageUsersTapped = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: AdminDashboardPage(
              viewModel: viewModel,
              onManageUsersRequested: (_) async => manageUsersTapped++,
              onMetricSelected: (_, metric, overview) async {
                selectedMetric = metric;
                selectedMetricOverview = overview;
              },
              onTaskSelected: (_, task) async {
                selectedTask = task;
              },
              onTenantSelected: (_, tenant) async {
                selectedTenant = tenant;
              },
              onEventSelected: (_, event) async {
                selectedEvent = event;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Administracion y gobierno'), findsOneWidget);
      expect(repository.loadCalls, 1);
      expect(find.text('Gobierno de plataforma sincronizado.'), findsOneWidget);

      await tester.tap(find.text('Usuarios'));
      await tester.pumpAndSettle();

      expect(manageUsersTapped, 1);
      expect(find.text('Configurar organización'), findsNothing);

      await tester.tap(find.text('Organización activa'));
      await tester.pumpAndSettle();
      expect(selectedMetric?.kind, AdminMetricKind.activeTenants);
      expect(selectedMetricOverview?.activeTenants, 2);

      await tester.tap(find.text('Task'));
      await tester.pumpAndSettle();
      expect(selectedTask?.title, 'Task');

      await tester.tap(find.text('Organización 1'));
      await tester.pumpAndSettle();
      expect(selectedTenant?.id, 'tenant-1');

      await tester.tap(find.text('LOGIN SUCCEEDED'));
      await tester.pumpAndSettle();
      expect(selectedEvent?.eventType, 'LOGIN_SUCCEEDED');
    },
  );
}

final class _DashboardAdminRepository implements AdminRepository {
  int loadCalls = 0;

  @override
  Future<AdminOverview> loadOverview() async {
    loadCalls++;
    return const AdminOverview(
      activeTenants: 2,
      pendingProvisioning: 1,
      failedLogins24h: 3,
      storageAlerts: 1,
      tenants: [
        AdminTenantSummary(
          id: 'tenant-1',
          code: 'TENANT-1',
          name: 'Organización 1',
          sector: 'EMPRESA',
          createdAtLabel: 'Hoy',
        ),
      ],
      recentEvents: [
        AdminAuditEvent(
          tenantCode: 'TENANT-1',
          eventType: 'LOGIN_SUCCEEDED',
          severity: 'INFO',
          occurredAtLabel: 'Hoy',
        ),
      ],
      tasks: [
        GovernanceTask(
          title: 'Task',
          ownerLabel: 'Owner',
          priorityLabel: 'Alta',
        ),
      ],
    );
  }
}
