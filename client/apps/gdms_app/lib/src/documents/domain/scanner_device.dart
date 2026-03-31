final class ScannerDevice {
  const ScannerDevice({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.productFamily,
    required this.twainVersion,
    required this.isOpen,
  });

  factory ScannerDevice.fromJson(Map<String, dynamic> json) {
    return ScannerDevice(
      id: json['id'] as int?,
      name: (json['name'] as String? ?? '').trim(),
      manufacturer: (json['manufacturer'] as String? ?? '').trim(),
      productFamily: (json['productFamily'] as String? ?? '').trim(),
      twainVersion: (json['twainVersion'] as String? ?? '').trim(),
      isOpen: json['isOpen'] as bool? ?? false,
    );
  }

  final int? id;
  final String name;
  final String manufacturer;
  final String productFamily;
  final String twainVersion;
  final bool isOpen;
  bool get hasTwainMetadata => twainVersion.trim().isNotEmpty;
  String get sourceStatusLabel => isOpen ? 'Source abierto' : 'Source cerrado';
  String get compatibilityLabel =>
      hasTwainMetadata ? 'Compatibilidad TWAIN OK' : 'Verificar driver TWAIN';
  String get sourceIdLabel => id == null ? 'Source sin id' : 'Source #$id';

  String get displayLabel {
    final manufacturerLabel = manufacturer.trim();
    if (manufacturerLabel.isEmpty) {
      return name;
    }

    return '$manufacturerLabel $name';
  }
}
