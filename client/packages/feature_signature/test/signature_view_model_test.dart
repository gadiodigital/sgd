import 'package:feature_signature/feature_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load sincroniza overview y filtros por query y estado', () async {
    final repository = _RecordingSignatureRepository();
    final viewModel = SignatureViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.pendingRequests, 1);
    expect(viewModel.filteredEnvelopes.length, 3);
    expect(viewModel.filteredPendingRequests, 1);
    expect(viewModel.filteredSignedRequests, 1);
    expect(viewModel.filteredDigitalRequests, 2);
    expect(viewModel.message, 'Firma documental sincronizada.');

    viewModel.updateQuery('gomez');
    expect(viewModel.filteredEnvelopes.map((item) => item.id), ['sig-2']);

    viewModel.updateQuery('');
    viewModel.updateStatusFilter('CANCELLED');
    expect(viewModel.filteredEnvelopes.map((item) => item.id), ['sig-3']);

    viewModel.clearFilters();
    expect(viewModel.query, '');
    expect(viewModel.statusFilter, 'ALL');
    expect(viewModel.filteredEnvelopes.length, 3);
  });

  test('completeSignature recarga overview y publica mensaje de exito', () async {
    final repository = _RecordingSignatureRepository();
    final viewModel = SignatureViewModel(repository);

    await viewModel.load();
    await viewModel.completeSignature('sig-1');

    expect(repository.completedEnvelopeIds, ['sig-1']);
    expect(repository.loadCalls, 2);
    expect(
      viewModel.message,
      'Solicitud de firma completada correctamente.',
    );
  });

  test('cancelSignature persiste motivo y recarga overview', () async {
    final repository = _RecordingSignatureRepository();
    final viewModel = SignatureViewModel(repository);

    await viewModel.load();
    await viewModel.cancelSignature('sig-1', 'Firmante incorrecto');

    expect(repository.cancelledEnvelopeIds, ['sig-1']);
    expect(repository.cancelReasons, ['Firmante incorrecto']);
    expect(repository.loadCalls, 2);
    expect(
      viewModel.message,
      'Solicitud de firma cancelada correctamente.',
    );
  });
}

final class _RecordingSignatureRepository implements SignatureRepository {
  int loadCalls = 0;
  final List<String> completedEnvelopeIds = <String>[];
  final List<String> cancelledEnvelopeIds = <String>[];
  final List<String> cancelReasons = <String>[];

  @override
  Future<void> cancelSignature(
    String envelopeId, {
    required String reason,
  }) async {
    cancelledEnvelopeIds.add(envelopeId);
    cancelReasons.add(reason);
  }

  @override
  Future<void> completeSignature(
    String envelopeId, {
    String? externalReference,
  }) async {
    completedEnvelopeIds.add(envelopeId);
  }

  @override
  Future<SignatureOverview> loadOverview({String? documentId}) async {
    loadCalls++;
    return const SignatureOverview(
      pendingRequests: 1,
      signedRequests: 1,
      digitalRequests: 2,
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
          signerEmail: 'cliente@gomez.com',
          signatureLevel: 'ELECTRONIC',
          providerCode: 'INTERNAL',
          status: 'COMPLETED',
          requestedAtLabel: 'Ayer',
          dueAtLabel: 'Sin vencimiento',
        ),
        SignatureEnvelopeItem(
          id: 'sig-3',
          documentId: 'doc-3',
          signerDisplayName: 'Proveedor Norte',
          signerEmail: 'norte@proveedor.com',
          signatureLevel: 'DIGITAL',
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
