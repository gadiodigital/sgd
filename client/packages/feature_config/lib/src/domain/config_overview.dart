/// Represents the current dynamic configuration and user preferences snapshot.
final class ConfigOverview {
  const ConfigOverview({
    required this.remoteConfigAvailable,
    required this.firestoreAvailable,
    required this.bannerMessage,
    required this.workflowEnabled,
    required this.searchResultLimit,
    required this.preferredLandingModule,
    required this.showComplianceTips,
    required this.statusMessage,
  });

  final bool remoteConfigAvailable;
  final bool firestoreAvailable;
  final String bannerMessage;
  final bool workflowEnabled;
  final int searchResultLimit;
  final String preferredLandingModule;
  final bool showComplianceTips;
  final String statusMessage;
}
