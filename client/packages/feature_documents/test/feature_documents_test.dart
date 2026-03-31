import 'package:flutter_test/flutter_test.dart';

import 'package:feature_documents/feature_documents.dart';

void main() {
  test('loads documents overview data', () async {
    final viewModel = DocumentsViewModel(_FakeDocumentsRepository());

    await viewModel.load();

    expect(viewModel.overview?.activeDocuments, 4);
    expect(viewModel.overview?.recentDocuments.length, 1);
  });
}

final class _FakeDocumentsRepository implements DocumentsRepository {
  @override
  Future<DocumentsOverview> loadOverview({String query = ''}) async {
    return const DocumentsOverview(
      activeDocuments: 4,
      pendingClassification: 1,
      documentsOnHold: 0,
      storageUsedLabel: '1 GB',
      recentDocuments: [
        DocumentRecord(
          id: 'doc-1',
          title: 'Doc',
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
