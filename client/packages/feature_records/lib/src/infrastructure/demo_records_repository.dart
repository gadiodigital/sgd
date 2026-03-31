import '../domain/records_overview.dart';
import '../domain/records_repository.dart';

/// Supplies demo retention data until the records APIs are consumed.
final class DemoRecordsRepository implements RecordsRepository {
  @override
  Future<RecordsOverview> loadOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    return const RecordsOverview(
      policiesInUse: 12,
      legalHoldsActive: 7,
      dueThisWeek: 19,
      pendingReview: 4,
      dispositionQueue: [
        DispositionItem(
          documentId: 'demo-1',
          documentTitle: 'Contrato marco proveedores 2020',
          actionCode: 'ARCHIVE',
          actionLabel: 'Archivar',
          dueDateLabel: '22 Mar 2026',
          hasLegalHold: false,
        ),
        DispositionItem(
          documentId: 'demo-2',
          documentTitle: 'Expediente judicial 4312',
          actionCode: 'DELETE',
          actionLabel: 'Bloqueado',
          dueDateLabel: 'En hold',
          hasLegalHold: true,
        ),
        DispositionItem(
          documentId: 'demo-3',
          documentTitle: 'KYC cliente premium 2018',
          actionCode: 'DELETE',
          actionLabel: 'Eliminar',
          dueDateLabel: '24 Mar 2026',
          hasLegalHold: false,
        ),
      ],
    );
  }

  @override
  Future<void> executeDisposition(String documentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}
