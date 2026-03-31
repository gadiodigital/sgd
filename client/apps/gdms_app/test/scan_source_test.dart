import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';

void main() {
  test('adf expone id y label esperados', () {
    expect(ScanSource.adf.id, 'adf');
    expect(ScanSource.adf.label, 'ADF');
  });

  test('flatbed expone id y label esperados', () {
    expect(ScanSource.flatbed.id, 'flatbed');
    expect(ScanSource.flatbed.label, 'Cama plana');
  });
}
