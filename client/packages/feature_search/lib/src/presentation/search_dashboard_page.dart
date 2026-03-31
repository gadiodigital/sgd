import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/search_view_model.dart';
import '../domain/search_preset.dart';
import '../domain/search_result_item.dart';
import '../domain/saved_search.dart';

/// Renders the dedicated document search workspace.
class SearchDashboardPage extends StatefulWidget {
  const SearchDashboardPage({
    required this.viewModel,
    this.onResultSelected,
    super.key,
  });

  final SearchViewModel viewModel;
  final Future<void> Function(BuildContext context, SearchResultItem result)?
      onResultSelected;

  @override
  State<SearchDashboardPage> createState() => _SearchDashboardPageState();
}

class _SearchDashboardPageState extends State<SearchDashboardPage> {
  late final TextEditingController _queryController;
  late final TextEditingController _documentTypeController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.viewModel.query);
    _documentTypeController = TextEditingController(
      text: widget.viewModel.documentTypeCode,
    );
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _documentTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final overview = widget.viewModel.overview;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const GdmsPageHeader(
              title: 'Búsqueda',
              subtitle: 'Consulta full text y filtros rápidos sobre el repositorio.',
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              subtitle: widget.viewModel.message,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar',
                            hintText: 'Título, tipo documental o palabra clave',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (_) => _runSearch(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _runSearch,
                        child: const Text('Buscar'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _saveCurrentSearch,
                        child: const Text('Guardar actual'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.viewModel.presets
                        .map(
                          (preset) => ActionChip(
                            label: Text(preset.label),
                            onPressed: () => _applyPreset(preset),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  if (widget.viewModel.savedSearches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.viewModel.savedSearches
                          .map(
                            (savedSearch) => InputChip(
                              label: Text(savedSearch.label),
                              onPressed: () => _applySavedSearch(savedSearch),
                              onDeleted: () =>
                                  widget.viewModel.removeSavedSearch(savedSearch),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _documentTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo documental',
                            hintText: 'Ej: CONTRACT',
                          ),
                          onSubmitted: (_) => _runSearch(),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(widget.viewModel.status),
                          initialValue: widget.viewModel.status.isEmpty
                              ? ''
                              : widget.viewModel.status,
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Todos')),
                            DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                            DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                            DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                            DropdownMenuItem(value: 'DISPOSED', child: Text('Disposed')),
                          ],
                          onChanged: (value) {
                            widget.viewModel.updateStatus(value ?? '');
                            _runSearch();
                          },
                        ),
                      ),
                      FilterChip(
                        label: const Text('Solo legal hold'),
                        selected: widget.viewModel.onlyOnLegalHold,
                        onSelected: (value) {
                          widget.viewModel.updateOnlyOnLegalHold(value);
                          _runSearch();
                        },
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (overview != null)
              SizedBox(
                width: 220,
                child: GdmsMetricTile(
                  label: 'Resultados',
                  value: '${overview.resultsCount}',
                  color: const Color(0xFF6A1B9A),
                ),
              ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Resultados',
              child: (overview == null || overview.results.isEmpty)
                  ? const Text('Todavía no hay resultados para mostrar.')
                  : Column(
                      children: overview.results
                          .map(
                            (result) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: widget.onResultSelected == null
                                    ? null
                                    : () => widget.onResultSelected!(
                                        context,
                                        result,
                                      ),
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                title: Text(result.title),
                                subtitle: Text(
                                  '${result.documentTypeCode} · ${result.updatedAtLabel}',
                                ),
                                trailing: GdmsStatusBadge(
                                  label: result.status,
                                  tone: GdmsStatusTone.info,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runSearch() async {
    widget.viewModel.updateQuery(_queryController.text);
    widget.viewModel.updateDocumentTypeCode(_documentTypeController.text);
    await widget.viewModel.load();
  }

  Future<void> _clearFilters() async {
    _queryController.clear();
    _documentTypeController.clear();
    widget.viewModel.clearFilters();
    await _runSearch();
  }

  Future<void> _applyPreset(SearchPreset preset) async {
    widget.viewModel.applyPreset(preset);
    _queryController.text = widget.viewModel.query;
    _documentTypeController.text = widget.viewModel.documentTypeCode;
    await widget.viewModel.load();
  }

  Future<void> _applySavedSearch(SavedSearch savedSearch) async {
    widget.viewModel.applySavedSearch(savedSearch);
    _queryController.text = widget.viewModel.query;
    _documentTypeController.text = widget.viewModel.documentTypeCode;
    await widget.viewModel.load();
  }

  void _saveCurrentSearch() {
    widget.viewModel.updateQuery(_queryController.text);
    widget.viewModel.updateDocumentTypeCode(_documentTypeController.text);
    widget.viewModel.saveCurrentSearch();
  }
}
