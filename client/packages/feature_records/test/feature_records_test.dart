import 'package:flutter_test/flutter_test.dart';

import 'package:feature_records/feature_records.dart';

void main() {
  test('loads records overview data', () async {
    final viewModel = RecordsViewModel(_FakeRecordsRepository());

    await viewModel.load();

    expect(viewModel.overview?.policiesInUse, 3);
    expect(viewModel.overview?.dispositionQueue.first.actionLabel, 'Archivar');
    expect(viewModel.filteredQueue.length, 2);

    viewModel.updateQueueFilter(RecordsQueueFilter.legalHold);
    expect(viewModel.filteredQueue.single.hasLegalHold, isTrue);
  });
}

final class _FakeRecordsRepository implements RecordsRepository {
  @override
  Future<RecordsOverview> loadOverview() async {
    return const RecordsOverview(
      policiesInUse: 3,
      legalHoldsActive: 1,
      dueThisWeek: 2,
      pendingReview: 1,
      dispositionQueue: [
        DispositionItem(
          documentId: 'doc-1',
          documentTitle: 'Expediente',
          actionCode: 'ARCHIVE',
          actionLabel: 'Archivar',
          dueDateLabel: 'Hoy',
          hasLegalHold: false,
        ),
        DispositionItem(
          documentId: 'doc-2',
          documentTitle: 'Contrato con hold',
          actionCode: 'REVIEW',
          actionLabel: 'Revisar',
          dueDateLabel: 'Mañana',
          hasLegalHold: true,
        ),
      ],
    );
  }

  @override
  Future<void> executeDisposition(String documentId) async {}
}
