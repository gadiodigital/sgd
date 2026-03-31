import 'package:feature_documents/feature_documents.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../documents/presentation/document_details_dialog.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_corporate_dashboard_repository.dart';
import '../domain/corporate_record_file_document_reference.dart';
import '../domain/corporate_record_file_reference.dart';
import 'link_document_to_corporate_record_file_dialog.dart';

/// Shows a corporate record file with the documents linked to it.
class CorporateRecordFileDetailsDialog extends StatefulWidget {
  const CorporateRecordFileDetailsDialog({
    required this.sessionViewModel,
    required this.recordFile,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final CorporateRecordFileReference recordFile;

  @override
  State<CorporateRecordFileDetailsDialog> createState() =>
      _CorporateRecordFileDetailsDialogState();
}

class _CorporateRecordFileDetailsDialogState
    extends State<CorporateRecordFileDetailsDialog> {
  late final ApiCorporateDashboardRepository _repository;
  List<CorporateRecordFileDocumentReference> _documents = const [];
  bool _isBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _repository = ApiCorporateDashboardRepository(
      widget.sessionViewModel.apiClient,
      widget.sessionViewModel,
    );
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.recordFile.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.recordFile.code} · ${widget.recordFile.category} · ${widget.recordFile.ownerArea}',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _openLinkDialog,
                  icon: const Icon(Icons.attach_file_outlined),
                  label: const Text('Vincular documento'),
                ),
              ),
              const SizedBox(height: 16),
              if (_message != null) Text(_message!),
              if (_isBusy)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_documents.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Este legajo todavía no tiene documentos vinculados.',
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _documents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _documents[index];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.documentTypeCode} · ${_formatLinkedAt(item.linkedAtUtc)}',
                        ),
                        trailing: Text(item.status),
                        onTap: () => _openDocument(item),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
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
      final documents = await _repository.loadCorporateRecordFileDocuments(
        widget.recordFile.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _documents = documents);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudieron cargar los documentos del legajo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _openLinkDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => LinkDocumentToCorporateRecordFileDialog(
        sessionViewModel: widget.sessionViewModel,
        corporateRecordFileId: widget.recordFile.id,
        onLinked: _loadDocuments,
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadDocuments();
  }

  Future<void> _openDocument(CorporateRecordFileDocumentReference item) {
    return showDialog<void>(
      context: context,
      builder: (_) => DocumentDetailsDialog(
        apiClient: widget.sessionViewModel.apiClient,
        sessionViewModel: widget.sessionViewModel,
        document: DocumentRecord(
          id: item.documentId,
          title: item.title,
          typeLabel: item.documentTypeCode,
          classificationLabel: item.documentTypeCode,
          statusLabel: item.status,
          ownerLabel: widget.sessionViewModel.session?.tenantCode ?? 'GDMS',
          updatedAtLabel: _formatLinkedAt(item.linkedAtUtc),
          onLegalHold: false,
        ),
      ),
    );
  }

  String _formatLinkedAt(DateTime? value) {
    if (value == null) {
      return 'Sin fecha';
    }

    final localValue = value.toLocal();
    return '${localValue.day.toString().padLeft(2, '0')}/'
        '${localValue.month.toString().padLeft(2, '0')}/${localValue.year}';
  }
}
