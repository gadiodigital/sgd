import 'package:core/core.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/repositories/api_documents_repository.dart';
import '../../infrastructure/repositories/api_signature_repository.dart';
import '../domain/signature_document_option.dart';

/// Coordinates the create signature request dialog.
final class CreateSignatureRequestViewModel extends ViewModel {
  CreateSignatureRequestViewModel({
    required AppSessionViewModel sessionViewModel,
  }) : _documentsRepository = ApiDocumentsRepository(
         sessionViewModel.apiClient,
         sessionViewModel,
       ),
       _signatureRepository = ApiSignatureRepository(
         sessionViewModel.apiClient,
         sessionViewModel,
       );

  final ApiDocumentsRepository _documentsRepository;
  final ApiSignatureRepository _signatureRepository;

  List<SignatureDocumentOption> _documentOptions = const [];

  List<SignatureDocumentOption> get documentOptions => _documentOptions;

  Future<void> load() async {
    await run(() async {
      final overview = await _documentsRepository.loadOverview();
      _documentOptions = overview.recentDocuments
          .map(
            (item) => SignatureDocumentOption(id: item.id, title: item.title),
          )
          .toList(growable: false);
      setMessage('Documentos disponibles para firma cargados.');
    });
  }

  void preloadDocument(String documentId, String title) {
    final exists = _documentOptions.any((item) => item.id == documentId);
    if (exists) {
      return;
    }

    _documentOptions = [
      SignatureDocumentOption(id: documentId, title: title),
      ..._documentOptions,
    ];
    notifyListeners();
  }

  Future<void> submit({
    required String documentId,
    required String signerDisplayName,
    required String signerEmail,
    required String signatureLevel,
  }) async {
    await run(() async {
      await _signatureRepository.requestSignature(
        documentId: documentId,
        signerDisplayName: signerDisplayName,
        signerEmail: signerEmail,
        signatureLevel: signatureLevel,
      );
      setMessage('Solicitud de firma creada correctamente.');
    });
  }
}
