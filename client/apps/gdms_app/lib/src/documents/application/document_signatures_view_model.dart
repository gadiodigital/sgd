import 'dart:collection';

import 'package:core/core.dart';
import 'package:feature_signature/feature_signature.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_signature_repository.dart';

/// Loads signature requests associated with the selected document.
final class DocumentSignaturesViewModel extends ViewModel {
  DocumentSignaturesViewModel(this._sessionViewModel)
    : _signatureRepository = ApiSignatureRepository(
        _sessionViewModel.apiClient,
        _sessionViewModel,
      );

  final AppSessionViewModel _sessionViewModel;
  final ApiSignatureRepository _signatureRepository;
  List<SignatureEnvelopeItem> _envelopes = const [];

  UnmodifiableListView<SignatureEnvelopeItem> get envelopes =>
      UnmodifiableListView(_envelopes);

  Future<void> load(String documentId) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return;
    }

    try {
      await run(() async {
        final overview = await _signatureRepository.loadOverview(
          documentId: documentId,
        );
        _envelopes = overview.envelopes;
        setMessage(
          _envelopes.isEmpty
              ? 'No hay solicitudes de firma para este documento.'
              : 'Firmas documentales cargadas.',
        );
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<void> completeSignature(String envelopeId, String documentId) async {
    try {
      await run(() async {
        await _signatureRepository.completeSignature(envelopeId);
        await load(documentId);
        setMessage('Solicitud de firma completada correctamente.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<void> cancelSignature(
    String envelopeId,
    String documentId,
    String reason,
  ) async {
    try {
      await run(() async {
        await _signatureRepository.cancelSignature(envelopeId, reason: reason);
        await load(documentId);
        setMessage('Solicitud de firma cancelada correctamente.');
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la operación de firma documental.';
  }
}
