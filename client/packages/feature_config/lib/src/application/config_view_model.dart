import 'package:core/core.dart';

import '../domain/config_overview.dart';
import '../domain/config_repository.dart';

/// Coordinates dynamic configuration and user-preference state.
final class ConfigViewModel extends ViewModel {
  ConfigViewModel(this._repository);

  final ConfigRepository _repository;
  ConfigOverview? _overview;
  String _preferredLandingModule = 'documents';
  bool _showComplianceTips = true;

  ConfigOverview? get overview => _overview;
  String get preferredLandingModule => _preferredLandingModule;
  bool get showComplianceTips => _showComplianceTips;

  void updatePreferredLandingModule(String value) {
    _preferredLandingModule = value;
    notifyListeners();
  }

  void updateShowComplianceTips(bool value) {
    _showComplianceTips = value;
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      _preferredLandingModule = _overview?.preferredLandingModule ?? 'documents';
      _showComplianceTips = _overview?.showComplianceTips ?? true;
      setMessage(_overview?.statusMessage ?? 'Configuración sincronizada.');
    });
  }

  Future<void> savePreferences() async {
    await run(() async {
      await _repository.savePreferences(
        preferredLandingModule: _preferredLandingModule,
        showComplianceTips: _showComplianceTips,
      );
      _overview = await _repository.loadOverview();
      _preferredLandingModule = _overview?.preferredLandingModule ?? 'documents';
      _showComplianceTips = _overview?.showComplianceTips ?? true;
      setMessage('Preferencias guardadas correctamente.');
    });
  }
}
