import 'package:flutter/foundation.dart';

import 'view_state.dart';

/// Provides a small MVVM-friendly base class for presentation state.
abstract class ViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _message;

  /// Gets the current state.
  ViewState get state => _state;

  /// Gets the latest user-facing status message.
  String? get message => _message;

  /// Gets whether the view model is currently busy.
  bool get isBusy => _state == ViewState.loading;

  /// Executes an async operation and updates state consistently.
  Future<void> run(Future<void> Function() action) async {
    _setState(ViewState.loading);

    try {
      await action();
      _setState(ViewState.success);
    } catch (_) {
      _setState(ViewState.error);
      rethrow;
    }
  }

  /// Updates the latest status message.
  void setMessage(String? value) {
    _message = value;
    notifyListeners();
  }

  void _setState(ViewState value) {
    _state = value;
    notifyListeners();
  }
}
