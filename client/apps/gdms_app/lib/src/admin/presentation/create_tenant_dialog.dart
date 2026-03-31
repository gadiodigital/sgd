import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/api/gdms_api_client.dart';
import '../application/create_tenant_view_model.dart';

/// Presents a modal form to create a new tenant.
class CreateTenantDialog extends StatefulWidget {
  const CreateTenantDialog({
    required this.apiClient,
    required this.onCreated,
    super.key,
  });

  final GdmsApiClient apiClient;
  final Future<void> Function() onCreated;

  @override
  State<CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends State<CreateTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _sectorController = TextEditingController();
  final _countryController = TextEditingController(text: 'AR');
  late final CreateTenantViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateTenantViewModel(widget.apiClient);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _sectorController.dispose();
    _countryController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GdmsPageHeader(
                    title: 'Crear tenant',
                    subtitle:
                        'Alta de un espacio lógico nuevo para operar de forma aislada.',
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Código',
                            hintText: 'EJEMPLO-TENANT',
                          ),
                          validator: _validateCode,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Nombre comercial o razón social',
                          ),
                          validator: _validateRequired,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sectorController,
                          decoration: const InputDecoration(
                            labelText: 'Sector',
                            hintText: 'EMPRESA, INMOBILIARIA, JURIDICO',
                          ),
                          validator: _validateRequired,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'País',
                            hintText: 'AR',
                          ),
                          maxLength: 2,
                          validator: _validateCountry,
                        ),
                      ],
                    ),
                  ),
                  if (_viewModel.message != null) ...[
                    const SizedBox(height: 12),
                    GdmsStatusBadge(
                      label: _viewModel.message!,
                      tone: _viewModel.state == ViewState.error
                          ? GdmsStatusTone.critical
                          : GdmsStatusTone.info,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _viewModel.isBusy
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _viewModel.isBusy ? null : _submit,
                        icon: _viewModel.isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_business),
                        label: const Text('Crear'),
                      ),
                    ],
                  ),
                ],
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

    final created = await _viewModel.createTenant(
      code: _codeController.text,
      name: _nameController.text,
      sector: _sectorController.text,
      primaryCountryCode: _countryController.text,
    );
    if (!mounted || !created) return;

    await widget.onCreated();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validateCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresá el código del tenant.';
    }

    if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(text.toUpperCase())) {
      return 'Usá solo letras, números, guion o guion bajo.';
    }

    return null;
  }

  String? _validateCountry(String? value) {
    final text = value?.trim() ?? '';
    if (text.length != 2) {
      return 'Ingresá un código país de 2 letras.';
    }

    return null;
  }
}
