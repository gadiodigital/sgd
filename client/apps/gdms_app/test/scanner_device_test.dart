import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';

void main() {
  test('fromJson normaliza strings y usa defaults seguros', () {
    final scanner = ScannerDevice.fromJson({
      'id': 7,
      'name': ' fi-8170 ',
      'manufacturer': ' Fujitsu ',
      'productFamily': ' ScanSnap ',
      'twainVersion': ' 2.4 ',
      'isOpen': true,
    });

    expect(scanner.id, 7);
    expect(scanner.name, 'fi-8170');
    expect(scanner.manufacturer, 'Fujitsu');
    expect(scanner.productFamily, 'ScanSnap');
    expect(scanner.twainVersion, '2.4');
    expect(scanner.isOpen, isTrue);
  });

  test('fromJson cubre faltantes e invalidos con defaults', () {
    final scanner = ScannerDevice.fromJson(const {});

    expect(scanner.id, isNull);
    expect(scanner.name, isEmpty);
    expect(scanner.manufacturer, isEmpty);
    expect(scanner.productFamily, isEmpty);
    expect(scanner.twainVersion, isEmpty);
    expect(scanner.isOpen, isFalse);
  });

  test('getters derivados resuelven etiquetas con y sin metadata', () {
    const healthy = ScannerDevice(
      id: 3,
      name: 'fi-8170',
      manufacturer: 'Fujitsu',
      productFamily: 'ScanSnap',
      twainVersion: '2.4',
      isOpen: false,
    );
    const missing = ScannerDevice(
      id: null,
      name: 'Canon DR',
      manufacturer: '',
      productFamily: '',
      twainVersion: '',
      isOpen: true,
    );

    expect(healthy.hasTwainMetadata, isTrue);
    expect(healthy.sourceStatusLabel, 'Source cerrado');
    expect(healthy.compatibilityLabel, 'Compatibilidad TWAIN OK');
    expect(healthy.sourceIdLabel, 'Source #3');
    expect(healthy.displayLabel, 'Fujitsu fi-8170');

    expect(missing.hasTwainMetadata, isFalse);
    expect(missing.sourceStatusLabel, 'Source abierto');
    expect(missing.compatibilityLabel, 'Verificar driver TWAIN');
    expect(missing.sourceIdLabel, 'Source sin id');
    expect(missing.displayLabel, 'Canon DR');
  });
}
