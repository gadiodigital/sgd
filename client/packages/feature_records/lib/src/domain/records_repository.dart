import 'records_overview.dart';

/// Defines the source of retention and legal hold dashboard data.
abstract interface class RecordsRepository {
  Future<RecordsOverview> loadOverview();
  Future<void> executeDisposition(String documentId);
}
