import 'package:feature_signature/feature_signature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filtra selecciona completa y cancela solicitudes de firma',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DashboardSignatureRepository();
      final viewModel = SignatureViewModel(repository);
      SignatureEnvelopeItem? selectedItem;
      var createTapped = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: SignatureDashboardPage(
              viewModel: viewModel,
              onCreateRequested: (_) async => createTapped++,
              onEnvelopeSelected: (_, item) async {
                selectedItem = item;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Firma'), findsOneWidget);
      expect(repository.loadCalls, 1);
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('3 visibles de 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'gomez');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Completadas'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));

      await tester.tap(find.text('Solicitar firma'));
      await tester.pumpAndSettle();
      expect(createTapped, 1);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Documento').first);
      await tester.pumpAndSettle();
      expect(selectedItem?.id, 'sig-1');

      await tester.tap(find.widgetWithText(FilledButton, 'Completar').first);
      await tester.pumpAndSettle();
      expect(repository.completedEnvelopeIds, ['sig-1']);
      expect(viewModel.message, 'Solicitud de firma completada correctamente.');

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar').first);
      await tester.pumpAndSettle();
      expect(find.text('Cancelar solicitud de firma'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Cancelar solicitud'),
        ).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField).last, 'abc');
      await tester.pumpAndSettle();
      expect(repository.cancelledEnvelopeIds, isEmpty);
      expect(find.text('Cancelar solicitud de firma'), findsOneWidget);
      expect(find.text('Minimo 5 caracteres.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Firmante desactualizado');
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Cancelar solicitud'),
        ).onPressed,
        isNotNull,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar solicitud'));
      await tester.pumpAndSettle();

      expect(repository.cancelledEnvelopeIds, ['sig-1']);
      expect(repository.cancelReasons, ['Firmante desactualizado']);
      expect(viewModel.message, 'Solicitud de firma cancelada correctamente.');
    },
  );
}

final class _DashboardSignatureRepository implements SignatureRepository {
  int loadCalls = 0;
  final List<String> completedEnvelopeIds = <String>[];
  final List<String> cancelledEnvelopeIds = <String>[];
  final List<String> cancelReasons = <String>[];

  @override
  Future<void> cancelSignature(
    String envelopeId, {
    required String reason,
  }) async {
    cancelledEnvelopeIds.add(envelopeId);
    cancelReasons.add(reason);
  }

  @override
  Future<void> completeSignature(
    String envelopeId, {
    String? externalReference,
  }) async {
    completedEnvelopeIds.add(envelopeId);
  }

  @override
  Future<SignatureOverview> loadOverview({String? documentId}) async {
    loadCalls++;
    return const SignatureOverview(
      pendingRequests: 1,
      signedRequests: 1,
      digitalRequests: 2,
      envelopes: [
        SignatureEnvelopeItem(
          id: 'sig-1',
          documentId: 'doc-1',
          signerDisplayName: 'Estudio Perez',
          signerEmail: 'firma@cliente.com',
          signatureLevel: 'DIGITAL',
          providerCode: 'INTERNAL',
          status: 'PENDING',
          requestedAtLabel: 'Hoy',
          dueAtLabel: 'Mañana',
        ),
        SignatureEnvelopeItem(
          id: 'sig-2',
          documentId: 'doc-2',
          signerDisplayName: 'Cliente Gomez',
          signerEmail: 'cliente@gomez.com',
          signatureLevel: 'ELECTRONIC',
          providerCode: 'INTERNAL',
          status: 'COMPLETED',
          requestedAtLabel: 'Ayer',
          dueAtLabel: 'Sin vencimiento',
        ),
        SignatureEnvelopeItem(
          id: 'sig-3',
          documentId: 'doc-3',
          signerDisplayName: 'Proveedor Norte',
          signerEmail: 'norte@proveedor.com',
          signatureLevel: 'DIGITAL',
          providerCode: 'INTERNAL',
          status: 'CANCELLED',
          requestedAtLabel: 'Hace dos dias',
          dueAtLabel: 'Sin vencimiento',
        ),
      ],
    );
  }

  @override
  Future<void> requestSignature({
    required String documentId,
    required String signerDisplayName,
    required String signerEmail,
    required String signatureLevel,
    String? providerCode,
    DateTime? dueAtUtc,
  }) async {}
}
