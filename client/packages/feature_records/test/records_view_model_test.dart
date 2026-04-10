import 'package:feature_records/feature_records.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load sincroniza overview y filtros funcionan por query y legal hold', () async {
    final repository = _RecordingRecordsRepository();
    final viewModel = RecordsViewModel(repository);

    await viewModel.load();

    expect(repository.loadCalls, 1);
    expect(viewModel.overview?.policiesInUse, 3);
    expect(viewModel.filteredQueue.length, 3);
    expect(viewModel.message, 'Cola de disposicion sincronizada.');

    viewModel.updateQuery('contrato');
    expect(viewModel.filteredQueue.map((item) => item.documentId), ['doc-1']);

    viewModel.updateQuery('');
    viewModel.updateQueueFilter(RecordsQueueFilter.legalHold);
    expect(viewModel.filteredQueue.map((item) => item.documentId), ['doc-2']);

    viewModel.clearFilters();
    expect(viewModel.query, '');
    expect(viewModel.queueFilter, RecordsQueueFilter.all);
    expect(viewModel.filteredQueue.length, 3);
  });

  test('executeDisposition recarga overview y publica mensaje de exito', () async {
    final repository = _RecordingRecordsRepository();
    final viewModel = RecordsViewModel(repository);

    await viewModel.load();
    await viewModel.executeDisposition('doc-1');

    expect(repository.executedDocumentIds, ['doc-1']);
    expect(repository.loadCalls, 2);
    expect(viewModel.message, 'Disposición ejecutada correctamente.');
  });

  test('executeDisposition informa error cuando el repositorio falla', () async {
    final viewModel = RecordsViewModel(_FailingExecuteRecordsRepository());

    await viewModel.load();
    await viewModel.executeDisposition('doc-9');

    expect(
      viewModel.message,
      'No se pudo ejecutar la disposición solicitada.',
    );
    expect(viewModel.isBusy, isFalse);
  });
}

final class _RecordingRecordsRepository implements RecordsRepository {
  int loadCalls = 0;
  final List<String> executedDocumentIds = <String>[];

  @override
  Future<RecordsOverview> loadOverview() async {
    loadCalls++;
    return const RecordsOverview(
      policiesInUse: 3,
      legalHoldsActive: 1,
      dueThisWeek: 2,
      pendingReview: 1,
      dispositionQueue: [
        DispositionItem(
          documentId: 'doc-1',
          documentTitle: 'Contrato marco',
          actionCode: 'ARCHIVE',
          actionLabel: 'Archivar',
          dueDateLabel: 'Hoy',
          hasLegalHold: false,
        ),
        DispositionItem(
          documentId: 'doc-2',
          documentTitle: 'Expediente bloqueado',
          actionCode: 'DELETE',
          actionLabel: 'Bloqueado',
          dueDateLabel: 'En hold',
          hasLegalHold: true,
        ),
        DispositionItem(
          documentId: 'doc-3',
          documentTitle: 'KYC vencido',
          actionCode: 'REVIEW',
          actionLabel: 'Revisar',
          dueDateLabel: 'Mañana',
          hasLegalHold: false,
        ),
      ],
    );
  }

  @override
  Future<void> executeDisposition(String documentId) async {
    executedDocumentIds.add(documentId);
  }
}

final class _FailingExecuteRecordsRepository implements RecordsRepository {
  @override
  Future<RecordsOverview> loadOverview() async {
    return const RecordsOverview(
      policiesInUse: 1,
      legalHoldsActive: 0,
      dueThisWeek: 1,
      pendingReview: 0,
      dispositionQueue: [
        DispositionItem(
          documentId: 'doc-9',
          documentTitle: 'Documento listo',
          actionCode: 'ARCHIVE',
          actionLabel: 'Archivar',
          dueDateLabel: 'Hoy',
          hasLegalHold: false,
        ),
      ],
    );
  }

  @override
  Future<void> executeDisposition(String documentId) {
    throw Exception('cannot execute');
  }
}
