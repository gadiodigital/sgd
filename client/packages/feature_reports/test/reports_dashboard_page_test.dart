import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filtra metricas y dispara callbacks operativos', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardReportsRepository();
    final viewModel = ReportsViewModel(repository);
    ReportMetricItem? selectedMetric;
    PlatformReportMetricItem? selectedPlatformMetric;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: ReportsDashboardPage(
            viewModel: viewModel,
            onMetricSelected: (_, metric) async {
              selectedMetric = metric;
            },
            onPlatformMetricSelected: (_, metric) async {
              selectedPlatformMetric = metric;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reportes'), findsOneWidget);
    expect(repository.loadCalls, 1);
    expect(find.text('Reporte operativo sincronizado.'), findsOneWidget);
    expect(find.text('Documentos'), findsNWidgets(2));
    expect(find.text('Organizaciones'), findsOneWidget);

    await tester.tap(find.text('Cumplimiento'));
    await tester.pumpAndSettle();

    expect(find.text('Legal holds'), findsOneWidget);
    expect(find.text('Disposición pendiente'), findsOneWidget);
    expect(find.text('Workflow abierto'), findsOneWidget);

    await tester.tap(find.text('Legal holds').first);
    await tester.pumpAndSettle();
    expect(selectedMetric?.label, 'Legal holds');

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Organizaciones'));
    await tester.pumpAndSettle();
    expect(selectedPlatformMetric?.label, 'Organizaciones');
  });
}

final class _DashboardReportsRepository implements ReportsRepository {
  int loadCalls = 0;

  @override
  Future<OperationalReportOverview> loadOverview() async {
    loadCalls++;
    return const OperationalReportOverview(
      totalDocuments: 12,
      activeLegalHolds: 1,
      openWorkflowTasks: 4,
      pendingSignatures: 2,
      cancelledSignatures: 1,
      pendingDispositionItems: 3,
      failedLoginsLast24Hours: 1,
      platformSummary: PlatformReportOverview(
        totalTenants: 2,
        totalDocuments: 120,
        openWorkflowTasks: 11,
        pendingSignatures: 5,
        cancelledSignatures: 2,
        failedLoginsLast24Hours: 3,
      ),
    );
  }
}
