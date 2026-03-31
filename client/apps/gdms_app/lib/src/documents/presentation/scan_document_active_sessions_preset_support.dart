import '../domain/active_scan_session.dart';
import 'scan_document_active_sessions_preset.dart';
import 'scan_document_active_sessions_support.dart';

final class ScanDocumentActiveSessionsPresetAvailability {
  const ScanDocumentActiveSessionsPresetAvailability({
    required this.preset,
    required this.matchCount,
  });

  final ScanDocumentActiveSessionsPresetConfig preset;
  final int matchCount;

  bool get hasMatches => matchCount > 0;
}

final class ScanDocumentActiveSessionsPresetRecommendation {
  const ScanDocumentActiveSessionsPresetRecommendation({
    required this.availability,
    required this.reason,
  });

  final ScanDocumentActiveSessionsPresetAvailability availability;
  final String reason;
}

final class ScanDocumentActiveSessionsPresetSupport {
  static List<ScanDocumentActiveSessionsPresetAvailability> resolveAvailabilities(
    List<ActiveScanSession> sessions,
  ) {
    return ScanDocumentActiveSessionsPresetCatalog.values
        .map(
          (preset) => ScanDocumentActiveSessionsPresetAvailability(
            preset: preset,
            matchCount: ScanDocumentActiveSessionsSupport.filterSessions(
              sessions,
              filter: preset.filter,
              statusFilter: preset.statusFilter,
              sort: ScanDocumentSessionSort.recentActivity,
              pageVolumeFilter: preset.pageVolumeFilter,
              activityFilter: preset.activityFilter,
              selectedScanner: '',
              query: '',
            ).length,
          ),
        )
        .toList(growable: false);
  }

  static ScanDocumentActiveSessionsPresetRecommendation? recommendPreset(
    List<ScanDocumentActiveSessionsPresetAvailability> availabilities,
  ) {
    for (final presetId in const [
      ScanDocumentActiveSessionsPreset.oldErrors,
      ScanDocumentActiveSessionsPreset.attention,
      ScanDocumentActiveSessionsPreset.recentAdf,
      ScanDocumentActiveSessionsPreset.flatbed,
    ]) {
      final availability = availabilities
          .where((item) => item.preset.id == presetId && item.hasMatches)
          .firstOrNull;
      if (availability != null) {
        return ScanDocumentActiveSessionsPresetRecommendation(
          availability: availability,
          reason: _recommendationReason(availability),
        );
      }
    }
    return null;
  }

  static String _recommendationReason(
    ScanDocumentActiveSessionsPresetAvailability availability,
  ) {
    return switch (availability.preset.id) {
      ScanDocumentActiveSessionsPreset.oldErrors =>
        'Hay errores viejos acumulados y conviene resolverlos primero.',
      ScanDocumentActiveSessionsPreset.attention =>
        'El lote visible tiene sesiones con seguimiento pendiente.',
      ScanDocumentActiveSessionsPreset.recentAdf =>
        'La actividad reciente del host esta concentrada en ADF.',
      ScanDocumentActiveSessionsPreset.flatbed =>
        'La operacion visible esta sesgada a cama plana.',
    };
  }
}
