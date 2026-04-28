import 'package:feature_auth/feature_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza sesion badges y datos operativos', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardSessionOverviewRepository();
    final viewModel = AuthOverviewViewModel(repository);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(body: AuthDashboardPage(viewModel: viewModel)),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Identidad y acceso'), findsOneWidget);
    expect(find.text('Sesion preparada para operar.'), findsOneWidget);
    expect(find.text('TENANT_ADMIN'), findsOneWidget);
    expect(find.text('MFA activo'), findsOneWidget);
    expect(find.text('Organización TENANT-01'), findsOneWidget);
    expect(find.text('Usuario Demo'), findsOneWidget);
    expect(find.text('demo@example.com'), findsOneWidget);
    expect(find.text('Organizacion activa'), findsOneWidget);
    expect(find.text('Organización Demo'), findsOneWidget);
    expect(find.text('Ultimo acceso'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Rotacion de credencial'), findsOneWidget);
    expect(find.text('30 dias'), findsOneWidget);
  });
}

final class _DashboardSessionOverviewRepository
    implements SessionOverviewRepository {
  int loadCalls = 0;

  @override
  Future<SessionOverview> loadCurrentSession() async {
    loadCalls++;
    return const SessionOverview(
      userName: 'Usuario Demo',
      email: 'demo@example.com',
      tenantName: 'Organización Demo',
      tenantCode: 'TENANT-01',
      primaryRole: 'TENANT_ADMIN',
      lastLoginLabel: 'Hoy',
      passwordRotationDays: 30,
      mfaEnabled: true,
    );
  }
}
