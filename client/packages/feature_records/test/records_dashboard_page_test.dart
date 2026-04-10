import 'package:feature_records/feature_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra limpia selecciona gestiona y confirma disposicion ejecutable',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DashboardRecordsRepository();
      final viewModel = RecordsViewModel(repository);
      DispositionItem? selectedItem;
      DispositionItem? managedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: RecordsDashboardPage(
              viewModel: viewModel,
              onItemSelected: (_, item) async {
                selectedItem = item;
              },
              onManageRequested: (_, item) async {
                managedItem = item;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Records y cumplimiento'), findsOneWidget);
      expect(repository.loadCalls, 1);
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('3 visibles de 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'expediente');
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('1 visibles de 3'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Ejecutables'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
      expect(find.text('0 visibles de 3'), findsOneWidget);
      expect(
        find.text('No hay items de disposicion para los filtros actuales.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('3 visibles de 3'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Documento').first);
      await tester.pumpAndSettle();
      expect(selectedItem?.documentId, 'doc-1');

      await tester.tap(find.widgetWithText(OutlinedButton, 'Gestionar').first);
      await tester.pumpAndSettle();
      expect(managedItem?.documentId, 'doc-1');

      await tester.tap(find.widgetWithText(FilledButton, 'Ejecutar').first);
      await tester.pumpAndSettle();
      expect(find.text('Confirmar disposición'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(repository.executedDocumentIds, ['doc-1']);
      expect(repository.loadCalls, 2);
      expect(viewModel.message, 'Disposición ejecutada correctamente.');
    },
  );
}

final class _DashboardRecordsRepository implements RecordsRepository {
  int loadCalls = 0;
  final List<String> executedDocumentIds = <String>[];

  @override
  Future<RecordsOverview> loadOverview() async {
    loadCalls++;
    return const RecordsOverview(
      policiesInUse: 4,
      legalHoldsActive: 1,
      dueThisWeek: 3,
      pendingReview: 1,
      dispositionQueue: [
        DispositionItem(
          documentId: 'doc-1',
          documentTitle: 'Contrato marco 2020',
          actionCode: 'ARCHIVE',
          actionLabel: 'Archivar',
          dueDateLabel: 'Hoy',
          hasLegalHold: false,
        ),
        DispositionItem(
          documentId: 'doc-2',
          documentTitle: 'Expediente judicial 4312',
          actionCode: 'DELETE',
          actionLabel: 'Bloqueado',
          dueDateLabel: 'En hold',
          hasLegalHold: true,
        ),
        DispositionItem(
          documentId: 'doc-3',
          documentTitle: 'KYC cliente premium',
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
