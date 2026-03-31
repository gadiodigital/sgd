import 'package:feature_signature/feature_signature.dart';

import '../../auth/application/app_session_view_model.dart';
import '../api/api_exception.dart';
import '../api/gdms_api_client.dart';
import 'api_repository_formatters.dart';

/// Connects the signature dashboard to the tenant signature API.
final class ApiSignatureRepository implements SignatureRepository {
  const ApiSignatureRepository(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;

  @override
  Future<SignatureOverview> loadOverview({String? documentId}) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    final suffix = documentId == null || documentId.isEmpty
        ? ''
        : '?documentId=${Uri.encodeQueryComponent(documentId)}';
    final response = await _apiClient.getList(
      '/api/tenants/$tenantId/signature/envelopes$suffix',
    );
    final items = response
        .cast<Map<String, dynamic>>()
        .map((item) {
          final dueAtUtc = item['dueAtUtc'] as String?;
          return SignatureEnvelopeItem(
            id: item['id'] as String,
            documentId: item['documentId'] as String,
            signerDisplayName:
                item['signerDisplayName'] as String? ?? 'Firmante',
            signerEmail: item['signerEmail'] as String? ?? '',
            signatureLevel: item['signatureLevel'] as String? ?? 'ELECTRONIC',
            providerCode: item['providerCode'] as String? ?? 'INTERNAL',
            status: item['status'] as String? ?? 'PENDING',
            requestedAtLabel: ApiRepositoryFormatters.formatRelativeDate(
              DateTime.parse(item['requestedAtUtc'] as String).toUtc(),
            ),
            dueAtLabel: dueAtUtc == null
                ? 'Sin vencimiento'
                : ApiRepositoryFormatters.formatRelativeDate(
                    DateTime.parse(dueAtUtc).toUtc(),
                  ),
          );
        })
        .toList(growable: false);

    return SignatureOverview(
      pendingRequests: items.where((item) => item.status == 'PENDING').length,
      signedRequests: items.where((item) => item.status == 'SIGNED').length,
      digitalRequests: items
          .where((item) => item.signatureLevel == 'DIGITAL')
          .length,
      envelopes: items,
    );
  }

  @override
  Future<void> requestSignature({
    required String documentId,
    required String signerDisplayName,
    required String signerEmail,
    required String signatureLevel,
    String? providerCode,
    DateTime? dueAtUtc,
  }) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postObject('/api/tenants/$tenantId/signature/envelopes', {
      'documentId': documentId,
      'signerDisplayName': signerDisplayName,
      'signerEmail': signerEmail,
      'signatureLevel': signatureLevel,
      'providerCode': providerCode,
      'dueAtUtc': dueAtUtc?.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> completeSignature(
    String envelopeId, {
    String? externalReference,
  }) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postNoContent(
      '/api/tenants/$tenantId/signature/envelopes/$envelopeId/complete',
      {'externalReference': externalReference},
    );
  }

  @override
  Future<void> cancelSignature(
    String envelopeId, {
    required String reason,
  }) async {
    final tenantId = _sessionViewModel.session?.tenantId;
    if (tenantId == null) {
      throw const ApiException('No hay una sesion autenticada activa.');
    }

    await _apiClient.postNoContent(
      '/api/tenants/$tenantId/signature/envelopes/$envelopeId/cancel',
      {'reason': reason},
    );
  }
}
