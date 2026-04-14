import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../auth/application/app_session_view_model.dart';
import '../../documents/domain/document_metadata_field.dart';
import '../../documents/presentation/document_metadata_editor_support.dart';
import '../../documents/presentation/document_metadata_fields_section.dart';
import '../../documents/presentation/upload_document_dialog.dart';
import '../../infrastructure/api/gdms_api_client.dart';
import '../application/document_structure_view_model.dart';
import '../domain/container_node_entry.dart';
import '../domain/container_type_entry.dart';
import '../domain/document_link_option.dart';

class DocumentStructurePage extends StatefulWidget {
  const DocumentStructurePage({
    required this.viewModel,
    required this.apiClient,
    required this.sessionViewModel,
    super.key,
  });

  final DocumentStructureViewModel viewModel;
  final GdmsApiClient apiClient;
  final AppSessionViewModel sessionViewModel;

  @override
  State<DocumentStructurePage> createState() => _DocumentStructurePageState();
}

class _DocumentStructurePageState extends State<DocumentStructurePage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.load());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final selectedContainer = widget.viewModel.selectedContainer;
        return RefreshIndicator(
          onRefresh: widget.viewModel.load,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Header(
                isBusy: widget.viewModel.isBusy,
                canCreateType: widget.viewModel.selectedProjectId != null,
                canCreateRule: widget.viewModel.containerTypes.length >= 2,
                canCreateContainer: widget.viewModel.containerTypes.isNotEmpty,
                canAttachDocument: widget.viewModel.containerAcceptsDocuments(
                  selectedContainer,
                ),
                canUploadDocument: widget.viewModel.containerAcceptsDocuments(
                  selectedContainer,
                ),
                onCreateProject: () => _showProjectDialog(context),
                onCreateType: () => _showTypeDialog(context),
                onCreateRule: () => _showRuleDialog(context),
                onCreateContainer: () => _showContainerDialog(context),
                onAttachDocument: () => _showAttachDocumentDialog(context),
                onUploadDocument: () =>
                    _showUploadDocumentDialog(context, startWithScanner: false),
                onScanDocument: () =>
                    _showUploadDocumentDialog(context, startWithScanner: true),
                onRefresh: widget.viewModel.load,
              ),
              const SizedBox(height: 16),
              if (widget.viewModel.projects.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey(widget.viewModel.selectedProjectId),
                  initialValue: widget.viewModel.selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Proyecto documental',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.viewModel.projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.id,
                          child: Text('${project.code} - ${project.name}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.viewModel.isBusy
                      ? null
                      : (value) {
                          if (value != null) {
                            unawaited(widget.viewModel.selectProject(value));
                          }
                        },
                ),
              if (widget.viewModel.message != null) ...[
                const SizedBox(height: 12),
                Text(widget.viewModel.message!),
              ],
              const SizedBox(height: 16),
              _MetricsRow(
                projects: widget.viewModel.projects.length,
                types: widget.viewModel.containerTypes.length,
                rules: widget.viewModel.rules.length,
                nodes: widget.viewModel.containers.length,
              ),
              const SizedBox(height: 16),
              _TypesAndRulesSection(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              _HierarchySection(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              _SelectedContainerDocumentsSection(viewModel: widget.viewModel),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProjectDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CreateProjectDialog(viewModel: widget.viewModel),
    );
  }

  Future<void> _showTypeDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CreateContainerTypeDialog(viewModel: widget.viewModel),
    );
  }

  Future<void> _showRuleDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CreateRuleDialog(viewModel: widget.viewModel),
    );
  }

  Future<void> _showContainerDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CreateContainerDialog(viewModel: widget.viewModel),
    );
  }

  Future<void> _showAttachDocumentDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AttachDocumentDialog(viewModel: widget.viewModel),
    );
  }

  Future<void> _showUploadDocumentDialog(
    BuildContext context, {
    required bool startWithScanner,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => UploadDocumentDialog(
        apiClient: widget.apiClient,
        sessionViewModel: widget.sessionViewModel,
        startWithScanner: startWithScanner,
        onDocumentUploaded: widget.viewModel.attachDocument,
        onUploaded: () async {},
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isBusy,
    required this.canCreateType,
    required this.canCreateRule,
    required this.canCreateContainer,
    required this.canAttachDocument,
    required this.canUploadDocument,
    required this.onCreateProject,
    required this.onCreateType,
    required this.onCreateRule,
    required this.onCreateContainer,
    required this.onAttachDocument,
    required this.onUploadDocument,
    required this.onScanDocument,
    required this.onRefresh,
  });

  final bool isBusy;
  final bool canCreateType;
  final bool canCreateRule;
  final bool canCreateContainer;
  final bool canAttachDocument;
  final bool canUploadDocument;
  final VoidCallback onCreateProject;
  final VoidCallback onCreateType;
  final VoidCallback onCreateRule;
  final VoidCallback onCreateContainer;
  final VoidCallback onAttachDocument;
  final VoidCallback onUploadDocument;
  final VoidCallback onScanDocument;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        const SizedBox(
          width: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estructura documental',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Configura proyectos, tipos de contenedor, reglas, arboles y documentos vinculados.',
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => unawaited(onRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : onCreateProject,
              icon: const Icon(Icons.add_business),
              label: const Text('Proyecto'),
            ),
            FilledButton.tonalIcon(
              onPressed: isBusy || !canCreateType ? null : onCreateType,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Tipo'),
            ),
            FilledButton.tonalIcon(
              onPressed: isBusy || !canCreateRule ? null : onCreateRule,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Regla'),
            ),
            FilledButton.tonalIcon(
              onPressed: isBusy || !canCreateContainer
                  ? null
                  : onCreateContainer,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Nodo'),
            ),
            FilledButton.icon(
              onPressed: isBusy || !canAttachDocument ? null : onAttachDocument,
              icon: const Icon(Icons.link),
              label: const Text('Vincular doc'),
            ),
            FilledButton.icon(
              onPressed: isBusy || !canUploadDocument ? null : onUploadDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir al nodo'),
            ),
            FilledButton.icon(
              onPressed: isBusy || !canUploadDocument ? null : onScanDocument,
              icon: const Icon(Icons.scanner_outlined),
              label: const Text('Escanear al nodo'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.projects,
    required this.types,
    required this.rules,
    required this.nodes,
  });

  final int projects;
  final int types;
  final int rules;
  final int nodes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(label: 'Proyectos', value: projects),
        _MetricCard(label: 'Tipos', value: types),
        _MetricCard(label: 'Reglas', value: rules),
        _MetricCard(label: 'Nodos', value: nodes),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypesAndRulesSection extends StatelessWidget {
  const _TypesAndRulesSection({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipos y reglas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (viewModel.containerTypes.isEmpty)
              const Text('No hay tipos de contenedor para este proyecto.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: viewModel.containerTypes
                    .map(
                      (type) => Chip(
                        label: Text(
                          '${type.code}${type.isRootAllowed ? ' root' : ''}${type.acceptsDocuments ? ' docs' : ''}',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            const SizedBox(height: 12),
            if (viewModel.rules.isEmpty)
              const Text('No hay reglas padre-hijo configuradas.')
            else
              ...viewModel.rules.map((rule) {
                final parent = viewModel.findType(rule.parentContainerTypeId);
                final child = viewModel.findType(rule.childContainerTypeId);
                return Text(
                  '${parent?.code ?? rule.parentContainerTypeId} -> ${child?.code ?? rule.childContainerTypeId}',
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _HierarchySection extends StatelessWidget {
  const _HierarchySection({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final roots = viewModel.containers
        .where((node) => node.parentContainerId == null)
        .toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arbol jerarquico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (roots.isEmpty)
              const Text('No hay nodos creados para este proyecto.')
            else
              ...roots.expand((root) => _buildNode(context, root, 0)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNode(
    BuildContext context,
    ContainerNodeEntry node,
    int depth,
  ) {
    final type = viewModel.findType(node.containerTypeId);
    final isSelected = node.id == viewModel.selectedContainerId;
    final children = viewModel.containers
        .where((candidate) => candidate.parentContainerId == node.id)
        .toList(growable: false);
    return [
      Padding(
        padding: EdgeInsets.only(left: depth * 20.0, bottom: 6),
        child: ListTile(
          selected: isSelected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            type?.acceptsDocuments == true
                ? Icons.folder_special_outlined
                : Icons.folder_outlined,
          ),
          title: Text('${node.code} - ${node.name}'),
          subtitle: Text(type?.code ?? 'Tipo desconocido'),
          trailing: isSelected ? const Icon(Icons.check_circle) : null,
          onTap: () => unawaited(viewModel.selectContainer(node.id)),
        ),
      ),
      ...children.expand((child) => _buildNode(context, child, depth + 1)),
    ];
  }
}

class _SelectedContainerDocumentsSection extends StatelessWidget {
  const _SelectedContainerDocumentsSection({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedContainer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected == null
                  ? 'Documentos del nodo'
                  : 'Documentos de ${selected.code}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (selected == null)
              const Text('Selecciona un nodo para ver sus documentos.')
            else if (!viewModel.containerAcceptsDocuments(selected))
              const Text('El nodo seleccionado no acepta documentos.')
            else if (viewModel.selectedContainerDocuments.isEmpty)
              const Text('No hay documentos vinculados a este nodo.')
            else
              ...viewModel.selectedContainerDocuments.map(
                (document) => ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(document.documentTitle),
                  subtitle: Text(
                    '${document.documentTypeCode} - ${document.documentStatus}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Crear proyecto documental',
      viewModel: widget.viewModel,
      formKey: _formKey,
      children: [
        _textField(_codeController, 'Codigo'),
        _textField(_nameController, 'Nombre'),
        _textField(_descriptionController, 'Descripcion', isRequired: false),
      ],
      onSubmit: () async {
        return widget.viewModel.createProject(
          code: _codeController.text,
          name: _nameController.text,
          description: _descriptionController.text,
        );
      },
    );
  }
}

class _CreateContainerTypeDialog extends StatefulWidget {
  const _CreateContainerTypeDialog({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  State<_CreateContainerTypeDialog> createState() =>
      _CreateContainerTypeDialogState();
}

class _CreateContainerTypeDialogState
    extends State<_CreateContainerTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController(text: 'folder');
  final _schemaController = TextEditingController(text: '{}');
  bool _isRootAllowed = false;
  bool _acceptsDocuments = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _iconController.dispose();
    _schemaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Crear tipo de contenedor',
      viewModel: widget.viewModel,
      formKey: _formKey,
      children: [
        _textField(_codeController, 'Codigo'),
        _textField(_nameController, 'Nombre'),
        _textField(_iconController, 'Icono Material'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Puede ser raiz'),
          value: _isRootAllowed,
          onChanged: (value) => setState(() => _isRootAllowed = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Acepta documentos'),
          value: _acceptsDocuments,
          onChanged: (value) => setState(() => _acceptsDocuments = value),
        ),
        _jsonField(_schemaController, 'Esquema de atributos JSON'),
      ],
      onSubmit: () async {
        return widget.viewModel.createContainerType(
          code: _codeController.text,
          name: _nameController.text,
          iconKey: _iconController.text,
          isRootAllowed: _isRootAllowed,
          acceptsDocuments: _acceptsDocuments,
          metadataSchemaJson: _schemaController.text,
        );
      },
    );
  }
}

class _CreateRuleDialog extends StatefulWidget {
  const _CreateRuleDialog({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  State<_CreateRuleDialog> createState() => _CreateRuleDialogState();
}

class _CreateRuleDialogState extends State<_CreateRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _parentTypeId;
  String? _childTypeId;

  @override
  void initState() {
    super.initState();
    _parentTypeId = widget.viewModel.containerTypes.firstOrNull?.id;
    _childTypeId = widget.viewModel.containerTypes.length > 1
        ? widget.viewModel.containerTypes[1].id
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Crear regla padre-hijo',
      viewModel: widget.viewModel,
      formKey: _formKey,
      children: [
        _typeDropdown(
          label: 'Tipo padre',
          value: _parentTypeId,
          types: widget.viewModel.containerTypes,
          onChanged: (value) => setState(() => _parentTypeId = value),
        ),
        _typeDropdown(
          label: 'Tipo hijo',
          value: _childTypeId,
          types: widget.viewModel.containerTypes,
          onChanged: (value) => setState(() => _childTypeId = value),
        ),
      ],
      onSubmit: () async {
        return widget.viewModel.createRule(
          parentContainerTypeId: _parentTypeId!,
          childContainerTypeId: _childTypeId!,
        );
      },
    );
  }
}

class _CreateContainerDialog extends StatefulWidget {
  const _CreateContainerDialog({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  State<_CreateContainerDialog> createState() => _CreateContainerDialogState();
}

class _CreateContainerDialogState extends State<_CreateContainerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _metadataControllers = {};
  final Map<String, String?> _booleanMetadataValues = {};
  String? _containerTypeId;
  String _parentContainerId = '';

  @override
  void initState() {
    super.initState();
    _containerTypeId = widget.viewModel.containerTypes.firstOrNull?.id;
    _syncMetadataEditors();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    for (final controller in _metadataControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadataFields = _metadataFields;
    return _FormDialog(
      title: 'Crear nodo jerarquico',
      viewModel: widget.viewModel,
      formKey: _formKey,
      children: [
        _typeDropdown(
          label: 'Tipo',
          value: _containerTypeId,
          types: widget.viewModel.containerTypes,
          onChanged: (value) {
            setState(() {
              _containerTypeId = value;
              _syncMetadataEditors();
            });
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: _parentContainerId,
          decoration: const InputDecoration(labelText: 'Padre'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Sin padre / raiz')),
            ...widget.viewModel.containers.map(
              (node) => DropdownMenuItem(
                value: node.id,
                child: Text('${node.code} - ${node.name}'),
              ),
            ),
          ],
          onChanged: (value) =>
              setState(() => _parentContainerId = value ?? ''),
        ),
        _textField(_codeController, 'Codigo'),
        _textField(_nameController, 'Nombre'),
        if (metadataFields.isEmpty)
          const Text('El tipo seleccionado no define atributos adicionales.')
        else
          DocumentMetadataFieldsSection(
            title: 'Atributos del nodo',
            subtitle:
                'Los campos se generan desde el esquema del tipo de contenedor.',
            fields: metadataFields,
            controllers: _metadataControllers,
            booleanValues: _booleanMetadataValues,
            onBooleanChanged: _updateBooleanMetadata,
          ),
      ],
      onSubmit: () async {
        final metadataFields = _metadataFields;
        return widget.viewModel.createContainer(
          containerTypeId: _containerTypeId!,
          parentContainerId: _parentContainerId.isEmpty
              ? null
              : _parentContainerId,
          code: _codeController.text,
          name: _nameController.text,
          metadataJson: jsonEncode(
            DocumentMetadataEditorSupport.buildPayload(
              metadataFields,
              _metadataControllers,
              _booleanMetadataValues,
            ),
          ),
        );
      },
    );
  }

  List<DocumentMetadataField> get _metadataFields {
    final containerTypeId = _containerTypeId;
    if (containerTypeId == null) {
      return const <DocumentMetadataField>[];
    }

    final containerType = widget.viewModel.findType(containerTypeId);
    if (containerType == null || containerType.metadataSchema.isEmpty) {
      return const <DocumentMetadataField>[];
    }

    return containerType.metadataSchema.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => DocumentMetadataField.fromJson(
            entry.key,
            Map<String, dynamic>.from(entry.value! as Map),
          ),
        )
        .toList(growable: false);
  }

  void _syncMetadataEditors() {
    DocumentMetadataEditorSupport.syncEditors(
      fields: _metadataFields,
      metadata: const <String, Object?>{},
      controllers: _metadataControllers,
      booleanValues: _booleanMetadataValues,
    );
  }

  void _updateBooleanMetadata(String key, String? value) {
    setState(() {
      _booleanMetadataValues[key] = value;
    });
  }
}

class _AttachDocumentDialog extends StatefulWidget {
  const _AttachDocumentDialog({required this.viewModel});

  final DocumentStructureViewModel viewModel;

  @override
  State<_AttachDocumentDialog> createState() => _AttachDocumentDialogState();
}

class _AttachDocumentDialogState extends State<_AttachDocumentDialog> {
  late final Future<List<DocumentLinkOption>> _documentsFuture;
  String? _selectedDocumentId;
  String? _submitMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = widget.viewModel.loadDocumentOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<DocumentLinkOption>>(
            future: _documentsFuture,
            builder: (context, snapshot) {
              final documents = snapshot.data ?? const <DocumentLinkOption>[];
              _selectedDocumentId ??= documents.firstOrNull?.id;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vincular documento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(child: CircularProgressIndicator())
                  else if (documents.isEmpty)
                    const Text('No hay documentos disponibles para vincular.')
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedDocumentId),
                      initialValue: _selectedDocumentId,
                      decoration: const InputDecoration(
                        labelText: 'Documento',
                        border: OutlineInputBorder(),
                      ),
                      items: documents
                          .map(
                            (document) => DropdownMenuItem(
                              value: document.id,
                              child: Text(
                                '${document.title} - ${document.documentTypeCode}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _selectedDocumentId = value),
                    ),
                  if (_submitMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_submitMessage!),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _selectedDocumentId == null || _isSubmitting
                            ? null
                            : () => unawaited(_attachSelected(context)),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Vincular'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _attachSelected(BuildContext context) async {
    final documentId = _selectedDocumentId;
    if (documentId == null) {
      return;
    }
    final navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    final linked = await widget.viewModel.attachDocument(documentId);
    if (!mounted) {
      return;
    }

    if (linked) {
      navigator.pop();
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitMessage =
          widget.viewModel.message ?? 'No se pudo vincular el documento.';
    });
  }
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.title,
    required this.viewModel,
    required this.formKey,
    required this.children,
    required this.onSubmit,
  });

  final String title;
  final DocumentStructureViewModel viewModel;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<bool> Function() onSubmit;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  String? _submitMessage;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSubmitting || widget.viewModel.isBusy;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: widget.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.children.expand(
                    (child) => [child, const SizedBox(height: 12)],
                  ),
                  if (_submitMessage != null) ...[
                    Text(_submitMessage!),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isBusy
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: isBusy
                            ? null
                            : () => unawaited(_submit(context)),
                        child: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return;
    }
    final navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    final succeeded = await widget.onSubmit();
    if (!mounted) {
      return;
    }

    if (succeeded) {
      navigator.pop();
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitMessage =
          widget.viewModel.message ?? 'No se pudo completar la operacion.';
    });
  }
}

TextFormField _textField(
  TextEditingController controller,
  String label, {
  bool isRequired = true,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      if (!isRequired) return null;
      final normalized = value?.trim() ?? '';
      return normalized.length < 2 ? 'Ingresa un valor valido.' : null;
    },
  );
}

TextFormField _jsonField(TextEditingController controller, String label) {
  return TextFormField(
    controller: controller,
    minLines: 3,
    maxLines: 8,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      try {
        final decoded = jsonDecode(
          (value ?? '').trim().isEmpty ? '{}' : value!,
        );
        return decoded is Map<String, dynamic>
            ? null
            : 'El JSON debe ser un objeto.';
      } catch (_) {
        return 'Ingresa JSON valido.';
      }
    },
  );
}

DropdownButtonFormField<String> _typeDropdown({
  required String label,
  required String? value,
  required List<ContainerTypeEntry> types,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    key: ValueKey(value),
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: types
        .map(
          (type) => DropdownMenuItem(
            value: type.id,
            child: Text('${type.code} - ${type.name}'),
          ),
        )
        .toList(growable: false),
    onChanged: onChanged,
    validator: (value) =>
        value == null || value.isEmpty ? 'Selecciona un tipo.' : null,
  );
}
