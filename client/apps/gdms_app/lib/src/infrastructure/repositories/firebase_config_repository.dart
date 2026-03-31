import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_config/feature_config.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../config/application/firebase_runtime_state.dart';

/// Uses Firebase Remote Config and Firestore with safe local fallback.
final class FirebaseConfigRepository implements ConfigRepository {
  FirebaseConfigRepository(this._runtimeState, this._sessionViewModel);

  final FirebaseRuntimeState _runtimeState;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<ConfigOverview> loadOverview() async {
    final session = _sessionViewModel.session;
    await _runtimeState.ensureInitialized();
    if (!_runtimeState.isAvailable || session == null) {
      return _fallbackOverview(_runtimeState.statusMessage);
    }

    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults(const {
      'gdms_banner_message': 'Configuración local activa para GDMS.',
      'gdms_workflow_enabled': true,
      'gdms_search_result_limit': 25,
    });

    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {}

    var firestoreAvailable = true;
    var preferredLandingModule = 'documents';
    var showComplianceTips = true;

    try {
      final document = await FirebaseFirestore.instance
          .collection('gdmsUserPreferences')
          .doc('${session.tenantId}_${session.userId}')
          .get();
      final data = document.data();
      if (data != null) {
        preferredLandingModule =
            data['preferredLandingModule'] as String? ?? preferredLandingModule;
        showComplianceTips =
            data['showComplianceTips'] as bool? ?? showComplianceTips;
      }
    } catch (_) {
      firestoreAvailable = false;
    }

    return ConfigOverview(
      remoteConfigAvailable: true,
      firestoreAvailable: firestoreAvailable,
      bannerMessage: remoteConfig.getString('gdms_banner_message'),
      workflowEnabled: remoteConfig.getBool('gdms_workflow_enabled'),
      searchResultLimit: remoteConfig.getInt('gdms_search_result_limit'),
      preferredLandingModule: preferredLandingModule,
      showComplianceTips: showComplianceTips,
      statusMessage: _runtimeState.statusMessage,
    );
  }

  @override
  Future<void> savePreferences({
    required String preferredLandingModule,
    required bool showComplianceTips,
  }) async {
    final session = _sessionViewModel.session;
    await _runtimeState.ensureInitialized();
    if (!_runtimeState.isAvailable || session == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('gdmsUserPreferences')
        .doc('${session.tenantId}_${session.userId}')
        .set({
          'preferredLandingModule': preferredLandingModule,
          'showComplianceTips': showComplianceTips,
          'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
  }

  ConfigOverview _fallbackOverview(String statusMessage) {
    return ConfigOverview(
      remoteConfigAvailable: false,
      firestoreAvailable: false,
      bannerMessage: 'Configuración dinámica no disponible. Se usan defaults locales.',
      workflowEnabled: true,
      searchResultLimit: 25,
      preferredLandingModule: 'documents',
      showComplianceTips: true,
      statusMessage: statusMessage,
    );
  }
}
