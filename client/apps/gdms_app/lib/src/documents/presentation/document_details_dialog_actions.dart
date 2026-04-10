part of 'document_details_dialog.dart';

extension _DocumentDetailsDialogActions on _DocumentDetailsDialogState {
  Future<void> _download() => _viewModel.download(
    documentId: widget.document.id,
    fallbackFileName: widget.document.title,
  );

  Future<void> _downloadEvidencePackage() => _viewModel.downloadEvidencePackage(
    documentId: widget.document.id,
    fallbackFileName: '${widget.document.title}-evidence-package.json',
  );

  Future<void> _downloadVersion(DocumentVersionItem version) =>
      _viewModel.downloadVersion(
        documentId: widget.document.id,
        versionNumber: version.versionNumber,
        fallbackFileName: '${widget.document.title}-v${version.versionNumber}',
      );

  Future<void> _openLinkToCaseDialog() => showDialog<void>(
    context: context,
    builder: (_) => LinkDocumentToCaseDialog(
      sessionViewModel: widget.sessionViewModel,
      document: widget.document,
    ),
  );

  Future<void> _openVersionUploadDialog() async {
    await _openVersionDialog();
  }

  Future<void> _openScannedVersionUploadDialog() async {
    await _openVersionDialog(startWithScanner: true);
  }

  Future<void> _openVersionDialog({bool startWithScanner = false}) async {
    final uploaded = await showDialog<bool>(
      context: context,
      builder: (_) => UploadDocumentVersionDialog(
        apiClient: widget.apiClient,
        sessionViewModel: widget.sessionViewModel,
        documentId: widget.document.id,
        documentTitle: widget.document.title,
        startWithScanner: startWithScanner,
      ),
    );
    if (!mounted || uploaded != true) {
      return;
    }

    await _loadDetails();
  }

  Future<void> _openManageAccessDialog() => showDialog<void>(
    context: context,
    builder: (_) => ManageDocumentAccessDialog(
      apiClient: widget.apiClient,
      sessionViewModel: widget.sessionViewModel,
      documentId: widget.document.id,
      documentTitle: widget.document.title,
    ),
  );

  Future<void> _openCreateWorkflowTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateWorkflowTaskDialog(
        apiClient: widget.apiClient,
        sessionViewModel: widget.sessionViewModel,
        initialDocumentId: widget.document.id,
        onCreated: () => _workflowViewModel.load(widget.document.id),
      ),
    );
    if (!mounted || created != true) {
      return;
    }

    await _workflowViewModel.load(widget.document.id);
  }

  Future<void> _openCreateSignatureDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateSignatureRequestDialog(
        viewModel: CreateSignatureRequestViewModel(
          sessionViewModel: widget.sessionViewModel,
        ),
        initialDocumentId: widget.document.id,
        initialDocumentTitle: widget.document.title,
      ),
    );
    if (!mounted || created != true) {
      return;
    }

    await _signaturesViewModel.load(widget.document.id);
  }

  Future<void> _loadDetails() async {
    await _viewModel.load(widget.document.id, widget.document.typeLabel);
    await _signaturesViewModel.load(widget.document.id);
    await _workflowViewModel.load(widget.document.id);
    if (!mounted) return;
    _syncEditors();
  }

  Widget _buildEditor() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DocumentMetadataFieldsSection(
            fields: _viewModel.metadataFields.toList(growable: false),
            controllers: _metadataControllers,
            booleanValues: _booleanMetadataValues,
            onBooleanChanged: _updateBooleanMetadata,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _viewModel.isBusy ? null : _saveMetadata,
              icon: const Icon(Icons.save),
              label: const Text('Guardar metadatos'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSummary() => _viewModel.metadata.isEmpty
      ? const Text('Sin metadatos registrados.')
      : Column(
          children: _viewModel.metadata.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(entry.key),
                    subtitle: Text('${entry.value}'),
                  ),
                ),
              )
              .toList(growable: false),
        );

  void _syncEditors() => DocumentMetadataEditorSupport.syncEditors(
    fields: _viewModel.metadataFields,
    metadata: _viewModel.metadata,
    controllers: _metadataControllers,
    booleanValues: _booleanMetadataValues,
  );

  Future<void> _completeWorkflowTask(WorkflowTaskItem task) =>
      _workflowViewModel.completeTask(task.id, widget.document.id);

  Future<void> _completeSignatureRequest(SignatureEnvelopeItem item) =>
      _signaturesViewModel.completeSignature(item.id, widget.document.id);

  Future<void> _cancelSignatureRequest(SignatureEnvelopeItem item) async {
    var reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isReasonValid = reason.trim().length >= 5;
          return AlertDialog(
            title: const Text('Cancelar solicitud de firma'),
            content: TextField(
              minLines: 2,
              maxLines: 4,
              onChanged: (value) => setDialogState(() => reason = value),
              decoration: InputDecoration(
                labelText: 'Motivo',
                hintText: 'Describi el motivo de cancelacion',
                helperText: isReasonValid
                    ? 'Motivo listo para cancelar.'
                    : 'Minimo 5 caracteres.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: isReasonValid
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: const Text('Cancelar solicitud'),
              ),
            ],
          );
        },
      ),
    );
    final trimmedReason = reason.trim();
    if (confirmed != true) {
      return;
    }

    await _signaturesViewModel.cancelSignature(
      item.id,
      widget.document.id,
      trimmedReason,
    );
  }
}
