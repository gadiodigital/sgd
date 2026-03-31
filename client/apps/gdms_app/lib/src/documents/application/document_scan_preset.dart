final class DocumentScanPreset {
  const DocumentScanPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.duplex,
    required this.dpi,
    required this.pixelType,
    required this.discardBlankPages,
  });

  static const libraryColor = DocumentScanPreset(
    id: 'library-color',
    label: 'Archivo color',
    description: 'Duplex color 300 dpi con descarte automatico de blancas.',
    duplex: true,
    dpi: 300,
    pixelType: 'color',
    discardBlankPages: 'auto',
  );

  static const contractsGray = DocumentScanPreset(
    id: 'contracts-gray',
    label: 'Contratos',
    description: 'Duplex gris 300 dpi conservando todas las paginas.',
    duplex: true,
    dpi: 300,
    pixelType: 'gray',
    discardBlankPages: 'off',
  );

  static const quickBw = DocumentScanPreset(
    id: 'quick-bw',
    label: 'B/N rapido',
    description: 'Simplex 200 dpi en blanco y negro para captura veloz.',
    duplex: false,
    dpi: 200,
    pixelType: 'bw',
    discardBlankPages: 'auto',
  );

  static const values = [libraryColor, contractsGray, quickBw];

  final String id;
  final String label;
  final String description;
  final bool duplex;
  final int dpi;
  final String pixelType;
  final String discardBlankPages;
}
