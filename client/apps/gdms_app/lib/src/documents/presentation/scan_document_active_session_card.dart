import 'package:flutter/material.dart';

import '../domain/active_scan_session.dart';
import 'scan_document_active_sessions_support.dart';

class ScanDocumentActiveSessionCard extends StatelessWidget {
  const ScanDocumentActiveSessionCard({
    required this.session,
    required this.isBusy,
    required this.isCurrent,
    required this.isPriority,
    required this.onDetailsRequested,
    required this.onResumeRequested,
    required this.onDiscardRequested,
    super.key,
  });

  final ActiveScanSession session;
  final bool isBusy;
  final bool isCurrent;
  final bool isPriority;
  final VoidCallback onDetailsRequested;
  final ValueChanged<String> onResumeRequested;
  final ValueChanged<String> onDiscardRequested;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.scannerName.isEmpty
                        ? session.sessionId
                        : session.scannerName,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isCurrent)
                        const Chip(
                          label: Text('Abierta aqui'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (isPriority)
                        const Chip(
                          label: Text('Prioridad'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (session.isRehydrated)
                        const Chip(
                          label: Text('Rehidratada'),
                          visualDensity: VisualDensity.compact,
                        ),
                      Chip(
                        label: Text(
                          ScanDocumentActiveSessionsSupport.statusLabel(
                            session.status,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (session.isStale)
                        const Chip(
                          label: Text('Inactiva'),
                          visualDensity: VisualDensity.compact,
                        )
                      else if (session.isDormant)
                        const Chip(
                          label: Text('Dormida'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 4),
                    const Text('Sesion abierta en este dialogo'),
                  ],
                  const SizedBox(height: 4),
                  Text('${session.modeLabel} · ${session.pageCount} pag.'),
                  const SizedBox(height: 4),
                  Text(
                    'Sesion ${session.sessionId} · ${ScanDocumentActiveSessionsSupport.formatDateTime(session.createdAtUtc)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ultima actividad: ${ScanDocumentActiveSessionsSupport.formatDateTime(session.lastTouchedAtUtc)}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onDetailsRequested,
              child: const Text('Detalle'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isBusy ? null : () => onResumeRequested(session.sessionId),
              child: const Text('Reanudar'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isBusy ? null : () => onDiscardRequested(session.sessionId),
              tooltip: 'Descartar sesion',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
