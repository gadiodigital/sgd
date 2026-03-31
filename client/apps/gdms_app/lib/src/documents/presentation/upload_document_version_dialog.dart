import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../application/document_version_upload_view_model.dart';
import '../domain/scanned_document_file.dart';
import 'scan_document_dialog.dart';
import 'upload_document_source_actions.dart';
import 'upload_scan_summary_badge.dart';

/// Lets users upload a new immutable version for an existing document.
class UploadDocumentVersionDialog extends StatefulWidget {
  const UploadDocumentVersionDialog({
    required this.apiClient,
    required this.sessionViewModel,
    required this.documentId,
    required this.documentTitle,
    this.startWithScanner = false,
    this.scanDocumentLauncher,
    this.pickFileLauncher,
    this.viewModel,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;
  final String documentId;
  final String documentTitle;
  final bool startWithScanner;
  final Future<ScannedDocumentFile?> Function(BuildContext context)?
  scanDocumentLauncher;
  final Future<PlatformFile?> Function(BuildContext context)? pickFileLauncher;
  final DocumentVersionUploadViewModel? viewModel;

  @override
  State<UploadDocumentVersionDialog> createState() =>
      _UploadDocumentVersionDialogState();
}

class _UploadDocumentVersionDialogState
    extends State<UploadDocumentVersionDialog> {
  late final DocumentVersionUploadViewModel _viewModel;
  late final bool _ownsViewModel;
  PlatformFile? _selectedFile;
  ScannedDocumentFile? _selectedScan;

  bool get _supportsScannerIntegration =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ??
        DocumentVersionUploadViewModel(
          widget.apiClient,
          widget.sessionViewModel,
        );
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
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subir nueva versión',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.documentTitle),
                  const SizedBox(height: 20),
                  UploadDocumentSourceActions(
                    selectedFile: _selectedFile,
                    isBusy: _viewModel.isBusy,
                    supportsScannerIntegration: _supportsScannerIntegration,
                    onPickFile: _pickFile,
                    onScanDocument: _scanDocument,
                  ),
                  if (_selectedScan != null) ...[
                    const SizedBox(height: 16),
                    UploadScanSummaryBadge(scannedFile: _selectedScan!),
                  ],
                  if (_viewModel.message != null) ...[
                    const SizedBox(height: 16),
                    Text(_viewModel.message!),
                  ],
                  const SizedBox(height: 24),
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
                        onPressed: _selectedFile == null || _viewModel.isBusy
                            ? null
                            : _submit,
                        icon: _viewModel.isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.publish),
                        label: const Text('Subir versión'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
    if (!mounted || selectedFile == null) {
      return;
    }

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
    final selectedFile = _selectedFile;
    if (selectedFile == null) {
      return;
    }

    final uploaded = await _viewModel.upload(
      documentId: widget.documentId,
      file: selectedFile,
    );
    if (!mounted || !uploaded) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _selectFile(
    PlatformFile file, {
    required ScannedDocumentFile? scannedFile,
  }) {
    setState(() {
      _selectedFile = file;
      _selectedScan = scannedFile;
    });
  }
}
