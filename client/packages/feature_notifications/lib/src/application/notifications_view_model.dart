import 'package:core/core.dart';
import 'dart:collection';

import '../domain/notifications_overview.dart';
import '../domain/notification_item.dart';
import '../domain/notifications_repository.dart';

/// Coordinates notification inbox state.
final class NotificationsViewModel extends ViewModel {
  NotificationsViewModel(this._repository);

  final NotificationsRepository _repository;
  NotificationsOverview? _overview;
  String _query = '';
  String _severityFilter = 'ALL';
  String _categoryFilter = 'ALL';

  NotificationsOverview? get overview => _overview;
  String get query => _query;
  String get severityFilter => _severityFilter;
  String get categoryFilter => _categoryFilter;

  UnmodifiableListView<NotificationItem> get filteredItems {
    final items = _overview?.items ?? const <NotificationItem>[];
    final normalizedQuery = _query.trim().toUpperCase();
    final filtered = items.where((item) {
      final matchesSeverity =
          _severityFilter == 'ALL' || item.severity == _severityFilter;
      final matchesCategory =
          _categoryFilter == 'ALL' || item.category == _categoryFilter;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.title.toUpperCase().contains(normalizedQuery) ||
          item.detail.toUpperCase().contains(normalizedQuery);
      return matchesSeverity && matchesCategory && matchesQuery;
    }).toList(growable: false);
    return UnmodifiableListView(filtered);
  }

  UnmodifiableListView<String> get availableCategories {
    final categories = <String>{};
    for (final item in _overview?.items ?? const <NotificationItem>[]) {
      categories.add(item.category);
    }

    final sorted = categories.toList()..sort();
    return UnmodifiableListView(sorted);
  }

  int get filteredCriticalItems =>
      filteredItems.where((item) => item.severity == 'CRITICAL').length;

  int get filteredWarningItems => filteredItems
      .where((item) => item.severity == 'WARNING' || item.severity == 'ERROR')
      .length;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateSeverityFilter(String value) {
    _severityFilter = value;
    notifyListeners();
  }

  void updateCategoryFilter(String value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _severityFilter = 'ALL';
    _categoryFilter = 'ALL';
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Inbox operativo sincronizado.');
    });
  }
}
