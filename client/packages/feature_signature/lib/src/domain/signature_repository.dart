import 'signature_overview.dart';

/// Defines the contract required by the signature dashboard.
abstract interface class SignatureRepository {
  Future<SignatureOverview> loadOverview({String? documentId});

  Future<void> requestSignature({
    required String documentId,
    required String signerDisplayName,
    required String signerEmail,
    required String signatureLevel,
    String? providerCode,
    DateTime? dueAtUtc,
  });

  Future<void> completeSignature(
    String envelopeId, {
    String? externalReference,
  });

  Future<void> cancelSignature(
    String envelopeId, {
    required String reason,
  });
}
