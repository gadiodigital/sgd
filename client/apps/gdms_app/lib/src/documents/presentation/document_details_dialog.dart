import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_documents/feature_documents.dart';
import 'package:feature_signature/feature_signature.dart';
import 'package:feature_workflow/feature_workflow.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../../legal/presentation/link_document_to_case_dialog.dart';
import '../../signature/application/create_signature_request_view_model.dart';
import '../../signature/presentation/create_signature_request_dialog.dart';
import '../../workflow/presentation/create_workflow_task_dialog.dart';
import '../application/document_details_view_model.dart';
import '../application/document_signatures_view_model.dart';
import '../application/document_workflow_tasks_view_model.dart';
import '../domain/document_version_item.dart';
import 'document_details_actions_bar.dart';
import 'document_audit_trail_section.dart';
import 'document_metadata_editor_support.dart';
import 'document_metadata_fields_section.dart';
import 'document_signature_requests_section.dart';
import 'manage_document_access_dialog.dart';
import 'document_workflow_tasks_section.dart';
import 'document_version_history_section.dart';
import 'upload_document_version_dialog.dart';

part 'document_details_dialog_actions.dart';

/// Shows the metadata and operational summary of a selected document.
class DocumentDetailsDialog extends StatefulWidget {
  const DocumentDetailsDialog({
    required this.apiClient,
    required this.sessionViewModel,
    required this.document,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;
  final DocumentRecord document;

  @override
  State<DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<DocumentDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _metadataControllers = {};
  final Map<String, String?> _booleanMetadataValues = {};
  late final DocumentDetailsViewModel _viewModel;
  late final DocumentSignaturesViewModel _signaturesViewModel;
  late final DocumentWorkflowTasksViewModel _workflowViewModel;
  bool _isEditing = false;

  bool get _supportsScannerIntegration =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _viewModel = DocumentDetailsViewModel(
      widget.apiClient,
      widget.sessionViewModel,
    );
    _signaturesViewModel = DocumentSignaturesViewModel(widget.sessionViewModel);
    _workflowViewModel = DocumentWorkflowTasksViewModel(
      widget.apiClient,
      widget.sessionViewModel,
    );
    unawaited(_loadDetails());
  }

  @override
  void dispose() {
    for (final controller in _metadataControllers.values) {
      controller.dispose();
    }
    _viewModel.dispose();
    _signaturesViewModel.dispose();
    _workflowViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GdmsPageHeader(
                      title: widget.document.title,
                      subtitle:
                          '${widget.document.typeLabel} · '
                          '${widget.document.updatedAtLabel}',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GdmsStatusBadge(
                          label: widget.document.statusLabel,
                          tone: GdmsStatusTone.info,
                        ),
                        GdmsStatusBadge(
                          label: widget.document.classificationLabel,
                          tone: widget.document.onLegalHold
                              ? GdmsStatusTone.warning
                              : GdmsStatusTone.neutral,
                        ),
                        GdmsStatusBadge(
                          label: widget.document.ownerLabel,
                          tone: GdmsStatusTone.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DocumentDetailsActionsBar(
                      isBusy: _viewModel.isBusy,
                      hasMetadataFields: _viewModel.metadataFields.isNotEmpty,
                      isEditing: _isEditing,
                      supportsScannerIntegration: _supportsScannerIntegration,
                      onDownloadRequested: _download,
                      onVersionUploadRequested: _openVersionUploadDialog,
                      onScanVersionRequested: _openScannedVersionUploadDialog,
                      onEvidenceExportRequested: _downloadEvidencePackage,
                      onLinkToCaseRequested: _openLinkToCaseDialog,
                      onManageAccessRequested: _openManageAccessDialog,
                      onEditToggleRequested: _isEditing
                          ? _cancelEditing
                          : _startEditing,
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel.isBusy && _viewModel.metadata.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      GdmsSectionCard(
                        title: 'Metadatos',
                        subtitle: _viewModel.message,
                        child: _isEditing
                            ? _buildEditor()
                            : _buildMetadataSummary(),
                      ),
                    const SizedBox(height: 16),
                    DocumentVersionHistorySection(
                      versions: _viewModel.versions.toList(growable: false),
                      onDownloadRequested: _downloadVersion,
                    ),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: _signaturesViewModel,
                      builder: (context, _) => DocumentSignatureRequestsSection(
                        envelopes: _signaturesViewModel.envelopes.toList(
                          growable: false,
                        ),
                        message: _signaturesViewModel.message,
                        isBusy: _signaturesViewModel.isBusy,
                        onCreateRequested: _openCreateSignatureDialog,
                        onCompleteRequested: _completeSignatureRequest,
                        onCancelRequested: _cancelSignatureRequest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: _workflowViewModel,
                      builder: (context, _) => DocumentWorkflowTasksSection(
                        tasks: _workflowViewModel.tasks.toList(growable: false),
                        message: _workflowViewModel.message,
                        isBusy: _workflowViewModel.isBusy,
                        onCreateRequested: _openCreateWorkflowTaskDialog,
                        onCompleteRequested: _completeWorkflowTask,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DocumentAuditTrailSection(
                      events: _viewModel.auditEvents.toList(growable: false),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
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

  Future<void> _saveMetadata() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = await _viewModel.updateMetadata(
      documentId: widget.document.id,
      metadata: DocumentMetadataEditorSupport.buildPayload(
        _viewModel.metadataFields,
        _metadataControllers,
        _booleanMetadataValues,
      ),
    );
    if (!mounted || !updated) return;
    setState(() {
      _isEditing = false;
      _syncEditors();
    });
  }

  void _startEditing() => setState(() {
    _isEditing = true;
    _syncEditors();
  });

  void _cancelEditing() => setState(() {
    _isEditing = false;
    _syncEditors();
  });

  void _updateBooleanMetadata(String key, String? value) =>
      setState(() => _booleanMetadataValues[key] = value);
}
