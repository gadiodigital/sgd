import 'package:core/core.dart';
import 'dart:collection';

import '../domain/audit_overview.dart';
import '../domain/audit_event_item.dart';
import '../domain/audit_repository.dart';

/// Loads audit information for the dedicated audit workspace.
final class AuditOverviewViewModel extends ViewModel {
  AuditOverviewViewModel(this._repository);

  final AuditRepository _repository;
  AuditOverview? _overview;
  String _query = '';
  String _severityFilter = 'ALL';
  String _tenantFilter = 'ALL';

  AuditOverview? get overview => _overview;
  String get query => _query;
  String get severityFilter => _severityFilter;
  String get tenantFilter => _tenantFilter;

  UnmodifiableListView<AuditEventItem> get filteredEvents {
    final events = _overview?.recentEvents ?? const <AuditEventItem>[];
    final normalizedQuery = _query.trim().toUpperCase();
    final filtered = events
        .where((item) {
          final matchesSeverity =
              _severityFilter == 'ALL' || item.severity == _severityFilter;
          final matchesTenant =
              _tenantFilter == 'ALL' || item.tenantCode == _tenantFilter;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.eventType.contains(normalizedQuery) ||
              item.tenantCode.contains(normalizedQuery);
          return matchesSeverity && matchesTenant && matchesQuery;
        })
        .toList(growable: false);
    return UnmodifiableListView(filtered);
  }

  int get filteredCriticalEvents =>
      filteredEvents.where((item) => item.severity == 'CRITICAL').length;

  int get filteredWarningEvents => filteredEvents
      .where((item) => item.severity == 'WARNING' || item.severity == 'ERROR')
      .length;

  UnmodifiableListView<String> get availableTenants {
    final tenants = <String>{};
    for (final event in _overview?.recentEvents ?? const <AuditEventItem>[]) {
      tenants.add(event.tenantCode);
    }

    final sorted = tenants.toList()..sort();
    return UnmodifiableListView(sorted);
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Auditoría sincronizada.');
    });
  }

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateSeverityFilter(String value) {
    _severityFilter = value;
    notifyListeners();
  }

  void updateTenantFilter(String value) {
    _tenantFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _severityFilter = 'ALL';
    _tenantFilter = 'ALL';
    notifyListeners();
  }
}
