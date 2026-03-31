import 'package:firebase_core/firebase_core.dart';

/// Tracks whether Firebase could be initialized in the current runtime.
final class FirebaseRuntimeState {
  bool _initializationAttempted = false;
  bool _isAvailable = false;
  String _statusMessage = 'Firebase no inicializado.';

  bool get isAvailable => _isAvailable;
  String get statusMessage => _statusMessage;

  Future<void> ensureInitialized() async {
    if (_initializationAttempted) {
      return;
    }

    _initializationAttempted = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _isAvailable = true;
      _statusMessage = 'Firebase disponible.';
    } catch (_) {
      _isAvailable = false;
      _statusMessage =
          'Firebase no está configurado en este entorno. Se usan defaults locales.';
    }
  }
}
