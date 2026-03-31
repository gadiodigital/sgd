import 'package:core/core.dart';
import 'dart:collection';

import '../domain/records_overview.dart';
import '../domain/records_repository.dart';

enum RecordsQueueFilter { all, legalHold, executable }

/// Manages retention and legal hold dashboard state.
final class RecordsViewModel extends ViewModel {
  RecordsViewModel(this._repository);

  final RecordsRepository _repository;
  RecordsOverview? _overview;
  String _query = '';
  RecordsQueueFilter _queueFilter = RecordsQueueFilter.all;

  RecordsOverview? get overview => _overview;
  String get query => _query;
  RecordsQueueFilter get queueFilter => _queueFilter;

  UnmodifiableListView<DispositionItem> get filteredQueue {
    final items = _overview?.dispositionQueue ?? const <DispositionItem>[];
    final normalizedQuery = _query.trim().toUpperCase();
    final filtered = items.where((item) {
      final matchesFilter = switch (_queueFilter) {
        RecordsQueueFilter.all => true,
        RecordsQueueFilter.legalHold => item.hasLegalHold,
        RecordsQueueFilter.executable => item.canExecute,
      };
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.documentTitle.toUpperCase().contains(normalizedQuery) ||
          item.actionLabel.toUpperCase().contains(normalizedQuery);
      return matchesFilter && matchesQuery;
    }).toList(growable: false);
    return UnmodifiableListView(filtered);
  }

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateQueueFilter(RecordsQueueFilter value) {
    _queueFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _queueFilter = RecordsQueueFilter.all;
    notifyListeners();
  }

  Future<void> load() async {
    try {
      await run(() async {
        _overview = await _repository.loadOverview();
        setMessage('Cola de disposicion sincronizada.');
      });
    } catch (_) {
      setMessage('No se pudo cargar la vista de records.');
    }
  }

  Future<void> executeDisposition(String documentId) async {
    try {
      await run(() async {
        await _repository.executeDisposition(documentId);
        _overview = await _repository.loadOverview();
        setMessage('Disposición ejecutada correctamente.');
      });
    } catch (_) {
      setMessage('No se pudo ejecutar la disposición solicitada.');
    }
  }
}
