import 'package:feature_documents/feature_documents.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_corporate_dashboard_repository.dart';
import '../../infrastructure/repositories/api_documents_repository.dart';

/// Lets the user attach an existing document to a corporate record file.
class LinkDocumentToCorporateRecordFileDialog extends StatefulWidget {
  const LinkDocumentToCorporateRecordFileDialog({
    required this.sessionViewModel,
    required this.corporateRecordFileId,
    required this.onLinked,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final String corporateRecordFileId;
  final Future<void> Function() onLinked;

  @override
  State<LinkDocumentToCorporateRecordFileDialog> createState() =>
      _LinkDocumentToCorporateRecordFileDialogState();
}

class _LinkDocumentToCorporateRecordFileDialogState
    extends State<LinkDocumentToCorporateRecordFileDialog> {
  List<DocumentRecord> _documents = const [];
  String? _selectedDocumentId;
  bool _isBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vincular documento',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (_message != null) ...[
                Text(_message!),
                const SizedBox(height: 12),
              ],
              if (_isBusy && _documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedDocumentId),
                  initialValue: _selectedDocumentId,
                  decoration: const InputDecoration(labelText: 'Documento'),
                  items: _documents
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.title),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isBusy
                      ? null
                      : (value) => setState(() => _selectedDocumentId = value),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed:
                        _isBusy || _selectedDocumentId == null ? null : _submit,
                    child: const Text('Vincular'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final repository = ApiDocumentsRepository(
        widget.sessionViewModel.apiClient,
        widget.sessionViewModel,
      );
      final documents = await repository.loadOverview();
      if (!mounted) {
        return;
      }
      setState(() {
        _documents = documents.recentDocuments;
        _selectedDocumentId =
            _documents.isEmpty ? null : _documents.first.id;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudieron cargar los documentos.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _submit() async {
    final documentId = _selectedDocumentId;
    if (documentId == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final repository = ApiCorporateDashboardRepository(
        widget.sessionViewModel.apiClient,
        widget.sessionViewModel,
      );
      await repository.attachDocumentToCorporateRecordFile(
        corporateRecordFileId: widget.corporateRecordFileId,
        documentId: documentId,
      );
      await widget.onLinked();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudo vincular el documento.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
