import 'dart:async';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../application/document_upload_view_model.dart';
import '../domain/document_metadata_field.dart';
import '../domain/scanned_document_file.dart';
import '../domain/document_type_catalog_entry.dart';
import 'document_metadata_editor_support.dart';
import 'scan_document_dialog.dart';
import 'upload_document_form_section.dart';
import 'upload_scan_summary_badge.dart';

/// Displays a modal flow to pick a file and upload it to the backend.
class UploadDocumentDialog extends StatefulWidget {
  const UploadDocumentDialog({
    required this.apiClient,
    required this.sessionViewModel,
    required this.onUploaded,
    this.startWithScanner = false,
    this.onDocumentUploaded,
    this.scanDocumentLauncher,
    this.pickFileLauncher,
    this.viewModel,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;
  final Future<void> Function() onUploaded;
  final bool startWithScanner;
  final Future<bool> Function(String documentId)? onDocumentUploaded;
  final Future<ScannedDocumentFile?> Function(BuildContext context)?
  scanDocumentLauncher;
  final Future<PlatformFile?> Function(BuildContext context)? pickFileLauncher;
  final DocumentUploadViewModel? viewModel;
  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final Map<String, TextEditingController> _metadataControllers = {};
  final Map<String, String?> _booleanMetadataValues = {};
  late final DocumentUploadViewModel _viewModel;
  late final bool _ownsViewModel;
  PlatformFile? _selectedFile;
  ScannedDocumentFile? _selectedScan;
  String? _selectedDocumentTypeCode;

  bool get _supportsScannerIntegration =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ??
        DocumentUploadViewModel(widget.apiClient, widget.sessionViewModel);
    unawaited(_loadCatalog());
    if (widget.startWithScanner && _supportsScannerIntegration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_scanDocument());
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _metadataControllers.values) {
      controller.dispose();
    }
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDocumentType = _selectedDocumentType;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GdmsPageHeader(
                      title: 'Subir documento',
                      subtitle:
                          'Carga un binario real al backend y registra su primera '
                          'version documental con metadatos validados.',
                    ),
                    const SizedBox(height: 18),
                    if (_viewModel.documentTypes.isEmpty && _viewModel.isBusy)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      UploadDocumentFormSection(
                        formKey: _formKey,
                        documentTypes: _viewModel.documentTypes.toList(),
                        selectedDocumentTypeCode: _selectedDocumentTypeCode,
                        selectedDocumentType: selectedDocumentType,
                        titleController: _titleController,
                        metadataControllers: _metadataControllers,
                        booleanMetadataValues: _booleanMetadataValues,
                        selectedFile: _selectedFile,
                        isBusy: _viewModel.isBusy,
                        supportsScannerIntegration: _supportsScannerIntegration,
                        onDocumentTypeChanged: _selectDocumentType,
                        onBooleanChanged: _updateBooleanMetadata,
                        onPickFile: _pickFile,
                        onScanDocument: _scanDocument,
                      ),
                    if (_selectedScan != null) ...[
                      const SizedBox(height: 14),
                      UploadScanSummaryBadge(scannedFile: _selectedScan!),
                    ],
                    if (_viewModel.message != null) ...[
                      const SizedBox(height: 14),
                      GdmsStatusBadge(
                        label: _viewModel.message!,
                        tone: _viewModel.state == ViewState.error
                            ? GdmsStatusTone.critical
                            : GdmsStatusTone.info,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _viewModel.isBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _viewModel.isBusy ? null : _submit,
                          icon: _viewModel.isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: const Text('Subir'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  DocumentTypeCatalogEntry? get _selectedDocumentType =>
      _viewModel.findDocumentType(_selectedDocumentTypeCode);

  Future<void> _loadCatalog() async {
    await _viewModel.loadDocumentTypes();
    if (!mounted || _viewModel.documentTypes.isEmpty) return;
    setState(() {
      _selectedDocumentTypeCode = _viewModel.documentTypes.first.code;
      _resetMetadataInputs();
    });
  }

  void _selectDocumentType(String? value) {
    setState(() {
      _selectedDocumentTypeCode = value;
      _resetMetadataInputs();
    });
  }

  Future<void> _pickFile() async {
    PlatformFile? selectedFile;
    final launcher = widget.pickFileLauncher;
    if (launcher != null) {
      selectedFile = await launcher(context);
    } else {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        selectedFile = result.files.single;
      }
    }
    if (!mounted || selectedFile == null) return;
    _selectFile(selectedFile, scannedFile: null);
  }

  Future<void> _scanDocument() async {
    ScannedDocumentFile? scannedFile;
    final launcher = widget.scanDocumentLauncher;
    if (launcher != null) {
      scannedFile = await launcher(context);
    } else {
      scannedFile = await showDialog<ScannedDocumentFile>(
        context: context,
        builder: (context) => const ScanDocumentDialog(),
      );
    }
    if (!mounted || scannedFile == null) {
      return;
    }
    _selectFile(
      PlatformFile(
        name: scannedFile.fileName,
        size: scannedFile.bytes.length,
        bytes: Uint8List.fromList(scannedFile.bytes),
      ),
      scannedFile: scannedFile,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedDocumentType = _selectedDocumentType;
    if (selectedDocumentType == null) {
      _viewModel.setMessage('Selecciona el tipo documental antes de subir.');
      return;
    }

    final selectedFile = _selectedFile;
    if (selectedFile == null) {
      _viewModel.setMessage('Selecciona un archivo antes de subir.');
      return;
    }

    final uploadResult = await _viewModel.uploadWithResult(
      documentTypeCode: selectedDocumentType.code,
      title: _titleController.text,
      file: selectedFile,
      metadata: DocumentMetadataEditorSupport.buildPayload(
        selectedDocumentType.metadataFields,
        _metadataControllers,
        _booleanMetadataValues,
      ),
    );
    if (!mounted || !uploadResult.succeeded) return;

    final documentUploaded = widget.onDocumentUploaded;
    if (documentUploaded != null) {
      final documentId = uploadResult.documentId;
      if (documentId == null || documentId.trim().isEmpty) {
        _viewModel.setMessage(
          'El documento se subio, pero la API no devolvio su identificador.',
        );
        return;
      }

      final linked = await documentUploaded(documentId);
      if (!mounted || !linked) {
        if (mounted) {
          _viewModel.setMessage(
            'El documento se subio, pero no se pudo vincular al nodo seleccionado.',
          );
        }
        return;
      }
    }

    await widget.onUploaded();
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  void _resetMetadataInputs() {
    final selectedDocumentType = _selectedDocumentType;
    DocumentMetadataEditorSupport.syncEditors(
      fields:
          selectedDocumentType?.metadataFields ??
          const <DocumentMetadataField>[],
      metadata: const <String, Object?>{},
      controllers: _metadataControllers,
      booleanValues: _booleanMetadataValues,
    );
  }

  void _updateBooleanMetadata(String key, String? value) {
    setState(() {
      _booleanMetadataValues[key] = value;
    });
  }

  void _selectFile(PlatformFile file, {ScannedDocumentFile? scannedFile}) {
    setState(() {
      _selectedFile = file;
      _selectedScan = scannedFile;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = file.name.split('.').first;
      }
    });
  }
}
