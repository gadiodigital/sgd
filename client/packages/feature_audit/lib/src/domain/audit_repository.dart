import 'audit_overview.dart';

/// Defines the read model required by the audit workspace.
abstract interface class AuditRepository {
  Future<AuditOverview> loadOverview();
}
