enum ScanSource {
  adf,
  flatbed;

  String get id => switch (this) {
    ScanSource.adf => 'adf',
    ScanSource.flatbed => 'flatbed',
  };

  String get label => switch (this) {
    ScanSource.adf => 'ADF',
    ScanSource.flatbed => 'Cama plana',
  };
}
