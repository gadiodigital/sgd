import 'dart:collection';

import 'package:core/core.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../domain/legal_hold_entry.dart';
import '../domain/retention_policy_option.dart';

/// Manages retention and legal-hold operations for a single document.
final class RecordsItemManagementViewModel extends ViewModel {
  RecordsItemManagementViewModel(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  List<RetentionPolicyOption> _policies = const [];
  List<LegalHoldEntry> _legalHolds = const [];

  UnmodifiableListView<RetentionPolicyOption> get policies =>
      UnmodifiableListView(_policies);
  UnmodifiableListView<LegalHoldEntry> get legalHolds =>
      UnmodifiableListView(_legalHolds);

  Future<void> load(String documentId) async {
    try {
      await run(() async {
        await _loadData(documentId);
        setMessage(_buildSummaryMessage());
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<bool> applyRetentionPolicy({
    required String documentId,
    required String policyCode,
  }) async {
    try {
      await run(() async {
        await _apiClient.postNoContent(
          _documentPath(documentId, 'retention-policy'),
          {'retentionPolicyCode': policyCode},
        );
        await _loadData(documentId);
        setMessage('Política de retención aplicada correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> createLegalHold({
    required String documentId,
    required String reason,
  }) async {
    try {
      await run(() async {
        await _apiClient.postObject(
          _documentPath(documentId, 'legal-holds'),
          {'reason': reason.trim()},
        );
        await _loadData(documentId);
        setMessage('Legal hold creado correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> releaseLegalHold({
    required String documentId,
    required String legalHoldId,
    required String reason,
  }) async {
    try {
      await run(() async {
        await _apiClient.postObject(
          _tenantPath('legal-holds/$legalHoldId/release'),
          {'reason': reason.trim()},
        );
        await _loadData(documentId);
        setMessage('Legal hold liberado correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<void> _loadData(String documentId) async {
    final policiesJson = await _apiClient.getList(_tenantPath('retention-policies'));
    final holdsJson = await _apiClient.getList(_documentPath(documentId, 'legal-holds'));

    _policies = policiesJson
        .cast<Map<String, dynamic>>()
        .where((item) => item['isActive'] == true)
        .map(RetentionPolicyOption.fromJson)
        .toList(growable: false);
    _legalHolds = holdsJson
        .cast<Map<String, dynamic>>()
        .map(LegalHoldEntry.fromJson)
        .toList(growable: false);
  }

  String _buildSummaryMessage() {
    final activeHolds = _legalHolds.where((item) => item.isActive).length;
    if (activeHolds > 0) {
      return 'El documento tiene $activeHolds legal hold activo.';
    }

    return 'Sin legal holds activos para este documento.';
  }

  String _documentPath(String documentId, String suffix) {
    return '${_tenantPath('documents/$documentId')}/$suffix';
  }

  String _tenantPath(String suffix) {
    final session = _sessionViewModel.session;
    if (session == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    return '/api/tenants/${session.tenantId}/records/$suffix';
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la operación de records.';
  }
}
