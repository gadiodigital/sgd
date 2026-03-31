/// Represents a signature request row in the UI.
final class SignatureEnvelopeItem {
  const SignatureEnvelopeItem({
    required this.id,
    required this.documentId,
    required this.signerDisplayName,
    required this.signerEmail,
    required this.signatureLevel,
    required this.providerCode,
    required this.status,
    required this.requestedAtLabel,
    required this.dueAtLabel,
  });

  final String id;
  final String documentId;
  final String signerDisplayName;
  final String signerEmail;
  final String signatureLevel;
  final String providerCode;
  final String status;
  final String requestedAtLabel;
  final String dueAtLabel;

  bool get canComplete => status == 'PENDING';
  bool get canCancel => status == 'PENDING';
  bool get isCancelled => status == 'CANCELLED';
}
