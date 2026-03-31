import 'session_overview.dart';

/// Defines the contract to obtain session state in the auth module.
abstract interface class SessionOverviewRepository {
  Future<SessionOverview> loadCurrentSession();
}
