import 'package:core/core.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import 'upload_multipart_support.dart';

/// Coordinates uploading a new immutable version for an existing document.
final class DocumentVersionUploadViewModel extends ViewModel {
  DocumentVersionUploadViewModel(
    this._apiClient,
    this._sessionViewModel, {
    MultipartObjectUploader? multipartUploader,
  }) {
    _multipartUploader = multipartUploader ?? _defaultMultipartUploader;
  }

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  late final MultipartObjectUploader _multipartUploader;

  Future<bool> upload({
    required String documentId,
    required PlatformFile file,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return false;
    }

    if (file.bytes == null || file.bytes!.isEmpty) {
      setMessage('No se pudo leer el archivo seleccionado.');
      return false;
    }

    try {
      await run(() async {
        await _multipartUploader(
          path:
              '/api/tenants/${session.tenantId}/documents/$documentId/versions/upload',
          fields: const {},
          fileFieldName: 'file',
          bytes: file.bytes!,
          fileName: file.name,
        );
        setMessage('Nueva versión subida correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo subir la nueva versión del documento.';
  }

  Future<void> _defaultMultipartUploader({
    required String path,
    required Map<String, String> fields,
    required String fileFieldName,
    required List<int> bytes,
    required String fileName,
  }) {
    return postMultipartObjectWithClient(
      _apiClient,
      path: path,
      fields: fields,
      fileFieldName: fileFieldName,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
