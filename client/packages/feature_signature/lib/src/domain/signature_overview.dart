import 'signature_envelope_item.dart';

/// Aggregates signature KPIs and recent signature requests.
final class SignatureOverview {
  const SignatureOverview({
    required this.pendingRequests,
    required this.signedRequests,
    required this.digitalRequests,
    required this.envelopes,
  });

  final int pendingRequests;
  final int signedRequests;
  final int digitalRequests;
  final List<SignatureEnvelopeItem> envelopes;
}
