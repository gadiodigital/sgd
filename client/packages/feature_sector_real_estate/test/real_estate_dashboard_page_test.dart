import 'package:feature_sector_real_estate/feature_sector_real_estate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza metricas CTA y seleccion de legajo', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardRealEstateRepository();
    final viewModel = RealEstateDashboardViewModel(repository);
    var createTapped = 0;
    RealEstateFileItem? selectedFile;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: RealEstateDashboardPage(
            viewModel: viewModel,
            onCreateRequested: (_) async => createTapped++,
            onFileSelected: (_, item) async {
              selectedFile = item;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Sector Inmobiliario'), findsOneWidget);
    expect(find.text('Panel inmobiliario sincronizado.'), findsOneWidget);
    expect(find.text('Legajos activos'), findsOneWidget);
    expect(find.text('Aprobaciones'), findsOneWidget);
    expect(find.text('Alertas compliance'), findsOneWidget);
    expect(find.text('Legajo de inmueble'), findsOneWidget);
    expect(find.text('Expediente de alquiler'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Crear legajo'));
    await tester.pumpAndSettle();
    expect(createTapped, 1);

    await tester.tap(find.text('Legajo de inmueble'));
    await tester.pumpAndSettle();
    expect(selectedFile?.id, 're-1');
  });
}

final class _DashboardRealEstateRepository
    implements RealEstateDashboardRepository {
  int loadCalls = 0;

  @override
  Future<RealEstateDashboardOverview> loadOverview() async {
    loadCalls++;
    return const RealEstateDashboardOverview(
      activeFiles: 4,
      pendingApprovals: 2,
      complianceAlerts: 1,
      files: [
        RealEstateFileItem(
          id: 're-1',
          title: 'Legajo de inmueble',
          subtitle: 'Contrato pendiente de aprobación',
          status: 'WARNING',
        ),
        RealEstateFileItem(
          id: 're-2',
          title: 'Expediente de alquiler',
          subtitle: 'Incumplimiento documental detectado',
          status: 'CRITICAL',
        ),
      ],
    );
  }
}
