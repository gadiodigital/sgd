import 'dart:collection';

import 'package:core/core.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../../infrastructure/api/downloaded_binary_file.dart';
import '../domain/document_audit_event.dart';
import '../domain/document_metadata_field.dart';
import '../domain/document_type_catalog_entry.dart';
import '../domain/document_version_item.dart';

/// Loads the current metadata snapshot of a document from the GDMS API.
final class DocumentDetailsViewModel extends ViewModel {
  DocumentDetailsViewModel(this._apiClient, this._sessionViewModel);

  final GdmsApiClient _apiClient;
  final AppSessionViewModel _sessionViewModel;
  List<DocumentAuditEvent> _auditEvents = const [];
  Map<String, Object?> _metadata = const {};
  List<DocumentMetadataField> _metadataFields = const [];
  List<DocumentVersionItem> _versions = const [];

  UnmodifiableListView<DocumentAuditEvent> get auditEvents =>
      UnmodifiableListView(_auditEvents);
  UnmodifiableMapView<String, Object?> get metadata =>
      UnmodifiableMapView(_metadata);
  UnmodifiableListView<DocumentMetadataField> get metadataFields =>
      UnmodifiableListView(_metadataFields);
  UnmodifiableListView<DocumentVersionItem> get versions =>
      UnmodifiableListView(_versions);

  Future<void> load(String documentId, String documentTypeCode) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return;
    }

    try {
      await run(() async {
        final metadataResponse = await _apiClient.getObject(
          '/api/tenants/${session.tenantId}/documents/$documentId/metadata',
        );
        final catalogResponse = await _apiClient.getList(
          '/api/tenants/${session.tenantId}/document-types',
        );
        final auditResponse = await _apiClient.getList(
          '/api/organization/documents/$documentId/audit-events?limit=20',
        );
        final versionsResponse = await _apiClient.getList(
          '/api/tenants/${session.tenantId}/documents/$documentId/versions',
        );
        _metadata = _toMap(metadataResponse['metadata']);
        _metadataFields = _resolveMetadataFields(
          catalogResponse.cast<Map<String, dynamic>>(),
          documentTypeCode,
        );
        _versions = versionsResponse
            .cast<Map<String, dynamic>>()
            .map(_mapVersion)
            .toList(growable: false);
        _auditEvents = auditResponse
            .cast<Map<String, dynamic>>()
            .map(_mapAuditEvent)
            .toList(growable: false);
        setMessage(
          _metadata.isEmpty
              ? 'El documento no tiene metadatos registrados.'
              : 'Metadatos cargados desde la API.',
        );
      });
    } catch (error) {
      setMessage(_mapError(error));
    }
  }

  Future<bool> download({
    required String documentId,
    required String fallbackFileName,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return false;
    }

    try {
      await run(() async {
        final binary = await _apiClient.getBinary(
          '/api/tenants/${session.tenantId}/documents/$documentId/download',
          fallbackFileName: fallbackFileName,
        );
        final savedPath = await _saveBinary(binary);
        setMessage(
          savedPath == null
              ? 'Descarga cancelada por el usuario.'
              : 'Documento descargado en $savedPath',
        );
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> downloadVersion({
    required String documentId,
    required int versionNumber,
    required String fallbackFileName,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return false;
    }

    try {
      await run(() async {
        final binary = await _apiClient.getBinary(
          '/api/tenants/${session.tenantId}/documents/$documentId/versions/$versionNumber/download',
          fallbackFileName: fallbackFileName,
        );
        final savedPath = await _saveBinary(binary);
        setMessage(
          savedPath == null
              ? 'Descarga cancelada por el usuario.'
              : 'Versión descargada en $savedPath',
        );
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> downloadEvidencePackage({
    required String documentId,
    required String fallbackFileName,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return false;
    }

    try {
      await run(() async {
        final binary = await _apiClient.getBinary(
          '/api/tenants/${session.tenantId}/documents/$documentId/evidence-package',
          fallbackFileName: fallbackFileName,
        );
        final savedPath = await _saveBinary(binary);
        setMessage(
          savedPath == null
              ? 'Exportación cancelada por el usuario.'
              : 'Paquete de evidencia descargado en $savedPath',
        );
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Future<bool> updateMetadata({
    required String documentId,
    required Map<String, Object?> metadata,
  }) async {
    final session = _sessionViewModel.session;
    if (session == null) {
      setMessage('No hay una sesion autenticada activa.');
      return false;
    }

    try {
      await run(() async {
        final response = await _apiClient.putObject(
          '/api/tenants/${session.tenantId}/documents/$documentId/metadata',
          {'metadata': _normalizeMetadata(metadata)},
        );
        _metadata = _toMap(response['metadata']);
        setMessage('Metadatos actualizados correctamente.');
      });
      return true;
    } catch (error) {
      setMessage(_mapError(error));
      return false;
    }
  }

  Map<String, Object?> _toMap(Object? rawValue) {
    if (rawValue is Map<String, dynamic>) {
      return rawValue.map(MapEntry.new);
    }

    if (rawValue is Map) {
      return rawValue.map((key, value) => MapEntry('$key', value));
    }

    return const <String, Object?>{};
  }

  List<DocumentMetadataField> _resolveMetadataFields(
    List<Map<String, dynamic>> catalogResponse,
    String documentTypeCode,
  ) {
    for (final item in catalogResponse) {
      final documentType = DocumentTypeCatalogEntry.fromJson(item);
      if (documentType.code == documentTypeCode) {
        return documentType.metadataFields;
      }
    }

    return const [];
  }

  Map<String, Object?> _normalizeMetadata(Map<String, Object?> metadata) {
    final normalized = <String, Object?>{};
    for (final entry in metadata.entries) {
      final value = entry.value;
      if (value is String) {
        final text = value.trim();
        if (text.isNotEmpty) {
          normalized[entry.key] = text;
        }
        continue;
      }

      if (value != null) {
        normalized[entry.key] = value;
      }
    }

    return normalized;
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la operación documental.';
  }

  DocumentAuditEvent _mapAuditEvent(Map<String, dynamic> json) {
    final occurredAt = DateTime.tryParse(
      json['occurredAtUtc'] as String? ?? '',
    )?.toUtc();
    return DocumentAuditEvent(
      eventType: json['eventType'] as String? ?? 'UNKNOWN',
      severity: json['severity'] as String? ?? 'INFO',
      occurredAtLabel: _formatOccurredAt(occurredAt),
    );
  }

  String _formatOccurredAt(DateTime? value) {
    if (value == null) {
      return 'Sin fecha';
    }

    final localValue = value.toLocal();
    return '${_twoDigits(localValue.day)}/${_twoDigits(localValue.month)}/${localValue.year} '
        '${_twoDigits(localValue.hour)}:${_twoDigits(localValue.minute)}';
  }

  DocumentVersionItem _mapVersion(Map<String, dynamic> json) {
    final uploadedAt = DateTime.tryParse(
      json['uploadedAtUtc'] as String? ?? '',
    )?.toUtc();
    final fileHash = json['fileHashSha256'] as String? ?? '';
    return DocumentVersionItem(
      versionNumber: json['versionNumber'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      fileHashPreview: fileHash.length <= 12
          ? fileHash
          : fileHash.substring(0, 12),
      uploadedAtLabel: _formatOccurredAt(uploadedAt),
    );
  }

  String _twoDigits(int number) => number.toString().padLeft(2, '0');

  Future<String?> _saveBinary(DownloadedBinaryFile binary) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Guardar documento',
      fileName: binary.fileName,
      bytes: binary.bytes,
    );
  }
}
