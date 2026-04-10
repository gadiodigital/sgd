import 'package:feature_search/feature_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('busca aplica preset guarda y reutiliza busquedas', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardSearchRepository();
    final viewModel = SearchViewModel(repository);
    SearchResultItem? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
        ),
        home: Scaffold(
          body: SearchDashboardPage(
            viewModel: viewModel,
            onResultSelected: (_, result) async {
              selectedResult = result;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Búsqueda'), findsOneWidget);
    expect(repository.requests.length, 1);
    expect(repository.requests.first.query, '');
    expect(find.text('Resultados'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar'), 'contrato');
    await tester.enterText(
      find.widgetWithText(TextField, 'Tipo documental'),
      'contract',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(repository.requests.last.query, 'contrato');
    expect(repository.requests.last.filters.documentTypeCode, 'CONTRACT');
    expect(find.text('Contrato comercial'), findsOneWidget);

    await tester.tap(find.text('Guardar actual'));
    await tester.pumpAndSettle();
    expect(find.text('Busqueda: contrato'), findsOneWidget);

    await tester.tap(find.text('Con legal hold'));
    await tester.pumpAndSettle();
    expect(repository.requests.last.filters.onlyOnLegalHold, isTrue);

    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();
    expect(repository.requests.last.filters.onlyOnLegalHold, isFalse);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(repository.requests.last.query, '');
    expect(repository.requests.last.filters.documentTypeCode, '');

    await tester.tap(find.text('Busqueda: contrato'));
    await tester.pumpAndSettle();
    expect(repository.requests.last.query, 'contrato');
    expect(repository.requests.last.filters.documentTypeCode, 'CONTRACT');

    await tester.tap(find.text('Contrato comercial'));
    await tester.pumpAndSettle();
    expect(selectedResult?.id, 'doc-1');
  });
}

final class _DashboardSearchRepository implements SearchRepository {
  final List<_SearchRequest> requests = <_SearchRequest>[];

  @override
  Future<SearchOverview> search({
    required String query,
    required SearchFilters filters,
  }) async {
    requests.add(_SearchRequest(query: query, filters: filters));

    final normalizedQuery = query.trim().toLowerCase();
    final matchesContract = normalizedQuery.isEmpty || 'contrato comercial'.contains(normalizedQuery);
    final matchesType = filters.documentTypeCode.isEmpty || filters.documentTypeCode == 'CONTRACT';
    final matchesHold = !filters.onlyOnLegalHold || true;
    final results = matchesContract && matchesType && matchesHold
        ? const [
            SearchResultItem(
              id: 'doc-1',
              title: 'Contrato comercial',
              documentTypeCode: 'CONTRACT',
              status: 'ACTIVE',
              updatedAtLabel: 'Hoy',
            ),
          ]
        : const <SearchResultItem>[];

    return SearchOverview(
      query: query,
      filters: filters,
      resultsCount: results.length,
      results: results,
    );
  }
}

final class _SearchRequest {
  const _SearchRequest({required this.query, required this.filters});

  final String query;
  final SearchFilters filters;
}
