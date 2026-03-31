import 'package:core/core.dart';
import 'dart:collection';

import '../domain/saved_search.dart';
import '../domain/search_overview.dart';
import '../domain/search_filters.dart';
import '../domain/search_preset.dart';
import '../domain/search_repository.dart';

/// Coordinates the dedicated search workspace state.
final class SearchViewModel extends ViewModel {
  SearchViewModel(this._repository);

  final SearchRepository _repository;
  SearchOverview? _overview;
  String _query = '';
  String _documentTypeCode = '';
  String _status = '';
  bool _onlyOnLegalHold = false;
  final List<SavedSearch> _savedSearches = [];
  static const _presets = [
    SearchPreset(
      label: 'Contratos activos',
      query: '',
      documentTypeCode: 'CONTRACT',
      status: 'ACTIVE',
      onlyOnLegalHold: false,
    ),
    SearchPreset(
      label: 'Con legal hold',
      query: '',
      documentTypeCode: '',
      status: '',
      onlyOnLegalHold: true,
    ),
    SearchPreset(
      label: 'Dispuestos',
      query: '',
      documentTypeCode: '',
      status: 'DISPOSED',
      onlyOnLegalHold: false,
    ),
  ];

  SearchOverview? get overview => _overview;
  String get query => _query;
  String get documentTypeCode => _documentTypeCode;
  String get status => _status;
  bool get onlyOnLegalHold => _onlyOnLegalHold;
  UnmodifiableListView<SearchPreset> get presets =>
      UnmodifiableListView(_presets);
  UnmodifiableListView<SavedSearch> get savedSearches =>
      UnmodifiableListView(_savedSearches);

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateDocumentTypeCode(String value) {
    _documentTypeCode = value.trim().toUpperCase();
    notifyListeners();
  }

  void updateStatus(String value) {
    _status = value.trim().toUpperCase();
    notifyListeners();
  }

  void updateOnlyOnLegalHold(bool value) {
    _onlyOnLegalHold = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _documentTypeCode = '';
    _status = '';
    _onlyOnLegalHold = false;
    notifyListeners();
  }

  void applyPreset(SearchPreset preset) {
    _query = preset.query;
    _documentTypeCode = preset.documentTypeCode;
    _status = preset.status;
    _onlyOnLegalHold = preset.onlyOnLegalHold;
    notifyListeners();
  }

  void saveCurrentSearch() {
    final snapshot = SavedSearch(
      label: _buildSavedSearchLabel(),
      query: _query,
      filters: SearchFilters(
        documentTypeCode: _documentTypeCode,
        status: _status,
        onlyOnLegalHold: _onlyOnLegalHold,
      ),
    );
    final alreadyExists = _savedSearches.any(
      (item) =>
          item.query == snapshot.query &&
          item.filters.documentTypeCode == snapshot.filters.documentTypeCode &&
          item.filters.status == snapshot.filters.status &&
          item.filters.onlyOnLegalHold == snapshot.filters.onlyOnLegalHold,
    );
    if (alreadyExists) {
      setMessage('La búsqueda actual ya estaba guardada.');
      return;
    }

    _savedSearches.insert(0, snapshot);
    if (_savedSearches.length > 6) {
      _savedSearches.removeLast();
    }
    setMessage('Búsqueda guardada para esta sesión.');
    notifyListeners();
  }

  void applySavedSearch(SavedSearch savedSearch) {
    _query = savedSearch.query;
    _documentTypeCode = savedSearch.filters.documentTypeCode;
    _status = savedSearch.filters.status;
    _onlyOnLegalHold = savedSearch.filters.onlyOnLegalHold;
    notifyListeners();
  }

  void removeSavedSearch(SavedSearch savedSearch) {
    _savedSearches.remove(savedSearch);
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.search(
        query: _query,
        filters: SearchFilters(
          documentTypeCode: _documentTypeCode,
          status: _status,
          onlyOnLegalHold: _onlyOnLegalHold,
        ),
      );
      setMessage(
        _query.trim().isEmpty
            ? 'Ingresá un criterio o filtros para buscar documentos.'
            : 'Se encontraron ${_overview?.resultsCount ?? 0} resultados.',
      );
    });
  }

  String _buildSavedSearchLabel() {
    if (_query.trim().isNotEmpty) {
      return 'Busqueda: ${_query.trim()}';
    }
    if (_documentTypeCode.isNotEmpty) {
      return 'Tipo: $_documentTypeCode';
    }
    if (_status.isNotEmpty) {
      return 'Estado: $_status';
    }
    if (_onlyOnLegalHold) {
      return 'Solo legal hold';
    }
    return 'Consulta general';
  }
}
