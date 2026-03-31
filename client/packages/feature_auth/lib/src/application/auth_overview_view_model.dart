import 'package:core/core.dart';

import '../domain/session_overview.dart';
import '../domain/session_overview_repository.dart';

/// Coordinates the auth dashboard state for the current user.
final class AuthOverviewViewModel extends ViewModel {
  AuthOverviewViewModel(this._repository);

  final SessionOverviewRepository _repository;
  SessionOverview? _session;

  SessionOverview? get session => _session;

  Future<void> load() async {
    try {
      await run(() async {
        _session = await _repository.loadCurrentSession();
        setMessage('Sesion preparada para operar.');
      });
    } catch (_) {
      setMessage('No se pudo cargar la sesion actual.');
    }
  }
}
