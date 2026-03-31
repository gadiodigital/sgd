import 'package:flutter_test/flutter_test.dart';

import 'package:feature_audit/feature_audit.dart';

void main() {
  test('loads audit overview data', () async {
    final viewModel = AuditOverviewViewModel(_FakeAuditRepository());

    await viewModel.load();

    expect(viewModel.overview?.totalEvents, 3);
    expect(viewModel.overview?.criticalEvents, 1);
    expect(viewModel.overview?.recentEvents.length, 3);
    expect(viewModel.filteredEvents.length, 3);

    viewModel.updateSeverityFilter('WARNING');
    expect(viewModel.filteredEvents.length, 1);

    viewModel.updateTenantFilter('TENANT-2');
    expect(viewModel.filteredEvents, isEmpty);

    viewModel.clearFilters();
    viewModel.updateQuery('document');
    expect(viewModel.filteredEvents.length, 1);
  });
}

final class _FakeAuditRepository implements AuditRepository {
  @override
  Future<AuditOverview> loadOverview() async {
    return const AuditOverview(
      totalEvents: 3,
      criticalEvents: 1,
      warningEvents: 1,
      recentEvents: [
        AuditEventItem(
          tenantCode: 'TENANT-1',
          eventType: 'LOGIN_FAILED',
          severity: 'WARNING',
          occurredAtLabel: 'Hoy',
        ),
        AuditEventItem(
          tenantCode: 'TENANT-1',
          eventType: 'DOCUMENT_CREATED',
          severity: 'INFO',
          occurredAtLabel: 'Hoy',
        ),
        AuditEventItem(
          tenantCode: 'TENANT-2',
          eventType: 'ACCESS_POLICY_CHANGED',
          severity: 'CRITICAL',
          occurredAtLabel: 'Hoy',
        ),
      ],
    );
  }
}
