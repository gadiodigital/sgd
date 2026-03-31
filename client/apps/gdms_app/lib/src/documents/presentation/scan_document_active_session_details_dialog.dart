import 'package:flutter/material.dart';

import '../domain/active_scan_session.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionDetailsDialog extends StatelessWidget {
  const ScanDocumentActiveSessionDetailsDialog({
    required this.session,
    required this.isCurrent,
    required this.isBusy,
    required this.onResumeRequested,
    required this.onDiscardRequested,
    super.key,
  });

  final ActiveScanSession session;
  final bool isCurrent;
  final bool isBusy;
  final ValueChanged<String> onResumeRequested;
  final ValueChanged<String> onDiscardRequested;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(session.scannerName.isEmpty ? 'Detalle de sesion' : session.scannerName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isCurrent)
                  const Chip(label: Text('Abierta aqui')),
                Chip(
                  label: Text(
                    ScanDocumentActiveSessionsSupport.statusLabel(
                      session.status,
                    ),
                  ),
                ),
                if (session.isRehydrated)
                  const Chip(label: Text('Rehidratada')),
                if (session.isStale)
                  const Chip(label: Text('Inactiva'))
                else if (session.isDormant)
                  const Chip(label: Text('Dormida')),
                Chip(label: Text(session.modeLabel)),
              ],
            ),
            const SizedBox(height: 12),
            _SessionDetailLine(label: 'Sesion', value: session.sessionId),
            _SessionDetailLine(
              label: 'Paginas',
              value: session.pageCount.toString(),
            ),
            _SessionDetailLine(
              label: 'Creada',
              value: ScanDocumentActiveSessionsSupport.formatDateTime(
                session.createdAtUtc,
              ),
            ),
            _SessionDetailLine(
              label: 'Ultima actividad',
              value: ScanDocumentActiveSessionsSupport.formatDateTime(
                session.lastTouchedAtUtc,
              ),
            ),
            _SessionDetailLine(
              label: 'Fuente',
              value: session.isAdf
                  ? 'ADF'
                  : session.isFlatbed
                  ? 'Cama plana'
                  : session.modeLabel,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: isBusy
              ? null
              : () {
                  Navigator.of(context).pop();
                  onDiscardRequested(session.sessionId);
                },
          child: const Text('Descartar'),
        ),
        FilledButton(
          onPressed: isBusy
              ? null
              : () {
                  Navigator.of(context).pop();
                  onResumeRequested(session.sessionId);
                },
          child: const Text('Reanudar'),
        ),
      ],
    );
  }
}

class _SessionDetailLine extends StatelessWidget {
  const _SessionDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}
