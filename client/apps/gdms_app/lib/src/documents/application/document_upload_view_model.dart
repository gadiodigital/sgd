import 'dart:collection';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../domain/document_type_catalog_entry.dart';
import 'upload_multipart_support.dart';

/// Coordinates multipart document uploads against the GDMS API.
final class DocumentUploadViewModel extends ViewModel {
  DocumentUploadViewModel(
    this._apiClient,
    this._sessionViewModel, {
    MultipartObjectUploader? multipartUploader,
  }) {
    _multipartUploader = multipartUploader ?? _defaultMultipartUploader;
  }

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  late final MultipartObjectUploader _multipartUploader;
  List<DocumentTypeCatalogEntry> _documentTypes = const [];

  UnmodifiableListView<DocumentTypeCatalogEntry> get documentTypes =>
      UnmodifiableListView(_documentTypes);

  Future<void> loadDocumentTypes() async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return;
    }

    try {
      await run(() async {
        final response = await _apiClient.getList(
          '/api/tenants/${session.tenantId}/document-types',
        );
        _documentTypes = response
            .cast<Map<String, dynamic>>()
            .map(DocumentTypeCatalogEntry.fromJson)
            .where((item) => item.isActive)
            .toList(growable: false);
        setMessage(
          _documentTypes.isEmpty
              ? 'No hay tipos documentales activos para este tenant.'
              : 'Selecciona el tipo documental y completa sus metadatos.',
        );
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  DocumentTypeCatalogEntry? findDocumentType(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }

    for (final documentType in _documentTypes) {
      if (documentType.code == code) {
        return documentType;
      }
    }

    return null;
  }

  Future<bool> upload({
    required String documentTypeCode,
    required String? title,
    required PlatformFile file,
    Map<String, Object?> metadata = const <String, Object?>{},
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
        final fields = <String, String>{
          'documentTypeCode': documentTypeCode.trim(),
        };
        if (title != null && title.trim().isNotEmpty) {
          fields['title'] = title.trim();
        }
        final normalizedMetadata = _normalizeMetadata(metadata);
        if (normalizedMetadata.isNotEmpty) {
          fields['metadataJson'] = jsonEncode(normalizedMetadata);
        }

        await _multipartUploader(
          path: '/api/tenants/${session.tenantId}/documents/upload',
          fields: fields,
          fileFieldName: 'file',
          bytes: file.bytes!,
          fileName: file.name,
        );

        setMessage('Documento subido correctamente.');
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

    return 'No se pudo subir el documento al backend.';
  }

  Map<String, Object?> _normalizeMetadata(Map<String, Object?> metadata) {
    final normalized = <String, Object?>{};
    for (final entry in metadata.entries) {
      if (entry.value is String) {
        final text = (entry.value as String).trim();
        if (text.isNotEmpty) {
          normalized[entry.key] = text;
        }
        continue;
      }

      if (entry.value != null) {
        normalized[entry.key] = entry.value;
      }
    }

    return normalized;
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
