import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_corporate_dashboard_repository.dart';

/// Collects the data required to create a new corporate record file.
class CreateCorporateRecordFileDialog extends StatefulWidget {
  const CreateCorporateRecordFileDialog({
    required this.sessionViewModel,
    required this.onCreated,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final Future<void> Function() onCreated;

  @override
  State<CreateCorporateRecordFileDialog> createState() =>
      _CreateCorporateRecordFileDialogState();
}

class _CreateCorporateRecordFileDialogState
    extends State<CreateCorporateRecordFileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'CONTRACTS');
  final _ownerAreaController = TextEditingController(text: 'LEGAL');
  bool _isBusy = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _ownerAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear legajo corporativo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: _validateShortText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: _validateShortText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: _validateShortText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerAreaController,
                  decoration: const InputDecoration(labelText: 'Área responsable'),
                  validator: _validateShortText,
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
                    FilledButton(
                      onPressed: _isBusy ? null : _submit,
                      child: const Text('Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateShortText(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.length < 3 ? 'Ingresá un valor válido.' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
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
      await repository.createCorporateRecordFile(
        code: _codeController.text,
        title: _titleController.text,
        category: _categoryController.text,
        ownerArea: _ownerAreaController.text,
      );
      await widget.onCreated();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _message = error is ApiException
            ? error.message
            : 'No se pudo crear el legajo corporativo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
