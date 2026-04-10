import 'package:feature_integrations/feature_integrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filtra limpia y dispara callback sobre integraciones visibles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardIntegrationsRepository();
    final viewModel = IntegrationsViewModel(repository);
    IntegrationStatusItem? selectedItem;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: IntegrationsDashboardPage(
            viewModel: viewModel,
            onItemSelected: (_, item) async {
              selectedItem = item;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Integraciones'), findsOneWidget);
    expect(find.text('Integraciones sincronizadas.'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.text('PostgreSQL'), findsOneWidget);
    expect(find.text('Firestore'), findsOneWidget);
    expect(find.text('Signature Provider'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar'), 'fire');
    await tester.pumpAndSettle();
    expect(find.text('Firestore'), findsOneWidget);
    expect(find.text('PostgreSQL'), findsNothing);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FIREBASE').last);
    await tester.pumpAndSettle();
    expect(find.text('Firestore'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EMULATOR').last);
    await tester.pumpAndSettle();
    expect(find.text('Firestore'), findsOneWidget);

    await tester.tap(find.text('Firestore'));
    await tester.pumpAndSettle();
    expect(selectedItem?.code, 'FIRESTORE');

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('PostgreSQL'), findsOneWidget);
    expect(find.text('Signature Provider'), findsOneWidget);
  });
}

final class _DashboardIntegrationsRepository implements IntegrationsRepository {
  int loadCalls = 0;

  @override
  Future<IntegrationsOverview> loadOverview() async {
    loadCalls++;
    return const IntegrationsOverview(
      readyCount: 2,
      warningCount: 1,
      items: [
        IntegrationStatusItem(
          code: 'POSTGRES',
          displayName: 'PostgreSQL',
          category: 'DATABASE',
          status: 'READY',
          detail: 'Fuente de verdad configurada.',
        ),
        IntegrationStatusItem(
          code: 'FIRESTORE',
          displayName: 'Firestore',
          category: 'FIREBASE',
          status: 'EMULATOR',
          detail: 'Ejecutando en emulador local.',
        ),
        IntegrationStatusItem(
          code: 'SIGNATURE_PROVIDER',
          displayName: 'Signature Provider',
          category: 'SIGNATURE',
          status: 'INTERNAL',
          detail: 'Proveedor interno listo para pruebas.',
        ),
      ],
    );
  }
}
