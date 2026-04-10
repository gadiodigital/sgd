import 'package:feature_sector_corporate/feature_sector_corporate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza metricas CTA y seleccion de legajo', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardCorporateRepository();
    final viewModel = CorporateDashboardViewModel(repository);
    var createTapped = 0;
    CorporateRecordItem? selectedRecord;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: CorporateDashboardPage(
            viewModel: viewModel,
            onCreateRequested: (_) async => createTapped++,
            onRecordSelected: (_, item) async {
              selectedRecord = item;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Sector Corporativo'), findsOneWidget);
    expect(find.text('Panel corporativo sincronizado.'), findsOneWidget);
    expect(find.text('Contratos activos'), findsOneWidget);
    expect(find.text('Gobierno pendiente'), findsOneWidget);
    expect(find.text('Alertas de control'), findsOneWidget);
    expect(find.text('Contrato societario'), findsOneWidget);
    expect(find.text('Libro de actas'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Crear legajo'));
    await tester.pumpAndSettle();
    expect(createTapped, 1);

    await tester.tap(find.text('Contrato societario'));
    await tester.pumpAndSettle();
    expect(selectedRecord?.id, 'corp-1');
  });
}

final class _DashboardCorporateRepository
    implements CorporateDashboardRepository {
  int loadCalls = 0;

  @override
  Future<CorporateDashboardOverview> loadOverview() async {
    loadCalls++;
    return const CorporateDashboardOverview(
      activeContracts: 5,
      pendingGovernanceTasks: 2,
      controlAlerts: 1,
      records: [
        CorporateRecordItem(
          id: 'corp-1',
          title: 'Contrato societario',
          subtitle: 'Pendiente de aprobación interna',
          status: 'WARNING',
        ),
        CorporateRecordItem(
          id: 'corp-2',
          title: 'Libro de actas',
          subtitle: 'Requiere actualización regulatoria',
          status: 'CRITICAL',
        ),
      ],
    );
  }
}
