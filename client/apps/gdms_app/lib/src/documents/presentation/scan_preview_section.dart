import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/scanned_document_file.dart';
import '../domain/scan_session_details.dart';

class ScanPreviewSection extends StatelessWidget {
  const ScanPreviewSection({
    required this.scannedFile,
    required this.previewBytes,
    required this.currentPage,
    required this.sessionDetails,
    required this.canShowPreviousPage,
    required this.canShowNextPage,
    required this.canDeleteCurrentPage,
    required this.canRotateCurrentPage,
    required this.canMoveCurrentPageBackward,
    required this.canMoveCurrentPageForward,
    required this.onPreviousPageRequested,
    required this.onNextPageRequested,
    required this.onRotateRequested,
    required this.onDeleteRequested,
    required this.onMoveBackwardRequested,
    required this.onMoveForwardRequested,
    required this.onAppendScanRequested,
    required this.onInsertBeforeScanRequested,
    required this.onInsertScanRequested,
    required this.canAppendScan,
    required this.canAdjustCurrentPage,
    required this.onBrightenRequested,
    required this.onDarkenRequested,
    required this.onIncreaseContrastRequested,
    required this.onDecreaseContrastRequested,
    required this.canRefreshSession,
    required this.onRefreshSessionRequested,
    required this.onDiscardSessionRequested,
    required this.onExportPdfRequested,
    required this.isBusy,
    super.key,
  });

  final ScannedDocumentFile scannedFile;
  final List<int>? previewBytes;
  final int currentPage;
  final ScanSessionDetails? sessionDetails;
  final bool canShowPreviousPage;
  final bool canShowNextPage;
  final bool canDeleteCurrentPage;
  final bool canRotateCurrentPage;
  final bool canMoveCurrentPageBackward;
  final bool canMoveCurrentPageForward;
  final Future<void> Function() onPreviousPageRequested;
  final Future<void> Function() onNextPageRequested;
  final Future<void> Function() onRotateRequested;
  final Future<void> Function() onDeleteRequested;
  final Future<void> Function() onMoveBackwardRequested;
  final Future<void> Function() onMoveForwardRequested;
  final Future<void> Function() onAppendScanRequested;
  final Future<void> Function() onInsertBeforeScanRequested;
  final Future<void> Function() onInsertScanRequested;
  final bool canAppendScan;
  final bool canAdjustCurrentPage;
  final Future<void> Function() onBrightenRequested;
  final Future<void> Function() onDarkenRequested;
  final Future<void> Function() onIncreaseContrastRequested;
  final Future<void> Function() onDecreaseContrastRequested;
  final bool canRefreshSession;
  final Future<void> Function() onRefreshSessionRequested;
  final Future<void> Function() onDiscardSessionRequested;
  final Future<bool> Function() onExportPdfRequested;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isFlatbed = sessionDetails?.isFlatbed ?? false;
    final appendLabel = isFlatbed ? 'Agregar hoja' : 'Agregar paginas';
    final insertBeforeLabel = isFlatbed
        ? 'Insertar hoja antes'
        : 'Insertar antes';
    final insertAfterLabel = isFlatbed
        ? 'Insertar hoja despues'
        : 'Insertar despues';
    final helperText = isFlatbed
        ? 'La preview permite releer la sesion, reordenar, sumar nuevas hojas desde cama plana y corregir paginas.'
        : 'La preview permite releer la sesion, navegar, reordenar, anexar y corregir paginas.';
    return GdmsSectionCard(
      title: 'Previsualizacion',
      subtitle:
          '${scannedFile.fileName} · pagina $currentPage de '
          '${scannedFile.pageCount} · '
          '${scannedFile.scannerName.isEmpty ? 'scanner local' : scannedFile.scannerName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previewBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                Uint8List.fromList(previewBytes!),
                fit: BoxFit.cover,
              ),
            )
          else
            const Text(
              'No se pudo generar la preview, pero el PDF escaneado quedo disponible.',
            ),
          if (sessionDetails != null) ...[
            const SizedBox(height: 12),
            Text(
              'Sesion ${sessionDetails!.sessionId} · '
              '${sessionDetails!.mode.isEmpty ? 'modo sin dato' : sessionDetails!.mode} · '
              '${sessionDetails!.status.isEmpty ? 'estado sin dato' : sessionDetails!.status}',
            ),
            if (sessionDetails!.dpi != null ||
                sessionDetails!.pixelType.isNotEmpty ||
                sessionDetails!.discardBlankPages.isNotEmpty)
              Text(
                'DPI ${sessionDetails!.dpi?.toString() ?? 'sin dato'} · '
                '${sessionDetails!.pixelType.isEmpty ? 'color sin dato' : sessionDetails!.pixelType} · '
                'blancas ${sessionDetails!.discardBlankPages.isEmpty ? 'sin dato' : sessionDetails!.discardBlankPages}',
              ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: !isBusy ? onExportPdfRequested : null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Exportar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy ? onDiscardSessionRequested : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Descartar sesion'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canRefreshSession
                    ? onRefreshSessionRequested
                    : null,
                icon: const Icon(Icons.sync),
                label: const Text('Releer sesión'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canShowPreviousPage
                    ? onPreviousPageRequested
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canShowNextPage
                    ? onNextPageRequested
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Siguiente'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canRotateCurrentPage
                    ? onRotateRequested
                    : null,
                icon: const Icon(Icons.rotate_right),
                label: const Text('Rotar 90°'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canDeleteCurrentPage
                    ? onDeleteRequested
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar página'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canMoveCurrentPageBackward
                    ? onMoveBackwardRequested
                    : null,
                icon: const Icon(Icons.keyboard_double_arrow_left),
                label: const Text('Mover atrás'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canMoveCurrentPageForward
                    ? onMoveForwardRequested
                    : null,
                icon: const Icon(Icons.keyboard_double_arrow_right),
                label: const Text('Mover adelante'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAppendScan
                    ? onAppendScanRequested
                    : null,
                icon: const Icon(Icons.add_to_photos_outlined),
                label: Text(appendLabel),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAppendScan
                    ? onInsertBeforeScanRequested
                    : null,
                icon: const Icon(Icons.playlist_play_outlined),
                label: Text(insertBeforeLabel),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAppendScan
                    ? onInsertScanRequested
                    : null,
                icon: const Icon(Icons.playlist_add_outlined),
                label: Text(insertAfterLabel),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAdjustCurrentPage
                    ? onBrightenRequested
                    : null,
                icon: const Icon(Icons.wb_sunny_outlined),
                label: const Text('Aclarar'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAdjustCurrentPage
                    ? onDarkenRequested
                    : null,
                icon: const Icon(Icons.dark_mode_outlined),
                label: const Text('Oscurecer'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAdjustCurrentPage
                    ? onIncreaseContrastRequested
                    : null,
                icon: const Icon(Icons.contrast),
                label: const Text('Más contraste'),
              ),
              OutlinedButton.icon(
                onPressed: !isBusy && canAdjustCurrentPage
                    ? onDecreaseContrastRequested
                    : null,
                icon: const Icon(Icons.tonality_outlined),
                label: const Text('Menos contraste'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(helperText),
        ],
      ),
    );
  }
}
