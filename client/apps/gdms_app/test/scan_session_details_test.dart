import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scan_session_details.dart';

void main() {
  test('fromJson parsea settings y normaliza campos basicos', () {
    final details = ScanSessionDetails.fromJson({
      'sessionId': '  s-1 ',
      'status': ' completed ',
      'mode': ' adf-duplex ',
      'pageCount': 4,
      'scannerName': ' Canon DR ',
      'settings': {
        'dpi': 300,
        'pixelType': ' gray ',
        'discardBlankPages': ' auto ',
      },
    });

    expect(details.sessionId, 's-1');
    expect(details.status, 'completed');
    expect(details.mode, 'adf-duplex');
    expect(details.pageCount, 4);
    expect(details.scannerName, 'Canon DR');
    expect(details.dpi, 300);
    expect(details.pixelType, 'gray');
    expect(details.discardBlankPages, 'auto');
    expect(details.isAdf, isTrue);
    expect(details.isFlatbed, isFalse);
  });

  test('fromJson usa defaults seguros y soporta dpi double', () {
    final details = ScanSessionDetails.fromJson({
      'settings': {'dpi': 299.6},
    });

    expect(details.sessionId, isEmpty);
    expect(details.status, isEmpty);
    expect(details.mode, isEmpty);
    expect(details.pageCount, 0);
    expect(details.scannerName, isEmpty);
    expect(details.dpi, 300);
    expect(details.pixelType, isEmpty);
    expect(details.discardBlankPages, isEmpty);
    expect(details.isAdf, isFalse);
    expect(details.isFlatbed, isFalse);
  });

  test('ignora settings invalidos y detecta flatbed por prefijo', () {
    final details = ScanSessionDetails.fromJson({
      'mode': 'flatbed-single',
      'settings': 'invalid',
    });

    expect(details.dpi, isNull);
    expect(details.pixelType, isEmpty);
    expect(details.discardBlankPages, isEmpty);
    expect(details.isFlatbed, isTrue);
    expect(details.isAdf, isFalse);
  });
}
