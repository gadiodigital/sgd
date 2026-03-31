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

  testWidgets('renderiza campos tipados y callback booleano', (tester) async {
    final titleController = TextEditingController();
    addTearDown(titleController.dispose);

    String? latestBooleanValue;

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
        ],
        controllers: {'title': titleController},
        booleanValues: {'approved': null},
        onBooleanChanged: (_, value) => latestBooleanValue = value,
      ),
    );

    expect(find.text('Metadatos tipados'), findsOneWidget);
    expect(find.text('Titulo legal'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('Máximo 30 caracteres'), findsOneWidget);
    expect(find.text('Formato AAAA-MM-DD'), findsOneWidget);
    expect(find.text('Seleccione verdadero o falso'), findsOneWidget);

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).last,
    );
    dropdown.onChanged?.call('true');

    expect(latestBooleanValue, 'true');
  });
}
