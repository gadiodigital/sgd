import 'package:core/core.dart';
import 'dart:collection';

import '../domain/integration_status_item.dart';
import '../domain/integrations_overview.dart';
import '../domain/integrations_repository.dart';

/// Coordinates integration status loading and presentation.
final class IntegrationsViewModel extends ViewModel {
  IntegrationsViewModel(this._repository);

  final IntegrationsRepository _repository;
  IntegrationsOverview? _overview;
  String _query = '';
  String _categoryFilter = '';
  String _statusFilter = '';

  IntegrationsOverview? get overview => _overview;
  String get query => _query;
  String get categoryFilter => _categoryFilter;
  String get statusFilter => _statusFilter;
  UnmodifiableListView<IntegrationStatusItem> get visibleItems {
    final items = _overview?.items ?? const <IntegrationStatusItem>[];
    final normalizedQuery = _query.trim().toUpperCase();
    final filtered = items.where((item) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.displayName.toUpperCase().contains(normalizedQuery) ||
          item.code.toUpperCase().contains(normalizedQuery) ||
          item.detail.toUpperCase().contains(normalizedQuery);
      final matchesCategory =
          _categoryFilter.isEmpty || item.category == _categoryFilter;
      final matchesStatus = _statusFilter.isEmpty || item.status == _statusFilter;
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList(growable: false);
    return UnmodifiableListView(filtered);
  }
  UnmodifiableListView<String> get availableCategories {
    final categories = _overview?.items.map((item) => item.category).toSet().toList()
      ?..sort();
    return UnmodifiableListView(categories ?? const <String>[]);
  }
  UnmodifiableListView<String> get availableStatuses {
    final statuses = _overview?.items.map((item) => item.status).toSet().toList()
      ?..sort();
    return UnmodifiableListView(statuses ?? const <String>[]);
  }
  int get visibleReadyCount => visibleItems
      .where((item) => item.status == 'READY' || item.status == 'EMULATOR')
      .length;
  int get visibleWarningCount => visibleItems
      .where((item) => item.status != 'READY' && item.status != 'EMULATOR')
      .length;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateCategoryFilter(String value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void updateStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _categoryFilter = '';
    _statusFilter = '';
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Integraciones sincronizadas.');
    });
  }
}
