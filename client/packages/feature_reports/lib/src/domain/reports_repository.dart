import 'operational_report_overview.dart';

/// Defines the contract required by the reports dashboard.
abstract interface class ReportsRepository {
  Future<OperationalReportOverview> loadOverview();
}
