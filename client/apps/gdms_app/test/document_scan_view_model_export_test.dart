import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_export.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';

void main() {
  late _FakeFilePicker fakePicker;

  setUp(() {
    fakePicker = _FakeFilePicker();
    FilePicker.platform = fakePicker;
  });

  DocumentScanViewModel buildViewModel() {
    return DocumentScanViewModel(WindowsTwainScanRepository());
  }

  ActiveScanSession buildSession({
    required String sessionId,
    required String mode,
    required String status,
    required int pageCount,
    bool isRehydrated = false,
  }) {
    return ActiveScanSession(
      sessionId: sessionId,
      createdAtUtc: DateTime.utc(2026, 3, 31, 10),
      lastTouchedAtUtc: DateTime.utc(2026, 3, 31, 10, 5),
      scannerName: 'Canon DR',
      mode: mode,
      status: status,
      pageCount: pageCount,
      isRehydrated: isRehydrated,
    );
  }

  test('exportPdf informa cuando no hay escaneo activo', () async {
    final vm = buildViewModel();

    final exported = await DocumentScanViewModelExport.exportPdf(vm);

    expect(exported, isFalse);
    expect(vm.message, 'No hay un escaneo activo para exportar.');
  });

  test('exportPdf guarda bytes y reporta la ruta elegida', () async {
    final vm = buildViewModel();
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [1, 2, 3, 4],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );
    fakePicker.nextPath = 'C:/tmp/scan.pdf';

    final exported = await DocumentScanViewModelExport.exportPdf(vm);

    expect(exported, isTrue);
    expect(fakePicker.lastDialogTitle, 'Guardar PDF escaneado');
    expect(fakePicker.lastFileName, 'scan.pdf');
    expect(fakePicker.lastBytes, [1, 2, 3, 4]);
    expect(vm.message, 'PDF escaneado guardado en C:/tmp/scan.pdf');
  });

  test('exportPdf conserva exito pero informa cancelacion del usuario', () async {
    final vm = buildViewModel();
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [9, 8],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    final exported = await DocumentScanViewModelExport.exportPdf(vm);

    expect(exported, isTrue);
    expect(vm.message, 'Exportación cancelada por el usuario.');
  });

  test('exportPdf informa fallo cuando saveFile lanza error', () async {
    final vm = buildViewModel();
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [1],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );
    fakePicker.throwOnSave = true;

    final exported = await DocumentScanViewModelExport.exportPdf(vm);

    expect(exported, isFalse);
    expect(vm.message, 'No se pudo exportar el PDF escaneado.');
  });

  test('exportSessionsSummary informa cuando no hay sesiones visibles', () async {
    final vm = buildViewModel();

    final exported = await DocumentScanViewModelExport.exportSessionsSummary(
      vm,
      const [],
    );

    expect(exported, isFalse);
    expect(vm.message, 'No hay sesiones visibles para exportar.');
  });

  test('exportSessionsSummary genera json con metadata del lote visible', () async {
    final vm = buildViewModel();
    fakePicker.nextPath = 'C:/tmp/sessions.json';

    final exported = await DocumentScanViewModelExport.exportSessionsSummary(
      vm,
      [
        buildSession(
          sessionId: 's-1',
          mode: 'adf-duplex',
          status: 'running',
          pageCount: 3,
        ),
        buildSession(
          sessionId: 's-2',
          mode: 'flatbed-single',
          status: 'completed',
          pageCount: 1,
          isRehydrated: true,
        ),
      ],
    );

    final payload = jsonDecode(
      utf8.decode(fakePicker.lastBytes!),
    ) as Map<String, dynamic>;

    expect(exported, isTrue);
    expect(fakePicker.lastDialogTitle, 'Guardar resumen de sesiones visibles');
    expect(fakePicker.lastFileName, startsWith('scan-sessions-'));
    expect(fakePicker.lastFileName, endsWith('.json'));
    expect(payload['serviceBaseUrl'], vm.serviceBaseUrl);
    expect(payload['totalSessions'], 2);
    expect(payload['exportedAtUtc'], isA<String>());
    expect(payload['sessions'], [
      {
        'sessionId': 's-1',
        'scannerName': 'Canon DR',
        'mode': 'adf-duplex',
        'status': 'running',
        'pageCount': 3,
        'createdAtUtc': '2026-03-31T10:00:00.000Z',
        'lastTouchedAtUtc': '2026-03-31T10:05:00.000Z',
        'isRehydrated': false,
      },
      {
        'sessionId': 's-2',
        'scannerName': 'Canon DR',
        'mode': 'flatbed-single',
        'status': 'completed',
        'pageCount': 1,
        'createdAtUtc': '2026-03-31T10:00:00.000Z',
        'lastTouchedAtUtc': '2026-03-31T10:05:00.000Z',
        'isRehydrated': true,
      },
    ]);
    expect(vm.message, 'Resumen de sesiones guardado en C:/tmp/sessions.json');
  });

  test('exportSessionsSummary informa cancelacion y fallo del usuario', () async {
    final vm = buildViewModel();
    final sessions = [
      buildSession(
        sessionId: 's-1',
        mode: 'adf-simplex',
        status: 'completed',
        pageCount: 2,
      ),
    ];

    final canceled = await DocumentScanViewModelExport.exportSessionsSummary(
      vm,
      sessions,
    );
    expect(canceled, isTrue);
    expect(vm.message, 'Exportación de sesiones cancelada por el usuario.');

    fakePicker.throwOnSave = true;
    final failed = await DocumentScanViewModelExport.exportSessionsSummary(
      vm,
      sessions,
    );
    expect(failed, isFalse);
    expect(vm.message, 'No se pudo exportar el resumen de sesiones.');
  });
}

final class _FakeFilePicker extends FilePicker {
  String? nextPath;
  bool throwOnSave = false;
  String? lastDialogTitle;
  String? lastFileName;
  List<int>? lastBytes;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (throwOnSave) {
      throw StateError('save-failed');
    }
    lastDialogTitle = dialogTitle;
    lastFileName = fileName;
    lastBytes = bytes?.toList(growable: false);
    return nextPath;
  }
}
