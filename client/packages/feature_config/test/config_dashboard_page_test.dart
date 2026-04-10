import 'package:feature_config/feature_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza config y permite guardar preferencias', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardConfigRepository();
    final viewModel = ConfigViewModel(repository);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: ConfigDashboardPage(viewModel: viewModel),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Config'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Config activa'), findsOneWidget);
    expect(find.text('Activo'), findsNWidgets(2));
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Mostrar tips de cumplimiento'), findsOneWidget);

    await tester.tap(find.text('Búsqueda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workflow').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar preferencias'));
    await tester.pumpAndSettle();

    expect(
      repository.savedRequests,
      [
        const _SaveRequest(
          preferredLandingModule: 'workflow',
          showComplianceTips: false,
        ),
      ],
    );
    expect(find.text('Preferencias guardadas correctamente.'), findsOneWidget);
  });
}

final class _DashboardConfigRepository implements ConfigRepository {
  int loadCalls = 0;
  final List<_SaveRequest> savedRequests = <_SaveRequest>[];
  String _preferredLandingModule = 'search';
  bool _showComplianceTips = true;

  @override
  Future<ConfigOverview> loadOverview() async {
    loadCalls++;
    return ConfigOverview(
      remoteConfigAvailable: true,
      firestoreAvailable: true,
      bannerMessage: 'Config activa',
      workflowEnabled: true,
      searchResultLimit: 20,
      preferredLandingModule: _preferredLandingModule,
      showComplianceTips: _showComplianceTips,
      statusMessage: 'OK',
    );
  }

  @override
  Future<void> savePreferences({
    required String preferredLandingModule,
    required bool showComplianceTips,
  }) async {
    savedRequests.add(
      _SaveRequest(
        preferredLandingModule: preferredLandingModule,
        showComplianceTips: showComplianceTips,
      ),
    );
    _preferredLandingModule = preferredLandingModule;
    _showComplianceTips = showComplianceTips;
  }
}

final class _SaveRequest {
  const _SaveRequest({
    required this.preferredLandingModule,
    required this.showComplianceTips,
  });

  final String preferredLandingModule;
  final bool showComplianceTips;

  @override
  bool operator ==(Object other) {
    return other is _SaveRequest &&
        other.preferredLandingModule == preferredLandingModule &&
        other.showComplianceTips == showComplianceTips;
  }

  @override
  int get hashCode => Object.hash(preferredLandingModule, showComplianceTips);
}
