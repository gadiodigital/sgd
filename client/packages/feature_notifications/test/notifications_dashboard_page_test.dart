import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra por severidad y categoria busca limpia y dispara acciones contextuales',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DashboardNotificationsRepository();
      final viewModel = NotificationsViewModel(repository);
      NotificationItem? actedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: NotificationsDashboardPage(
              viewModel: viewModel,
              onItemActionRequested: (_, item) async {
                actedItem = item;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(repository.loadCalls, 1);
      expect(find.byType(ListTile), findsNWidgets(4));
      expect(find.text('4 visibles de 4'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Crítica'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('1 visibles de 4'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Todas las categorías'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'WORKFLOW'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Todas'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(4));

      await tester.enterText(find.byType(TextField), 'firma');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Abrir firma'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Abrir firma'));
      await tester.pumpAndSettle();
      expect(actedItem?.category, 'SIGNATURE');
      expect(actedItem?.title, 'Firma pendiente');
    },
  );
}

final class _DashboardNotificationsRepository implements NotificationsRepository {
  int loadCalls = 0;

  @override
  Future<NotificationsOverview> loadOverview() async {
    loadCalls++;
    return const NotificationsOverview(
      totalItems: 4,
      criticalItems: 1,
      warningItems: 3,
      items: [
        NotificationItem(
          category: 'RECORDS',
          title: 'Disposición pendiente',
          detail: 'Existe legal hold activo',
          severity: 'CRITICAL',
          occurredAtLabel: 'Hoy',
        ),
        NotificationItem(
          category: 'WORKFLOW',
          title: 'Aprobación pendiente',
          detail: 'Contrato a revisar hoy',
          severity: 'WARNING',
          occurredAtLabel: 'Hoy',
        ),
        NotificationItem(
          category: 'SIGNATURE',
          title: 'Firma pendiente',
          detail: 'Solicitud digital con vencimiento cercano',
          severity: 'WARNING',
          occurredAtLabel: 'Hoy',
        ),
        NotificationItem(
          category: 'SECURITY',
          title: 'Inicio sospechoso',
          detail: 'Se detectó un acceso nuevo',
          severity: 'ERROR',
          occurredAtLabel: 'Hace 5 min',
        ),
      ],
    );
  }
}
