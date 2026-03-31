import 'documents_overview.dart';

/// Defines the read contract for the documents dashboard.
abstract interface class DocumentsRepository {
  Future<DocumentsOverview> loadOverview({String query = ''});
}
