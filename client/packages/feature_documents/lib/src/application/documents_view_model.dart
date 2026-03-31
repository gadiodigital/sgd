import 'package:core/core.dart';

import '../domain/documents_overview.dart';
import '../domain/documents_repository.dart';

/// Drives the state of the document exploration dashboard.
final class DocumentsViewModel extends ViewModel {
  DocumentsViewModel(this._repository);

  final DocumentsRepository _repository;
  DocumentsOverview? _overview;
  String _query = '';

  DocumentsOverview? get overview => _overview;
  String get query => _query;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> load() async {
    try {
      await run(() async {
        _overview = await _repository.loadOverview(query: _query);
        setMessage(
          _query.trim().isEmpty
              ? 'Repositorio documental actualizado.'
              : 'Resultados para "$_query".',
        );
      });
    } catch (_) {
      setMessage('No se pudo cargar el repositorio documental.');
    }
  }
}
