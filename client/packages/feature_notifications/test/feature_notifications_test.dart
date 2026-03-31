import 'package:flutter_test/flutter_test.dart';

import 'package:feature_notifications/feature_notifications.dart';

void main() {
  test('loads notifications overview data', () async {
    final viewModel = NotificationsViewModel(_FakeNotificationsRepository());

    await viewModel.load();

    expect(viewModel.overview?.totalItems, 3);
    expect(viewModel.overview?.criticalItems, 1);
    expect(viewModel.filteredItems.length, 3);

    viewModel.updateCategoryFilter('WORKFLOW');
    expect(viewModel.filteredItems.length, 1);

    viewModel.clearFilters();
    viewModel.updateQuery('firma');
    expect(viewModel.filteredItems.length, 1);
  });
}

final class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<NotificationsOverview> loadOverview() async {
    return const NotificationsOverview(
      totalItems: 3,
      criticalItems: 1,
      warningItems: 2,
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
      ],
    );
  }
}
