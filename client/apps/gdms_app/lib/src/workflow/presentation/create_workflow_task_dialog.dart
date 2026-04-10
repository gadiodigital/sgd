import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../application/create_workflow_task_view_model.dart';

/// Captures the data required to create a simple workflow task.
class CreateWorkflowTaskDialog extends StatefulWidget {
  const CreateWorkflowTaskDialog({
    required this.apiClient,
    required this.sessionViewModel,
    required this.onCreated,
    this.initialDocumentId,
    super.key,
  });

  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;
  final Future<void> Function() onCreated;
  final String? initialDocumentId;

  @override
  State<CreateWorkflowTaskDialog> createState() =>
      _CreateWorkflowTaskDialogState();
}

class _CreateWorkflowTaskDialogState extends State<CreateWorkflowTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _dueDateController = TextEditingController();
  late final CreateWorkflowTaskViewModel _viewModel;
  String? _selectedDocumentId;
  String? _selectedAssignedUserId;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateWorkflowTaskViewModel(
      widget.apiClient,
      widget.sessionViewModel,
    );
    _selectedDocumentId = widget.initialDocumentId;
    _viewModel.loadDocuments();
    _viewModel.loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                    const GdmsPageHeader(
                      title: 'Crear tarea de workflow',
                      subtitle: 'Genera una aprobación o seguimiento sobre un documento.',
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel.message != null)
                      GdmsStatusBadge(
                        label: _viewModel.message!,
                        tone: _viewModel.state == ViewState.error
                            ? GdmsStatusTone.critical
                            : GdmsStatusTone.info,
                      ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedDocumentId),
                            initialValue: _selectedDocumentId,
                            decoration: const InputDecoration(labelText: 'Documento'),
                            items: _viewModel.documents
                                .map(
                                  (document) => DropdownMenuItem<String>(
                                    value: document.id,
                                    child: Text(document.title),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: _viewModel.isBusy || widget.initialDocumentId != null
                                ? null
                                : (value) => setState(() => _selectedDocumentId = value),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Seleccioná un documento.' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: 'Título de la tarea'),
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(labelText: 'Notas'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedAssignedUserId),
                            initialValue: _selectedAssignedUserId,
                            decoration: const InputDecoration(
                              labelText: 'Asignar a',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Sin asignar'),
                              ),
                              ..._viewModel.users.map(
                                (user) => DropdownMenuItem<String>(
                                  value: user.id,
                                  child: Text(user.fullName),
                                ),
                              ),
                            ],
                            onChanged: _viewModel.isBusy
                                ? null
                                : (value) => setState(
                                      () => _selectedAssignedUserId =
                                          value?.isEmpty == true ? null : value,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dueDateController,
                            decoration: const InputDecoration(
                              labelText: 'Vencimiento (AAAA-MM-DD)',
                            ),
                            validator: _validateDueDate,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _viewModel.isBusy ? null : _submit,
                              child: const Text('Crear tarea'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _viewModel.isBusy
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                        ],
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final documentId = _selectedDocumentId;
    if (documentId == null) {
      return;
    }

    final created = await _viewModel.createTask(
      documentId: documentId,
      title: _titleController.text.trim(),
      notes: _notesController.text,
      dueDate: _dueDateController.text,
      assignedToUserId: _selectedAssignedUserId,
    );
    if (!created || !mounted) {
      return;
    }

    await widget.onCreated();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _validateTitle(String? value) {
    if ((value?.trim().length ?? 0) < 3) {
      return 'Ingresá un título descriptivo.';
    }

    return null;
  }

  String? _validateDueDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    final isValid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
    return isValid ? null : 'Usá formato AAAA-MM-DD.';
  }
}
