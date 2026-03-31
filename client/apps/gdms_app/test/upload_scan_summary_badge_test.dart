import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/presentation/upload_scan_summary_badge.dart';

void main() {
  Widget buildBadge(ScannedDocumentFile file) {
    return MaterialApp(
      home: Scaffold(body: UploadScanSummaryBadge(scannedFile: file)),
    );
  }

  testWidgets('renderiza el scanner normalizado en el badge', (tester) async {
    await tester.pumpWidget(
      buildBadge(
        const ScannedDocumentFile(
          fileName: 'scan.pdf',
          bytes: [1, 2, 3],
          pageCount: 3,
          sessionId: 'session-1',
          scannerName: '  Canon DR  ',
        ),
      ),
    );

    expect(
      find.text('PDF escaneado desde Canon DR con 3 pagina(s).'),
      findsOneWidget,
    );
  });

  testWidgets('usa fallback cuando el scanner no viene informado', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBadge(
        const ScannedDocumentFile(
          fileName: 'scan.pdf',
          bytes: [1, 2, 3],
          pageCount: 1,
          sessionId: 'session-2',
          scannerName: '   ',
        ),
      ),
    );

    expect(
      find.text('PDF escaneado desde scanner local con 1 pagina(s).'),
      findsOneWidget,
    );
  });
}
