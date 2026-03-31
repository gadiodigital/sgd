import 'admin_overview.dart';

/// Defines the read model contract for platform governance insights.
abstract interface class AdminRepository {
  Future<AdminOverview> loadOverview();
}
