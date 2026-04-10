import 'package:flutter_test/flutter_test.dart';

import 'package:feature_documents/feature_documents.dart';

void main() {
  test('load usa query actual y publica mensaje contextual', () async {
    final repository = _RecordingDocumentsRepository();
    final viewModel = DocumentsViewModel(repository);

    viewModel.updateQuery(' contrato ');
    await viewModel.load();

    expect(repository.queries, [' contrato ']);
    expect(viewModel.overview?.activeDocuments, 1);
    expect(viewModel.message, 'Resultados para " contrato ".');
    expect(viewModel.isBusy, isFalse);
  });

  test('load informa error y conserva overview nulo si el repositorio falla', () async {
    final viewModel = DocumentsViewModel(_FailingDocumentsRepository());

    await viewModel.load();

    expect(viewModel.overview, isNull);
    expect(
      viewModel.message,
      'No se pudo cargar el repositorio documental.',
    );
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingDocumentsRepository implements DocumentsRepository {
  final List<String> queries = <String>[];

  @override
  Future<DocumentsOverview> loadOverview({String query = ''}) async {
    queries.add(query);
    return const DocumentsOverview(
      activeDocuments: 1,
      pendingClassification: 0,
      documentsOnHold: 0,
      storageUsedLabel: '1 item',
      recentDocuments: [
        DocumentRecord(
          id: 'doc-1',
          title: 'Contrato maestro',
          typeLabel: 'Contrato',
          classificationLabel: 'Confidencial',
          statusLabel: 'Vigente',
          ownerLabel: 'Legales',
          updatedAtLabel: 'Hoy',
          onLegalHold: false,
        ),
      ],
    );
  }
}

final class _FailingDocumentsRepository implements DocumentsRepository {
  @override
  Future<DocumentsOverview> loadOverview({String query = ''}) {
    throw Exception('backend down');
  }
}
