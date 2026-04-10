import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_legal_dashboard_repository.dart';

/// Collects the data required to create a new case file.
class CreateCaseFileDialog extends StatefulWidget {
  const CreateCaseFileDialog({
    required this.sessionViewModel,
    required this.onCreated,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final Future<void> Function() onCreated;

  @override
  State<CreateCaseFileDialog> createState() => _CreateCaseFileDialogState();
}

class _CreateCaseFileDialogState extends State<CreateCaseFileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'JURIDICO');
  bool _isBusy = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear expediente',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    return normalized.length < 3
                        ? 'Ingresá un código válido.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    return normalized.length < 3
                        ? 'Ingresá un título válido.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    return normalized.isEmpty ? 'Ingresá una categoría.' : null;
                  },
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final repository = ApiLegalDashboardRepository(
        widget.sessionViewModel.apiClient,
        widget.sessionViewModel,
      );
      await repository.createCaseFile(
        code: _codeController.text.trim(),
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
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
            : 'No se pudo crear el expediente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
