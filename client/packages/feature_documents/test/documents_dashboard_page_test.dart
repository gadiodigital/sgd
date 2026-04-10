import 'package:feature_documents/feature_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('busca limpia y dispara callbacks operativos', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardDocumentsRepository();
    final viewModel = DocumentsViewModel(repository);
    var uploadTapped = 0;
    var scanTapped = 0;
    DocumentRecord? selectedDocument;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: DocumentsDashboardPage(
            viewModel: viewModel,
            onUploadRequested: (_) async => uploadTapped++,
            onScanRequested: (_) async => scanTapped++,
            onDocumentSelected: (_, document) async {
              selectedDocument = document;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Repositorio documental'), findsOneWidget);
    expect(repository.queries, ['']);
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'societaria');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(repository.queries, ['', 'societaria']);
    expect(find.text('Resultados para "societaria".'), findsOneWidget);

    expect(find.byType(ListTile), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(selectedDocument?.id, 'doc-1');

    await tester.tap(find.text('Subir documento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear documento'));
    await tester.pumpAndSettle();

    expect(uploadTapped, 1);
    expect(scanTapped, 1);

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(repository.queries, ['', 'societaria', '']);
    expect(find.text('Repositorio documental actualizado.'), findsOneWidget);
  });
}

final class _DashboardDocumentsRepository implements DocumentsRepository {
  final List<String> queries = <String>[];

  @override
  Future<DocumentsOverview> loadOverview({String query = ''}) async {
    queries.add(query);
    final normalized = query.trim().toLowerCase();
    final documents = normalized == 'societaria'
        ? _documents.where((item) => item.title.toLowerCase().contains(normalized)).toList()
        : _documents;

    return DocumentsOverview(
      activeDocuments: documents.length,
      pendingClassification: 2,
      documentsOnHold: documents.where((item) => item.onLegalHold).length,
      storageUsedLabel: '${documents.length} items',
      recentDocuments: documents,
    );
  }

  static const List<DocumentRecord> _documents = [
    DocumentRecord(
      id: 'doc-1',
      title: 'Acta societaria',
      typeLabel: 'Societario',
      classificationLabel: 'Reservado',
      statusLabel: 'Vigente',
      ownerLabel: 'Corporate',
      updatedAtLabel: 'Hoy',
      onLegalHold: false,
    ),
    DocumentRecord(
      id: 'doc-2',
      title: 'Contrato alquiler',
      typeLabel: 'Contrato',
      classificationLabel: 'Confidencial',
      statusLabel: 'Auditado',
      ownerLabel: 'Legales',
      updatedAtLabel: 'Ayer',
      onLegalHold: true,
    ),
  ];
}
