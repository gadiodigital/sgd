import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load sincroniza overview y filtros por severidad categoria y query', () async {
    final repository = _RecordingNotificationsRepository();
    final viewModel = NotificationsViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.totalItems, 4);
    expect(viewModel.filteredItems.length, 4);
    expect(viewModel.availableCategories, ['RECORDS', 'SECURITY', 'SIGNATURE', 'WORKFLOW']);
    expect(viewModel.filteredCriticalItems, 1);
    expect(viewModel.filteredWarningItems, 3);
    expect(viewModel.message, 'Inbox operativo sincronizado.');

    viewModel.updateSeverityFilter('CRITICAL');
    expect(viewModel.filteredItems.map((item) => item.category), ['RECORDS']);

    viewModel.updateSeverityFilter('ALL');
    viewModel.updateCategoryFilter('WORKFLOW');
    expect(viewModel.filteredItems.map((item) => item.title), ['Aprobación pendiente']);

    viewModel.updateCategoryFilter('ALL');
    viewModel.updateQuery('firma');
    expect(viewModel.filteredItems.map((item) => item.category), ['SIGNATURE']);

    viewModel.clearFilters();
    expect(viewModel.query, '');
    expect(viewModel.severityFilter, 'ALL');
    expect(viewModel.categoryFilter, 'ALL');
    expect(viewModel.filteredItems.length, 4);
  });
}

final class _RecordingNotificationsRepository implements NotificationsRepository {
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
