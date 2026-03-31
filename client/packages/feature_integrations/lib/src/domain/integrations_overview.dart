import 'integration_status_item.dart';

/// Aggregates integration health metrics and the current status list.
final class IntegrationsOverview {
  const IntegrationsOverview({
    required this.readyCount,
    required this.warningCount,
    required this.items,
  });

  final int readyCount;
  final int warningCount;
  final List<IntegrationStatusItem> items;
}
