import 'package:core/core.dart';

import '../domain/real_estate_dashboard_overview.dart';
import '../domain/real_estate_dashboard_repository.dart';

/// Coordinates the real-estate vertical overview.
final class RealEstateDashboardViewModel extends ViewModel {
  RealEstateDashboardViewModel(this._repository);

  final RealEstateDashboardRepository _repository;
  RealEstateDashboardOverview? _overview;

  RealEstateDashboardOverview? get overview => _overview;

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Panel inmobiliario sincronizado.');
    });
  }
}
