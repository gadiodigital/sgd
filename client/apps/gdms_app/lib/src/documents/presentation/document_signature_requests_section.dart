import 'package:design_system/design_system.dart';
import 'package:feature_signature/feature_signature.dart';
import 'package:flutter/material.dart';

/// Renders the signature requests associated with the current document.
class DocumentSignatureRequestsSection extends StatelessWidget {
  const DocumentSignatureRequestsSection({
    required this.envelopes,
    required this.message,
    required this.isBusy,
    required this.onCreateRequested,
    required this.onCompleteRequested,
    required this.onCancelRequested,
    super.key,
  });

  final List<SignatureEnvelopeItem> envelopes;
  final String? message;
  final bool isBusy;
  final Future<void> Function() onCreateRequested;
  final Future<void> Function(SignatureEnvelopeItem item) onCompleteRequested;
  final Future<void> Function(SignatureEnvelopeItem item) onCancelRequested;

  @override
  Widget build(BuildContext context) {
    return GdmsSectionCard(
      title: 'Firmas documentales',
      subtitle: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : onCreateRequested,
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Solicitar firma'),
          ),
          const SizedBox(height: 12),
          if (envelopes.isEmpty)
            const Text('No hay solicitudes de firma para este documento.')
          else
            Column(
              children: envelopes
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(item.signerDisplayName),
                        subtitle: Text(
                          '${item.signerEmail} · ${item.signatureLevel} · ${item.providerCode} · ${item.dueAtLabel}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GdmsStatusBadge(
                              label: item.status,
                              tone: item.canComplete
                                  ? GdmsStatusTone.warning
                                  : GdmsStatusTone.success,
                            ),
                            if (item.canComplete)
                              FilledButton(
                                onPressed: isBusy
                                    ? null
                                    : () => onCompleteRequested(item),
                                child: const Text('Completar'),
                              ),
                            if (item.canCancel)
                              OutlinedButton(
                                onPressed: isBusy
                                    ? null
                                    : () => onCancelRequested(item),
                                child: const Text('Cancelar'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}
