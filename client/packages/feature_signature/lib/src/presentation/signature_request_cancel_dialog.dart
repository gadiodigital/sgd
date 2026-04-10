import 'package:flutter/material.dart';

final class SignatureRequestCancelDialog extends StatefulWidget {
  const SignatureRequestCancelDialog({super.key});

  @override
  State<SignatureRequestCancelDialog> createState() =>
      _SignatureRequestCancelDialogState();
}

class _SignatureRequestCancelDialogState
    extends State<SignatureRequestCancelDialog> {
  String _reason = '';

  @override
  Widget build(BuildContext context) {
    final trimmedReason = _reason.trim();
    final isReasonValid = trimmedReason.length >= 5;

    return AlertDialog(
      title: const Text('Cancelar solicitud de firma'),
      content: TextField(
        minLines: 2,
        maxLines: 4,
        onChanged: (value) => setState(() => _reason = value),
        decoration: InputDecoration(
          labelText: 'Motivo',
          hintText: 'Describi el motivo de cancelacion',
          helperText: isReasonValid
              ? 'Motivo listo para cancelar.'
              : 'Minimo 5 caracteres.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: isReasonValid
              ? () => Navigator.of(context).pop(trimmedReason)
              : null,
          child: const Text('Cancelar solicitud'),
        ),
      ],
    );
  }
}
