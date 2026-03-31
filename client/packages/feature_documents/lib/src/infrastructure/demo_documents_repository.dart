import '../domain/document_record.dart';
import '../domain/documents_overview.dart';
import '../domain/documents_repository.dart';

/// Supplies demo data while the documents API is integrated.
final class DemoDocumentsRepository implements DocumentsRepository {
  @override
  Future<DocumentsOverview> loadOverview({String query = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    const sampleDocuments = [
      DocumentRecord(
        id: 'demo-1',
        title: 'Contrato de locacion - Palermo 2331',
        typeLabel: 'Contrato',
        classificationLabel: 'Confidencial',
        statusLabel: 'Vigente',
        ownerLabel: 'Legales',
        updatedAtLabel: 'Hace 12 min',
        onLegalHold: false,
      ),
      DocumentRecord(
        id: 'demo-2',
        title: 'Legajo societario - Delta SA',
        typeLabel: 'Societario',
        classificationLabel: 'Reservado',
        statusLabel: 'Auditado',
        ownerLabel: 'Corporate',
        updatedAtLabel: 'Hace 43 min',
        onLegalHold: true,
      ),
      DocumentRecord(
        id: 'demo-3',
        title: 'KYC comprador - expediente 482',
        typeLabel: 'AML/KYC',
        classificationLabel: 'Sensible',
        statusLabel: 'En revision',
        ownerLabel: 'Inmobiliaria',
        updatedAtLabel: 'Hoy 09:10',
        onLegalHold: false,
      ),
    ];

    final normalizedQuery = query.trim().toLowerCase();
    final filteredDocuments = normalizedQuery.isEmpty
        ? sampleDocuments
        : sampleDocuments
              .where(
                (document) =>
                    document.title.toLowerCase().contains(normalizedQuery) ||
                    document.typeLabel.toLowerCase().contains(normalizedQuery),
              )
              .toList();

    return DocumentsOverview(
      activeDocuments: filteredDocuments.length,
      pendingClassification: 18,
      documentsOnHold: filteredDocuments.where((item) => item.onLegalHold).length,
      storageUsedLabel: '${filteredDocuments.length} items',
      recentDocuments: filteredDocuments,
    );
  }
}
