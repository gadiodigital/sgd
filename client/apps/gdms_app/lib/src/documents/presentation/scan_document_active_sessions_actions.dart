import 'package:flutter/material.dart';

class ScanDocumentActiveSessionsActions extends StatelessWidget {
  const ScanDocumentActiveSessionsActions({
    required this.visibleCount,
    required this.attentionCount,
    required this.finishedCount,
    required this.errorCount,
    required this.staleCount,
    required this.runningCount,
    required this.hasAttentionVisible,
    required this.hasFinishedVisible,
    required this.hasErrorVisible,
    required this.hasStaleVisible,
    required this.hasRunningVisible,
    required this.isBusy,
    required this.onCopyAttentionIdsRequested,
    required this.onCopyVisibleIdsRequested,
    required this.onExportAttentionRequested,
    required this.onExportVisibleRequested,
    required this.onOpenAttentionRequested,
    required this.onOpenErrorRequested,
    required this.onResumeAttentionRequested,
    required this.onResumeFirstRequested,
    required this.onDiscardAttentionRequested,
    required this.onDiscardVisibleRequested,
    required this.onDiscardFinishedVisibleRequested,
    required this.onDiscardErrorVisibleRequested,
    required this.onDiscardStaleVisibleRequested,
    super.key,
  });

  final int visibleCount;
  final int attentionCount;
  final int finishedCount;
  final int errorCount;
  final int staleCount;
  final int runningCount;
  final bool hasAttentionVisible;
  final bool hasFinishedVisible;
  final bool hasErrorVisible;
  final bool hasStaleVisible;
  final bool hasRunningVisible;
  final bool isBusy;
  final VoidCallback onCopyAttentionIdsRequested;
  final VoidCallback onCopyVisibleIdsRequested;
  final VoidCallback onExportAttentionRequested;
  final VoidCallback onExportVisibleRequested;
  final VoidCallback onOpenAttentionRequested;
  final VoidCallback onOpenErrorRequested;
  final VoidCallback onResumeAttentionRequested;
  final VoidCallback onResumeFirstRequested;
  final VoidCallback onDiscardAttentionRequested;
  final VoidCallback onDiscardVisibleRequested;
  final VoidCallback onDiscardFinishedVisibleRequested;
  final VoidCallback onDiscardErrorVisibleRequested;
  final VoidCallback onDiscardStaleVisibleRequested;

  @override
  Widget build(BuildContext context) {
    if (visibleCount == 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: isBusy ? null : onCopyVisibleIdsRequested,
          child: const Text('Copiar IDs visibles'),
        ),
        if (hasAttentionVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onCopyAttentionIdsRequested,
            child: Text('Copiar IDs con atencion ($attentionCount)'),
          ),
        if (hasAttentionVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onExportAttentionRequested,
            child: Text('Exportar con atencion ($attentionCount)'),
          ),
        OutlinedButton(
          onPressed: isBusy ? null : onExportVisibleRequested,
          child: const Text('Exportar visibles'),
        ),
        if (hasAttentionVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onOpenAttentionRequested,
            child: const Text('Abrir primera con atencion'),
          ),
        if (hasErrorVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onOpenErrorRequested,
            child: Text('Abrir primera con error ($errorCount)'),
          ),
        if (hasAttentionVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onResumeAttentionRequested,
            child: const Text('Reanudar primera con atencion'),
          ),
        if (hasRunningVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onResumeFirstRequested,
            child: Text('Reanudar primera running ($runningCount)'),
          ),
        if (hasAttentionVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onDiscardAttentionRequested,
            child: Text('Descartar con atencion ($attentionCount)'),
          ),
        OutlinedButton(
          onPressed: isBusy ? null : onResumeFirstRequested,
          child: const Text('Reanudar primera visible'),
        ),
        OutlinedButton(
          onPressed: isBusy ? null : onDiscardVisibleRequested,
          child: Text('Descartar visibles ($visibleCount)'),
        ),
        if (hasFinishedVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onDiscardFinishedVisibleRequested,
            child: Text('Descartar visibles finalizadas ($finishedCount)'),
          ),
        if (hasErrorVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onDiscardErrorVisibleRequested,
            child: Text('Descartar visibles con error ($errorCount)'),
          ),
        if (hasStaleVisible)
          OutlinedButton(
            onPressed: isBusy ? null : onDiscardStaleVisibleRequested,
            child: Text('Descartar visibles inactivas ($staleCount)'),
          ),
      ],
    );
  }
}
