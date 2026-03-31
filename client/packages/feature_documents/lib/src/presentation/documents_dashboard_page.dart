import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../application/documents_view_model.dart';
import '../domain/document_record.dart';
import '../infrastructure/demo_documents_repository.dart';

/// Presents the main document repository KPIs and recent movement.
class DocumentsDashboardPage extends StatefulWidget {
  const DocumentsDashboardPage({
    super.key,
    DocumentsViewModel? viewModel,
    Future<void> Function(BuildContext context)? onUploadRequested,
    Future<void> Function(BuildContext context)? onScanRequested,
    Future<void> Function(BuildContext context, DocumentRecord document)?
    onDocumentSelected,
  }) : _viewModel = viewModel,
       _onUploadRequested = onUploadRequested,
       _onScanRequested = onScanRequested,
       _onDocumentSelected = onDocumentSelected;

  final DocumentsViewModel? _viewModel;
  final Future<void> Function(BuildContext context)? _onUploadRequested;
  final Future<void> Function(BuildContext context)? _onScanRequested;
  final Future<void> Function(BuildContext context, DocumentRecord document)?
  _onDocumentSelected;

  @override
  State<DocumentsDashboardPage> createState() => _DocumentsDashboardPageState();
}

class _DocumentsDashboardPageState extends State<DocumentsDashboardPage> {
  late final DocumentsViewModel _viewModel;
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget._viewModel ?? DocumentsViewModel(DemoDocumentsRepository());
    _queryController = TextEditingController(text: _viewModel.query);
    _viewModel.load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final overview = _viewModel.overview;

        if (overview == null && _viewModel.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (overview == null) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GdmsPageHeader(
              title: 'Repositorio documental',
              subtitle:
                  'Supervisa volumen, clasificacion, legal holds y actividad '
                  'reciente del repositorio multi-tenant.',
              trailing:
                  widget._onUploadRequested == null &&
                      widget._onScanRequested == null
                  ? null
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (widget._onUploadRequested != null)
                          FilledButton.icon(
                            onPressed: () =>
                                widget._onUploadRequested!(context),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Subir documento'),
                          ),
                        if (widget._onScanRequested != null)
                          OutlinedButton.icon(
                            onPressed: () => widget._onScanRequested!(context),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Escanear documento'),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            GdmsSectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar documentos',
                        hintText: 'Titulo o tipo documental',
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
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Documentos activos',
                    value: '${overview.activeDocuments}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Sin clasificar',
                    value: '${overview.pendingClassification}',
                    color: const Color(0xFFC4811C),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Con legal hold',
                    value: '${overview.documentsOnHold}',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: GdmsMetricTile(
                    label: 'Capacidad usada',
                    value: overview.storageUsedLabel,
                    color: const Color(0xFF1E8A5B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GdmsSectionCard(
              title: 'Actividad reciente',
              subtitle: _viewModel.message,
              child: Column(
                children: overview.recentDocuments
                    .map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: widget._onDocumentSelected == null
                              ? null
                              : () => widget._onDocumentSelected!(
                                  context,
                                  document,
                                ),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(document.title),
                          subtitle: Text(
                            '${document.typeLabel} · ${document.ownerLabel} · '
                            '${document.updatedAtLabel}',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              GdmsStatusBadge(
                                label: document.statusLabel,
                                tone: GdmsStatusTone.info,
                              ),
                              GdmsStatusBadge(
                                label: document.classificationLabel,
                                tone: document.onLegalHold
                                    ? GdmsStatusTone.warning
                                    : GdmsStatusTone.neutral,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runSearch() async {
    _viewModel.updateQuery(_queryController.text);
    await _viewModel.load();
  }

  Future<void> _clearSearch() async {
    _queryController.clear();
    _viewModel.updateQuery('');
    await _viewModel.load();
  }
}
