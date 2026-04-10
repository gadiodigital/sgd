import 'package:feature_sector_legal/feature_sector_legal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza metricas CTA expedientes y asuntos', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardLegalRepository();
    final viewModel = LegalDashboardViewModel(repository);
    var createTapped = 0;
    LegalCaseFileItem? selectedCase;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: LegalDashboardPage(
            viewModel: viewModel,
            onCreateRequested: (_) async => createTapped++,
            onCaseSelected: (_, caseFile) async {
              selectedCase = caseFile;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Sector Legal'), findsOneWidget);
    expect(find.text('Panel jurídico sincronizado.'), findsOneWidget);
    expect(find.text('Tareas abiertas'), findsOneWidget);
    expect(find.text('Revisiones de evidencia'), findsOneWidget);
    expect(find.text('Incidentes seguridad'), findsOneWidget);
    expect(find.text('Expediente civil'), findsOneWidget);
    expect(find.text('Expediente laboral'), findsOneWidget);
    expect(find.text('Custodia de evidencia'), findsOneWidget);
    expect(find.text('Incidente de acceso'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Crear expediente'));
    await tester.pumpAndSettle();
    expect(createTapped, 1);

    await tester.tap(find.text('Expediente civil'));
    await tester.pumpAndSettle();
    expect(selectedCase?.id, 'case-1');
  });
}

final class _DashboardLegalRepository implements LegalDashboardRepository {
  int loadCalls = 0;

  @override
  Future<LegalDashboardOverview> loadOverview() async {
    loadCalls++;
    return const LegalDashboardOverview(
      openTasks: 3,
      dueEvidenceReviews: 1,
      failedLogins24h: 0,
      caseFiles: [
        LegalCaseFileItem(
          id: 'case-1',
          title: 'Expediente civil',
          subtitle: 'EXP-2026-001 · JURIDICO',
          status: 'OPEN',
        ),
        LegalCaseFileItem(
          id: 'case-2',
          title: 'Expediente laboral',
          subtitle: 'EXP-2026-014 · RRLL',
          status: 'CLOSED',
        ),
      ],
      matters: [
        LegalMatterItem(
          title: 'Custodia de evidencia',
          subtitle: 'Expediente con revisión pendiente',
          status: 'WARNING',
        ),
        LegalMatterItem(
          title: 'Incidente de acceso',
          subtitle: 'Requiere revisión del equipo legal',
          status: 'CRITICAL',
        ),
      ],
    );
  }
}
