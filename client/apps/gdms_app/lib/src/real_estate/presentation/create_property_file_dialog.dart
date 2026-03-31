import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../infrastructure/api/api_exception.dart';
import '../../infrastructure/repositories/api_real_estate_dashboard_repository.dart';

/// Collects the data required to create a new property file.
class CreatePropertyFileDialog extends StatefulWidget {
  const CreatePropertyFileDialog({
    required this.sessionViewModel,
    required this.onCreated,
    super.key,
  });

  final AppSessionViewModel sessionViewModel;
  final Future<void> Function() onCreated;

  @override
  State<CreatePropertyFileDialog> createState() =>
      _CreatePropertyFileDialogState();
}

class _CreatePropertyFileDialogState extends State<CreatePropertyFileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  String _operationType = 'SALE';
  bool _isBusy = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _addressController.dispose();
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
                  'Crear legajo inmobiliario',
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
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: _validateShortText,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_operationType),
                  initialValue: _operationType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de operación',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SALE', child: Text('Venta')),
                    DropdownMenuItem(value: 'RENT', child: Text('Alquiler')),
                    DropdownMenuItem(value: 'LEASE', child: Text('Arrendamiento')),
                    DropdownMenuItem(value: 'MIXED', child: Text('Mixto')),
                  ],
                  onChanged: _isBusy
                      ? null
                      : (value) => setState(() => _operationType = value ?? 'SALE'),
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
      final repository = ApiRealEstateDashboardRepository(
        widget.sessionViewModel.apiClient,
        widget.sessionViewModel,
      );
      await repository.createPropertyFile(
        code: _codeController.text,
        title: _titleController.text,
        address: _addressController.text,
        operationType: _operationType,
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
            : 'No se pudo crear el legajo inmobiliario.';
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
