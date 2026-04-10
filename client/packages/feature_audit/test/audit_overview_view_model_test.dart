import 'package:feature_audit/feature_audit.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load sincroniza overview filtros y metricas derivadas', () async {
    final repository = _RecordingAuditRepository();
    final viewModel = AuditOverviewViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.totalEvents, 4);
    expect(viewModel.filteredEvents.length, 4);
    expect(viewModel.availableTenants, ['TENANT-1', 'TENANT-2', 'TENANT-3']);
    expect(viewModel.filteredCriticalEvents, 1);
    expect(viewModel.filteredWarningEvents, 2);
    expect(viewModel.message, 'Auditoría sincronizada.');

    viewModel.updateSeverityFilter('WARNING');
    expect(
      viewModel.filteredEvents.map((item) => item.eventType),
      ['LOGIN_FAILED'],
    );

    viewModel.updateSeverityFilter('ALL');
    viewModel.updateTenantFilter('TENANT-2');
    expect(
      viewModel.filteredEvents.map((item) => item.eventType),
      ['ACCESS_POLICY_CHANGED'],
    );

    viewModel.updateTenantFilter('ALL');
    viewModel.updateQuery('document');
    expect(
      viewModel.filteredEvents.map((item) => item.eventType),
      ['DOCUMENT_CREATED'],
    );

    viewModel.clearFilters();
    expect(viewModel.query, '');
    expect(viewModel.severityFilter, 'ALL');
    expect(viewModel.tenantFilter, 'ALL');
    expect(viewModel.filteredEvents.length, 4);
  });

  test('load informa error cuando el repositorio falla', () async {
    final viewModel = AuditOverviewViewModel(_FailingAuditRepository());

    await expectLater(viewModel.load(), throwsException);

    expect(viewModel.overview, isNull);
    expect(viewModel.filteredEvents, isEmpty);
    expect(viewModel.isBusy, isFalse);
    expect(viewModel.state, ViewState.error);
  });
}

final class _RecordingAuditRepository implements AuditRepository {
  int loadCalls = 0;

  @override
  Future<AuditOverview> loadOverview() async {
    loadCalls++;
    return const AuditOverview(
      totalEvents: 4,
      criticalEvents: 1,
      warningEvents: 2,
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
          occurredAtLabel: 'Hace 5 min',
        ),
        AuditEventItem(
          tenantCode: 'TENANT-3',
          eventType: 'SYNC_ERROR',
          severity: 'ERROR',
          occurredAtLabel: 'Hace 10 min',
        ),
      ],
    );
  }
}

final class _FailingAuditRepository implements AuditRepository {
  @override
  Future<AuditOverview> loadOverview() {
    throw Exception('cannot load audit overview');
  }
}
