import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../application/create_signature_request_view_model.dart';

/// Collects the minimum data required to create a signature request.
class CreateSignatureRequestDialog extends StatefulWidget {
  const CreateSignatureRequestDialog({
    required this.viewModel,
    this.initialDocumentId,
    this.initialDocumentTitle,
    super.key,
  });

  final CreateSignatureRequestViewModel viewModel;
  final String? initialDocumentId;
  final String? initialDocumentTitle;

  @override
  State<CreateSignatureRequestDialog> createState() =>
      _CreateSignatureRequestDialogState();
}

class _CreateSignatureRequestDialogState
    extends State<CreateSignatureRequestDialog> {
  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  final _formKey = GlobalKey<FormState>();
  final _signerDisplayNameController = TextEditingController();
  final _signerEmailController = TextEditingController();
  String? _selectedDocumentId;
  String _signatureLevel = 'ELECTRONIC';

  @override
  void initState() {
    super.initState();
    _selectedDocumentId = widget.initialDocumentId;
    widget.viewModel.load();
    if (widget.initialDocumentId != null && widget.initialDocumentTitle != null) {
      widget.viewModel.preloadDocument(
        widget.initialDocumentId!,
        widget.initialDocumentTitle!,
      );
    }
  }

  @override
  void dispose() {
    _signerDisplayNameController.dispose();
    _signerEmailController.dispose();
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
            listenable: widget.viewModel,
            builder: (context, _) {
              return Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solicitar firma',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedDocumentId),
                      initialValue: _selectedDocumentId,
                      decoration: const InputDecoration(labelText: 'Documento'),
                      items: widget.viewModel.documentOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.title),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: widget.viewModel.isBusy || widget.initialDocumentId != null
                          ? null
                          : (value) =>
                                setState(() => _selectedDocumentId = value),
                      validator: (value) =>
                          value == null ? 'Seleccioná un documento.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _signerDisplayNameController,
                      decoration: const InputDecoration(labelText: 'Firmante'),
                      validator: (value) {
                        final normalized = value?.trim() ?? '';
                        return normalized.length < 3
                            ? 'Ingresá un nombre de firmante válido.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _signerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email del firmante',
                      ),
                      validator: (value) {
                        final normalized = value?.trim() ?? '';
                        return _emailPattern.hasMatch(normalized)
                            ? null
                            : 'Ingresá un email válido.';
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_signatureLevel),
                      initialValue: _signatureLevel,
                      decoration: const InputDecoration(labelText: 'Nivel'),
                      items: const [
                        DropdownMenuItem(
                          value: 'ELECTRONIC',
                          child: Text('Electrónica'),
                        ),
                        DropdownMenuItem(
                          value: 'DIGITAL',
                          child: Text('Digital'),
                        ),
                      ],
                      onChanged: widget.viewModel.isBusy
                          ? null
                          : (value) => setState(
                              () => _signatureLevel = value ?? 'ELECTRONIC',
                            ),
                    ),
                    if (widget.viewModel.message != null) ...[
                      const SizedBox(height: 16),
                      Text(widget.viewModel.message!),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.viewModel.isBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: widget.viewModel.isBusy ? null : _submit,
                          child: const Text('Crear solicitud'),
                        ),
                      ],
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
    if (!_formKey.currentState!.validate() || _selectedDocumentId == null) {
      return;
    }

    await widget.viewModel.submit(
      documentId: _selectedDocumentId!,
      signerDisplayName: _signerDisplayNameController.text.trim(),
      signerEmail: _signerEmailController.text.trim(),
      signatureLevel: _signatureLevel,
    );

    if (!mounted || widget.viewModel.state == ViewState.error) {
      return;
    }

    Navigator.of(context).pop(true);
  }
}
