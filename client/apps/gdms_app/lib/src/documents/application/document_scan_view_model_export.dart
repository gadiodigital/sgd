import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/active_scan_session.dart';
import 'document_scan_view_model.dart';

final class DocumentScanViewModelExport {
  static Future<bool> exportPdf(DocumentScanViewModel vm) async {
    final scannedFile = vm.lastScannedFile;
    if (scannedFile == null) {
      vm.setMessage('No hay un escaneo activo para exportar.');
      return false;
    }

    try {
      await vm.run(() async {
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar PDF escaneado',
          fileName: scannedFile.fileName,
          bytes: Uint8List.fromList(scannedFile.bytes),
        );
        vm.setMessage(
          savedPath == null
              ? 'Exportación cancelada por el usuario.'
              : 'PDF escaneado guardado en $savedPath',
        );
      });
      return true;
    } catch (_) {
      vm.setMessage('No se pudo exportar el PDF escaneado.');
      return false;
    }
  }

  static Future<bool> exportSessionsSummary(
    DocumentScanViewModel vm,
    List<ActiveScanSession> sessions,
  ) async {
    if (sessions.isEmpty) {
      vm.setMessage('No hay sesiones visibles para exportar.');
      return false;
    }

    final payload = <String, Object?>{
      'exportedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'serviceBaseUrl': vm.serviceBaseUrl,
      'totalSessions': sessions.length,
      'sessions': sessions
          .map(
            (session) => <String, Object?>{
              'sessionId': session.sessionId,
              'scannerName': session.scannerName,
              'mode': session.mode,
              'status': session.status,
              'pageCount': session.pageCount,
              'createdAtUtc': session.createdAtUtc.toIso8601String(),
              'lastTouchedAtUtc': session.lastTouchedAtUtc.toIso8601String(),
              'isRehydrated': session.isRehydrated,
            },
          )
          .toList(growable: false),
    };

    try {
      await vm.run(() async {
        final fileName =
            'scan-sessions-${DateTime.now().toUtc().millisecondsSinceEpoch}.json';
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar resumen de sesiones visibles',
          fileName: fileName,
          bytes: Uint8List.fromList(
            utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
          ),
        );
        vm.setMessage(
          savedPath == null
              ? 'Exportación de sesiones cancelada por el usuario.'
              : 'Resumen de sesiones guardado en $savedPath',
        );
      });
      return true;
    } catch (_) {
      vm.setMessage('No se pudo exportar el resumen de sesiones.');
      return false;
    }
  }
}
