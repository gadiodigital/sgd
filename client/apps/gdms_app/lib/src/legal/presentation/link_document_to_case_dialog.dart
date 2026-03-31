import 'package:flutter/material.dart';
import 'package:feature_documents/feature_documents.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_legal_dashboard_repository.dart';
import '../domain/case_file_reference.dart';

/// Links an existing document to a selected case file.
class LinkDocumentToCaseDialog extends StatefulWidget {
  const LinkDocumentToCaseDialog({
    required this.sessionViewModel,
    required this.document,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final DocumentRecord document;

  @override
  State<LinkDocumentToCaseDialog> createState() =>
      _LinkDocumentToCaseDialogState();
}

class _LinkDocumentToCaseDialogState extends State<LinkDocumentToCaseDialog> {
  late final ApiLegalDashboardRepository _repository;
  List<CaseFileReference> _caseFiles = const [];
  String? _selectedCaseFileId;
  String? _message;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _repository = ApiLegalDashboardRepository(
      widget.sessionViewModel.apiClient,
      widget.sessionViewModel,
    );
    _loadCaseFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vincular a expediente',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(widget.document.title),
              const SizedBox(height: 20),
              if (_isBusy && _caseFiles.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (_caseFiles.isEmpty)
                const Text('No hay expedientes disponibles para vincular.')
              else
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCaseFileId),
                  initialValue: _selectedCaseFileId,
                  decoration: const InputDecoration(
                    labelText: 'Expediente',
                    border: OutlineInputBorder(),
                  ),
                  items: _caseFiles
                      .map(
                        (caseFile) => DropdownMenuItem(
                          value: caseFile.id,
                          child: Text(
                            '${caseFile.code} · ${caseFile.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isBusy
                      ? null
                      : (value) => setState(() => _selectedCaseFileId = value),
                ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!),
              ],
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
                  FilledButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('Vincular'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit => !_isBusy && _selectedCaseFileId != null;

  Future<void> _loadCaseFiles() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final caseFiles = await _repository.loadCaseFiles();
      if (!mounted) {
        return;
      }
      setState(() {
        _caseFiles = caseFiles;
        _selectedCaseFileId = caseFiles.isEmpty ? null : caseFiles.first.id;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudieron cargar los expedientes.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _submit() async {
    final caseFileId = _selectedCaseFileId;
    if (caseFileId == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await _repository.attachDocumentToCaseFile(
        caseFileId: caseFileId,
        documentId: widget.document.id,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudo vincular el documento al expediente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
