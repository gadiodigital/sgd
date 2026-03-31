import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/document_metadata_field.dart';
import 'package:gdms_app/src/documents/domain/document_type_catalog_entry.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_form_section.dart';

void main() {
  Widget buildSection({
    required List<DocumentTypeCatalogEntry> documentTypes,
    required String? selectedDocumentTypeCode,
    required DocumentTypeCatalogEntry? selectedDocumentType,
    required TextEditingController titleController,
    required Map<String, TextEditingController> metadataControllers,
    required Map<String, String?> booleanMetadataValues,
    PlatformFile? selectedFile,
    bool isBusy = false,
    bool supportsScannerIntegration = true,
    ValueChanged<String?>? onDocumentTypeChanged,
    void Function(String key, String? value)? onBooleanChanged,
    Future<void> Function()? onPickFile,
    Future<void> Function()? onScanDocument,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: UploadDocumentFormSection(
          formKey: GlobalKey<FormState>(),
          documentTypes: documentTypes,
          selectedDocumentTypeCode: selectedDocumentTypeCode,
          selectedDocumentType: selectedDocumentType,
          titleController: titleController,
          metadataControllers: metadataControllers,
          booleanMetadataValues: booleanMetadataValues,
          selectedFile: selectedFile,
          isBusy: isBusy,
          supportsScannerIntegration: supportsScannerIntegration,
          onDocumentTypeChanged: onDocumentTypeChanged ?? (_) {},
          onBooleanChanged: onBooleanChanged ?? (_, __) {},
          onPickFile: onPickFile ?? () async {},
          onScanDocument: onScanDocument ?? () async {},
        ),
      ),
    );
  }

  DocumentTypeCatalogEntry buildDocumentType() {
    return const DocumentTypeCatalogEntry(
      id: 'type-1',
      tenantId: 'tenant-1',
      code: 'LEASE',
      name: 'Contrato',
      sector: 'legal',
      isActive: true,
      metadataFields: [
        DocumentMetadataField(
          key: 'signed',
          label: 'Firmado',
          type: DocumentMetadataFieldType.boolean,
          required: false,
        ),
      ],
    );
  }

  testWidgets('renderiza tipo titulo metadatos y acciones de origen', (
    tester,
  ) async {
    final titleController = TextEditingController();
    addTearDown(titleController.dispose);

    String? latestType;
    String? latestBoolean;
    var pickCalls = 0;
    var scanCalls = 0;
    final documentType = buildDocumentType();

    await tester.pumpWidget(
      buildSection(
        documentTypes: [documentType],
        selectedDocumentTypeCode: 'LEASE',
        selectedDocumentType: documentType,
        titleController: titleController,
        metadataControllers: {},
        booleanMetadataValues: {'signed': null},
        onDocumentTypeChanged: (value) => latestType = value,
        onBooleanChanged: (_, value) => latestBoolean = value,
        onPickFile: () async => pickCalls += 1,
        onScanDocument: () async => scanCalls += 1,
      ),
    );

    expect(find.text('Tipo documental'), findsOneWidget);
    expect(find.text('Titulo'), findsOneWidget);
    expect(find.text('Metadatos tipados'), findsOneWidget);
    expect(find.text('Escanear documento'), findsOneWidget);

    final typeDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    typeDropdown.onChanged?.call('LEASE');

    final boolDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).last,
    );
    boolDropdown.onChanged?.call('false');

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pump();
    await tester.tap(find.text('Escanear documento'));
    await tester.pump();

    expect(latestType, 'LEASE');
    expect(latestBoolean, 'false');
    expect(pickCalls, 1);
    expect(scanCalls, 1);
  });

  testWidgets('en busy deshabilita selector y acciones del formulario', (
    tester,
  ) async {
    final titleController = TextEditingController();
    addTearDown(titleController.dispose);

    final documentType = buildDocumentType();

    await tester.pumpWidget(
      buildSection(
        documentTypes: [documentType],
        selectedDocumentTypeCode: 'LEASE',
        selectedDocumentType: documentType,
        titleController: titleController,
        metadataControllers: {},
        booleanMetadataValues: {'signed': null},
        isBusy: true,
      ),
    );

    final typeDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(typeDropdown.onChanged, isNull);

    final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    for (final button in buttons) {
      expect(button.onPressed, isNull);
    }
  });
}
