import 'package:feature_reports/feature_reports.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';

/// Connects the reports dashboard to the tenant reports API.
final class ApiReportsRepository implements ReportsRepository {
  const ApiReportsRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<OperationalReportOverview> loadOverview() async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final response = await _apiClient.getObject(
      '/api/tenants/$tenantId/reports/operational-summary',
    );
    final platformSummary = await _loadPlatformSummaryIfAvailable();

    return OperationalReportOverview(
      totalDocuments: response['totalDocuments'] as int? ?? 0,
      activeLegalHolds: response['activeLegalHolds'] as int? ?? 0,
      openWorkflowTasks: response['openWorkflowTasks'] as int? ?? 0,
      pendingSignatures: response['pendingSignatures'] as int? ?? 0,
      cancelledSignatures: response['cancelledSignatures'] as int? ?? 0,
      pendingDispositionItems: response['pendingDispositionItems'] as int? ?? 0,
      failedLoginsLast24Hours: response['failedLoginsLast24Hours'] as int? ?? 0,
      platformSummary: platformSummary,
    );
  }

  Future<PlatformReportOverview?> _loadPlatformSummaryIfAvailable() async {
    if (_sessionViewModel.identity?.isPlatformAdmin != true) {
      return null;
    }

    final response = await _apiClient.getObject(
      '/api/reports/platform-summary',
    );
    return PlatformReportOverview(
      totalTenants: response['totalTenants'] as int? ?? 0,
      totalDocuments: response['totalDocuments'] as int? ?? 0,
      openWorkflowTasks: response['openWorkflowTasks'] as int? ?? 0,
      pendingSignatures: response['pendingSignatures'] as int? ?? 0,
      cancelledSignatures: response['cancelledSignatures'] as int? ?? 0,
      failedLoginsLast24Hours: response['failedLoginsLast24Hours'] as int? ?? 0,
    );
  }
}
