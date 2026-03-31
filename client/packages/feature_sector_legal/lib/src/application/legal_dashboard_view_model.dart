import 'package:core/core.dart';

import '../domain/legal_dashboard_overview.dart';
import '../domain/legal_dashboard_repository.dart';

/// Coordinates the legal vertical overview.
final class LegalDashboardViewModel extends ViewModel {
  LegalDashboardViewModel(this._repository);

  final LegalDashboardRepository _repository;
  LegalDashboardOverview? _overview;

  LegalDashboardOverview? get overview => _overview;

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Panel jurídico sincronizado.');
    });
  }
}
