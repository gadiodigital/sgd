import 'package:feature_integrations/feature_integrations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads integrations overview data', () async {
    final viewModel = IntegrationsViewModel(_FakeIntegrationsRepository());

    await viewModel.load();

    expect(viewModel.overview?.readyCount, 2);
    expect(viewModel.overview?.items.length, 2);

    viewModel.updateCategoryFilter('DATABASE');
    expect(viewModel.visibleItems.length, 1);
    expect(viewModel.visibleReadyCount, 1);

    viewModel.updateStatusFilter('READY');
    expect(viewModel.visibleItems.length, 1);

    viewModel.updateQuery('signature');
    expect(viewModel.visibleItems, isEmpty);
  });
}

final class _FakeIntegrationsRepository implements IntegrationsRepository {
  @override
  Future<IntegrationsOverview> loadOverview() async {
    return const IntegrationsOverview(
      readyCount: 2,
      warningCount: 0,
      items: [
        IntegrationStatusItem(
          code: 'POSTGRES',
          displayName: 'PostgreSQL',
          category: 'DATABASE',
          status: 'READY',
          detail: 'Fuente de verdad configurada.',
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
