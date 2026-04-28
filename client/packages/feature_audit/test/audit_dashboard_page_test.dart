import 'package:feature_audit/feature_audit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra por severidad organizacion y query y limpia el dashboard',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DashboardAuditRepository();
      final viewModel = AuditOverviewViewModel(repository);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(body: AuditDashboardPage(viewModel: viewModel)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Auditoría'), findsOneWidget);
      expect(repository.loadCalls, 1);
      expect(find.byType(ListTile), findsNWidgets(4));
      expect(find.text('4 visibles de 4'), findsOneWidget);
      expect(find.text('Auditoría sincronizada.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Crítico'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('1 visibles de 4'), findsOneWidget);
      expect(find.text('ACCESS_POLICY_CHANGED'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilterChip, 'Todas las organizaciones'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'TENANT-1'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Todas'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(4));

      await tester.enterText(find.byType(TextField), 'sync');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('SYNC_ERROR'), findsOneWidget);
      expect(find.text('TENANT-3 · Hace 10 min'), findsOneWidget);
    },
  );
}

final class _DashboardAuditRepository implements AuditRepository {
  int loadCalls = 0;

  @override
  Future<AuditOverview> loadOverview() async {
    loadCalls++;
    return const AuditOverview(
      totalEvents: 4,
      criticalEvents: 1,
      warningEvents: 2,
      recentEvents: [
        AuditEventItem(
          tenantCode: 'TENANT-1',
          eventType: 'LOGIN_FAILED',
          severity: 'WARNING',
          occurredAtLabel: 'Hoy',
        ),
        AuditEventItem(
          tenantCode: 'TENANT-1',
          eventType: 'DOCUMENT_CREATED',
          severity: 'INFO',
          occurredAtLabel: 'Hoy',
        ),
        AuditEventItem(
          tenantCode: 'TENANT-2',
          eventType: 'ACCESS_POLICY_CHANGED',
          severity: 'CRITICAL',
          occurredAtLabel: 'Hace 5 min',
        ),
        AuditEventItem(
          tenantCode: 'TENANT-3',
          eventType: 'SYNC_ERROR',
          severity: 'ERROR',
          occurredAtLabel: 'Hace 10 min',
        ),
      ],
    );
  }
}
