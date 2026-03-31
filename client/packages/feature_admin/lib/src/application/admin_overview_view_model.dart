import 'package:core/core.dart';

import '../domain/admin_overview.dart';
import '../domain/admin_repository.dart';

/// Coordinates admin and governance dashboard state.
final class AdminOverviewViewModel extends ViewModel {
  AdminOverviewViewModel(this._repository);

  final AdminRepository _repository;
  AdminOverview? _overview;

  AdminOverview? get overview => _overview;

  Future<void> load() async {
    try {
      await run(() async {
        _overview = await _repository.loadOverview();
        setMessage('Gobierno de plataforma sincronizado.');
      });
    } catch (_) {
      setMessage('No se pudo cargar el tablero de administracion.');
    }
  }
}
