import 'package:flutter_test/flutter_test.dart';

import 'package:feature_integrations/feature_integrations.dart';

void main() {
  test('load sincroniza overview y filtra por categoria estado y query', () async {
    final repository = _RecordingIntegrationsRepository();
    final viewModel = IntegrationsViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.message, 'Integraciones sincronizadas.');
    expect(viewModel.overview?.items.length, 3);
    expect(viewModel.visibleReadyCount, 2);
    expect(viewModel.visibleWarningCount, 1);
    expect(viewModel.availableCategories, ['DATABASE', 'FIREBASE', 'SIGNATURE']);
    expect(viewModel.availableStatuses, ['EMULATOR', 'INTERNAL', 'READY']);

    viewModel.updateCategoryFilter('DATABASE');
    expect(viewModel.visibleItems.map((item) => item.code).toList(), ['POSTGRES']);

    viewModel.updateCategoryFilter('');
    viewModel.updateStatusFilter('READY');
    expect(
      viewModel.visibleItems.map((item) => item.code).toList(),
      ['POSTGRES'],
    );

    viewModel.updateStatusFilter('');
    viewModel.updateQuery('firestore');
    expect(
      viewModel.visibleItems.map((item) => item.code).toList(),
      ['FIRESTORE'],
    );

    viewModel.clearFilters();
    expect(viewModel.query, isEmpty);
    expect(viewModel.categoryFilter, isEmpty);
    expect(viewModel.statusFilter, isEmpty);
  });
}

final class _RecordingIntegrationsRepository implements IntegrationsRepository {
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
