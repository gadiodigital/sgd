import 'package:feature_signature/feature_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads signature overview data', () async {
    final viewModel = SignatureViewModel(_FakeSignatureRepository());

    await viewModel.load();

    expect(viewModel.overview?.pendingRequests, 1);
    expect(viewModel.overview?.envelopes.length, 2);
    expect(viewModel.filteredEnvelopes.length, 2);

    viewModel.updateStatusFilter('CANCELLED');
    expect(viewModel.filteredEnvelopes.single.status, 'CANCELLED');
  });
}

final class _FakeSignatureRepository implements SignatureRepository {
  @override
  Future<void> cancelSignature(
    String envelopeId, {
    required String reason,
  }) async {}

  @override
  Future<void> completeSignature(
    String envelopeId, {
    String? externalReference,
  }) async {}

  @override
  Future<SignatureOverview> loadOverview({String? documentId}) async {
    return const SignatureOverview(
      pendingRequests: 1,
      signedRequests: 2,
      digitalRequests: 1,
      envelopes: [
        SignatureEnvelopeItem(
          id: 'sig-1',
          documentId: 'doc-1',
          signerDisplayName: 'Estudio Perez',
          signerEmail: 'firma@cliente.com',
          signatureLevel: 'DIGITAL',
          providerCode: 'INTERNAL',
          status: 'PENDING',
          requestedAtLabel: 'Hoy',
          dueAtLabel: 'Mañana',
        ),
        SignatureEnvelopeItem(
          id: 'sig-2',
          documentId: 'doc-2',
          signerDisplayName: 'Cliente Gomez',
          signerEmail: 'cancelada@cliente.com',
          signatureLevel: 'ELECTRONIC',
          providerCode: 'INTERNAL',
          status: 'CANCELLED',
          requestedAtLabel: 'Ayer',
          dueAtLabel: 'Sin vencimiento',
        ),
      ],
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
  }) async {}
}
