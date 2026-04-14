import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/document_metadata_field.dart';
import 'package:gdms_app/src/documents/presentation/document_metadata_fields_section.dart';

void main() {
  Widget buildSection({
    required List<DocumentMetadataField> fields,
    required Map<String, TextEditingController> controllers,
    required Map<String, String?> booleanValues,
    required void Function(String key, String? value) onBooleanChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Form(
          child: DocumentMetadataFieldsSection(
            fields: fields,
            controllers: controllers,
            booleanValues: booleanValues,
            onBooleanChanged: onBooleanChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('no renderiza nada cuando no hay campos', (tester) async {
    await tester.pumpWidget(
      buildSection(
        fields: const [],
        controllers: {},
        booleanValues: {},
        onBooleanChanged: (_, _) {},
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.text('Metadatos tipados'), findsNothing);
  });

  testWidgets('renderiza campos tipados y callbacks de seleccion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final titleController = TextEditingController();
    final payloadController = TextEditingController();
    addTearDown(titleController.dispose);
    addTearDown(payloadController.dispose);

    final changedValues = <String, String?>{};

    await tester.pumpWidget(
      buildSection(
        fields: const [
          DocumentMetadataField(
            key: 'title',
            label: 'Titulo legal',
            type: DocumentMetadataFieldType.text,
            required: true,
            maxLength: 30,
          ),
          DocumentMetadataField(
            key: 'signedAt',
            label: 'Fecha',
            type: DocumentMetadataFieldType.date,
            required: false,
          ),
          DocumentMetadataField(
            key: 'approved',
            label: 'Aprobado',
            type: DocumentMetadataFieldType.boolean,
            required: false,
          ),
          DocumentMetadataField(
            key: 'category',
            label: 'Categoria',
            type: DocumentMetadataFieldType.list,
            required: true,
            options: ['Legal', 'Fiscal'],
          ),
          DocumentMetadataField(
            key: 'payload',
            label: 'Payload tecnico',
            type: DocumentMetadataFieldType.json,
            required: false,
          ),
        ],
        controllers: {'title': titleController, 'payload': payloadController},
        booleanValues: {'approved': null, 'category': null},
        onBooleanChanged: (key, value) => changedValues[key] = value,
      ),
    );

    expect(find.text('Metadatos tipados'), findsOneWidget);
    expect(find.text('Titulo legal'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Payload tecnico'), findsOneWidget);
    expect(find.text('Máximo 30 caracteres'), findsOneWidget);
    expect(find.text('Formato AAAA-MM-DD'), findsOneWidget);
    expect(find.text('Seleccione verdadero o falso'), findsOneWidget);
    expect(find.text('Seleccione una opción'), findsOneWidget);
    expect(find.text('Objeto, lista o valor JSON válido'), findsOneWidget);

    final dropdowns = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .toList(growable: false);
    dropdowns.first.onChanged?.call('true');
    dropdowns.last.onChanged?.call('Fiscal');

    expect(changedValues, {'approved': 'true', 'category': 'Fiscal'});
  });
}
