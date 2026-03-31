import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scan_session_snapshot.dart';

void main() {
  test('fromJson normaliza sessionId y status', () {
    final snapshot = ScanSessionSnapshot.fromJson({
      'sessionId': '  s-9 ',
      'status': ' EMPTY ',
      'pageCount': 3,
    });

    expect(snapshot.sessionId, 's-9');
    expect(snapshot.status, 'empty');
    expect(snapshot.pageCount, 3);
    expect(snapshot.isEmpty, isTrue);
  });

  test('considera vacia una sesion con cero paginas aunque el status no sea empty', () {
    final snapshot = ScanSessionSnapshot.fromJson({
      'sessionId': 's-1',
      'status': 'completed',
      'pageCount': 0,
    });

    expect(snapshot.isEmpty, isTrue);
  });

  test('usa defaults seguros cuando faltan datos', () {
    final snapshot = ScanSessionSnapshot.fromJson({});

    expect(snapshot.sessionId, isEmpty);
    expect(snapshot.status, isEmpty);
    expect(snapshot.pageCount, 0);
    expect(snapshot.isEmpty, isTrue);
  });
}
