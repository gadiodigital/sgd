import 'package:core/core.dart';

import '../domain/corporate_dashboard_overview.dart';
import '../domain/corporate_dashboard_repository.dart';

/// Coordinates the corporate vertical overview.
final class CorporateDashboardViewModel extends ViewModel {
  CorporateDashboardViewModel(this._repository);

  final CorporateDashboardRepository _repository;
  CorporateDashboardOverview? _overview;

  CorporateDashboardOverview? get overview => _overview;

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Panel corporativo sincronizado.');
    });
  }
}
