import 'package:feature_documents/feature_documents.dart';
import 'package:feature_sector_legal/feature_sector_legal.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../documents/presentation/document_details_dialog.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_legal_dashboard_repository.dart';
import '../domain/case_file_document_reference.dart';

/// Shows a case file with the documents linked to it.
class CaseFileDetailsDialog extends StatefulWidget {
  const CaseFileDetailsDialog({
    required this.sessionViewModel,
    required this.caseFile,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final LegalCaseFileItem caseFile;

  @override
  State<CaseFileDetailsDialog> createState() => _CaseFileDetailsDialogState();
}

class _CaseFileDetailsDialogState extends State<CaseFileDetailsDialog> {
  late final ApiLegalDashboardRepository _repository;
  List<CaseFileDocumentReference> _documents = const [];
  bool _isBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _repository = ApiLegalDashboardRepository(
      widget.sessionViewModel.apiClient,
      widget.sessionViewModel,
    );
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.caseFile.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(widget.caseFile.subtitle),
              const SizedBox(height: 20),
              if (_message != null) Text(_message!),
              if (_isBusy)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_documents.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Este expediente todavía no tiene documentos vinculados.',
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
      final documents = await _repository.loadCaseFileDocuments(
        widget.caseFile.id,
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
            : 'No se pudieron cargar los documentos del expediente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _openDocument(CaseFileDocumentReference item) {
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
