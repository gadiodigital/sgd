import 'document_record.dart';

/// Aggregates key document KPIs and recent document activity.
final class DocumentsOverview {
  const DocumentsOverview({
    required this.activeDocuments,
    required this.pendingClassification,
    required this.documentsOnHold,
    required this.storageUsedLabel,
    required this.recentDocuments,
  });

  final int activeDocuments;
  final int pendingClassification;
  final int documentsOnHold;
  final String storageUsedLabel;
  final List<DocumentRecord> recentDocuments;
}
