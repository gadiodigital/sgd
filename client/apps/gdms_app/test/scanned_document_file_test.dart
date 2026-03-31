import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';

void main() {
  test('copyWith conserva datos no modificados y reemplaza los provistos', () {
    const file = ScannedDocumentFile(
      sessionId: 's-1',
      fileName: 'scan.pdf',
      bytes: [1, 2, 3],
      pageCount: 2,
      scannerName: 'Canon',
    );

    final updated = file.copyWith(
      sessionId: 's-2',
      fileName: 'scan-2.pdf',
      bytes: const [4, 5],
      pageCount: 3,
    );

    expect(updated.sessionId, 's-2');
    expect(updated.fileName, 'scan-2.pdf');
    expect(updated.bytes, [4, 5]);
    expect(updated.pageCount, 3);
    expect(updated.scannerName, 'Canon');
  });
}
