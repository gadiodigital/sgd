import 'dart:convert';
import 'package:flutter/material.dart';
import 'local_scanner_runtime_stub.dart'
    if (dart.library.io) 'local_scanner_runtime_io.dart';
import 'sgd_api_client.dart';
import 'windows_twain_client.dart';

class ScanCenterPage extends StatefulWidget {
  const ScanCenterPage({
    super.key,
    required this.api,
    required this.projectId,
    required this.projectName,
    required this.nodeId,
    required this.nodeName,
    required this.nodeCode,
    required this.nodeTypeName,
    required this.fallbackAttributes,
    required this.documentTypes,
    required this.canReadDocuments,
    required this.canWriteDocuments,
    this.twain,
  });
  final SgdApiClient api;
  final WindowsTwainClient? twain;
  final String projectId;
  final String projectName;
  final String nodeId;
  final String nodeName;
  final String nodeCode;
  final String nodeTypeName;
  final List<ScanAttributeDefinition> fallbackAttributes;
  final List<ScanDocumentTypeDefinition> documentTypes;
  final bool canReadDocuments;
  final bool canWriteDocuments;
  @override
  State<ScanCenterPage> createState() => _ScanCenterPageState();
}

enum _ScanPreviewMode { edit, pdf }
enum _ScanMergeMode { replace, insertAfterCurrent, appendToEnd }

class _ScanCenterPageState extends State<ScanCenterPage> {
  static const _bg = Color(0xFF0B1120), _surface = Color(0xFF172033), _surfaceAlt = Color(0xFF1F2A3F), _border = Color(0xFF334155), _accent = Color(0xFF7DD3FC), _text = Color(0xFFF8FAFC), _muted = Color(0xFFCBD5E1);
  final formKey = GlobalKey<FormState>();
  late final WindowsTwainClient twain;
  late final TextEditingController titleController, descriptionController, timeoutController;
  final attributeTextControllers = <String, TextEditingController>{};
  final attributeSelections = <String, String?>{};
  final dpiOptions = const <int?>[null, 100, 150, 200, 300, 600];
  final pixelTypes = const {'bw': 'Blanco y negro', 'gray': 'Escala de grises', 'color': 'Color'};
  List<TwainScannerDescriptor> scanners = const [];
  List<SavedNodeDocument> documents = const [];
  TwainScanSession? session;
  int? selectedPageNumber, selectedScannerId, dpi = 300;
  String pixelType = 'gray';
  String? selectedDocumentTypeId;
  bool duplex = false, discardBlankPages = false, scannerLoading = true, documentsLoading = false, scanning = false, saving = false, attemptedScannerAutoStart = false, scannerExpanded = true, configExpanded = true, metadataExpanded = true, documentsExpanded = false;
  _ScanPreviewMode previewMode = _ScanPreviewMode.edit;
  String? scannerError, documentsError, actionError, infoText;

  @override
  void initState() {
    super.initState();
    twain = widget.twain ?? WindowsTwainClient();
    titleController = TextEditingController(text: widget.nodeCode.isEmpty ? widget.nodeName : '${widget.nodeCode} - ${widget.nodeName}');
    descriptionController = TextEditingController();
    timeoutController = TextEditingController(text: '90');
    selectedDocumentTypeId = widget.documentTypes.isNotEmpty ? widget.documentTypes.first.id : null;
    for (final a in _allKnownAttributes) { attributeTextControllers[a.id] = TextEditingController(); attributeSelections[a.id] = null; }
    _bootstrap();
  }

  @override
  void dispose() {
    titleController.dispose(); descriptionController.dispose(); timeoutController.dispose();
    for (final c in attributeTextControllers.values) { c.dispose(); }
    super.dispose();
  }

  List<ScanAttributeDefinition> get _allKnownAttributes {
    final byId = <String, ScanAttributeDefinition>{};
    for (final a in widget.fallbackAttributes) { byId[a.id] = a; }
    for (final t in widget.documentTypes) { for (final a in t.attributes) { byId[a.id] = a; } }
    return byId.values.toList();
  }

  ScanDocumentTypeDefinition? get selectedDocumentType {
    for (final t in widget.documentTypes) { if (t.id == selectedDocumentTypeId) return t; }
    return null;
  }

  List<ScanAttributeDefinition> get activeAttributes => selectedDocumentType?.attributes ?? widget.fallbackAttributes;

  TwainScanPage? get selectedPage {
    final current = session; if (current == null || selectedPageNumber == null) return null;
    for (final p in current.pages) { if (p.pageNumber == selectedPageNumber) return p; }
    return current.pages.isEmpty ? null : current.pages.first;
  }

  Future<void> _bootstrap() async => Future.wait([_loadScanners(), if (widget.canReadDocuments) _loadDocuments()]);

  Future<void> _loadScanners() async {
    setState(() { scannerLoading = true; scannerError = null; });
    try {
      final found = await twain.listScanners();
      if (!mounted) return;
      setState(() { scanners = found; selectedScannerId = found.any((i) => i.id == selectedScannerId) ? selectedScannerId : (found.isNotEmpty ? found.first.id : null); });
    } catch (error) {
      if (_shouldAutoStartScanner(error) && !attemptedScannerAutoStart) {
        attemptedScannerAutoStart = true;
        if (await startLocalScannerHost()) { await Future<void>.delayed(const Duration(seconds: 2)); if (mounted) await _loadScanners(); return; }
      }
      if (mounted) setState(() => scannerError = _friendlyScannerError(error));
    } finally {
      if (mounted) setState(() => scannerLoading = false);
    }
  }

  Future<void> _loadDocuments() async {
    setState(() { documentsLoading = true; documentsError = null; });
    try {
      final items = await widget.api.listNodeDocuments(widget.projectId, widget.nodeId);
      if (!mounted) return;
      setState(() => documents = items.map(SavedNodeDocument.fromJson).toList());
    } catch (error) {
      if (mounted) setState(() => documentsError = _errorText(error));
    } finally {
      if (mounted) setState(() => documentsLoading = false);
    }
  }

  bool _shouldAutoStartScanner(Object error) {
    final text = _errorText(error).toLowerCase();
    return text.contains('127.0.0.1:43127') && (text.contains('connection refused') || text.contains('rechazó la conexión') || text.contains('socketexception'));
  }

  String _friendlyScannerError(Object error) {
    if (_shouldAutoStartScanner(error)) {
      final command = localScannerStartCommand();
      return 'No se pudo conectar con windows-twain en http://127.0.0.1:43127.\n\nLa pantalla de escaneo necesita que el host local del escáner esté levantado.${command == null ? '' : '\n\nComando sugerido:\n$command'}';
    }
    return _errorText(error);
  }

  String _errorText(Object error) => error is ApiException ? error.message : error is TwainApiException ? error.message : error.toString();

  Future<void> _scan({required _ScanMergeMode mode}) async {
    if (!widget.canWriteDocuments) return;
    setState(() { scanning = true; actionError = null; infoText = null; });
    try {
      final timeout = int.tryParse(timeoutController.text.trim()) ?? 90;
      if (timeout < 15 || timeout > 300) throw TwainApiException('El timeout debe estar entre 15 y 300 segundos.');
      final newSession = await twain.startScan(duplex: duplex, scannerId: selectedScannerId, dpi: dpi, pixelType: pixelType, discardBlankPages: discardBlankPages, timeoutSeconds: timeout);
      TwainScanSession next = newSession; int? nextSelected = newSession.pageCount > 0 ? 1 : null; final current = session;
      if (mode != _ScanMergeMode.replace && current != null && current.pageCount > 0) {
        if (newSession.pageCount == 0) { next = current; nextSelected = selectedPageNumber; } else {
          final insertAfter = mode == _ScanMergeMode.appendToEnd ? current.pageCount : (selectedPageNumber ?? current.pageCount);
          next = await twain.mergeSession(current.sessionId, newSession.sessionId, insertAfterPageNumber: insertAfter);
          nextSelected = (insertAfter + 1).clamp(1, next.pageCount);
        }
      }
      if (!mounted) return;
      setState(() { session = next; selectedPageNumber = nextSelected; previewMode = _ScanPreviewMode.edit; infoText = next.message; });
    } catch (error) {
      if (mounted) setState(() => actionError = _friendlyScannerError(error));
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> _mutateSession(Future<TwainScanSession> Function() action) async {
    setState(() { actionError = null; infoText = null; });
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() { session = updated; selectedPageNumber = updated.pageCount == 0 ? null : (selectedPageNumber ?? 1).clamp(1, updated.pageCount); if (updated.pageCount == 0) previewMode = _ScanPreviewMode.edit; infoText = updated.message; });
    } catch (error) {
      if (mounted) setState(() => actionError = _errorText(error));
    }
  }

  Future<void> _saveDocument() async {
    if (!widget.canWriteDocuments) return;
    if (session == null || session!.pageCount == 0) { setState(() => actionError = 'Escanea al menos una página antes de guardar el documento.'); return; }
    if (!(formKey.currentState?.validate() ?? false)) { setState(() => metadataExpanded = true); return; }
    setState(() { saving = true; actionError = null; infoText = null; });
    final values = <String, dynamic>{}; for (final a in activeAttributes) { final v = _attributeValue(a); if (v != null && v.trim().isNotEmpty) values[a.id] = v.trim(); }
    try {
      await widget.api.createDocumentFromScan(widget.projectId, widget.nodeId, {'title': titleController.text.trim(), 'description': descriptionController.text.trim(), 'sessionId': session!.sessionId, 'documentTypeId': selectedDocumentTypeId, 'attributeValues': values});
      if (!mounted) return;
      setState(() { session = null; selectedPageNumber = null; previewMode = _ScanPreviewMode.edit; infoText = 'Documento guardado correctamente en la base de datos.'; });
      if (widget.canReadDocuments) await _loadDocuments();
    } catch (error) {
      if (mounted) setState(() => actionError = _errorText(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? _attributeValue(ScanAttributeDefinition a) => switch (a.dataType) { 'list' || 'boolean' => attributeSelections[a.id], _ => attributeTextControllers[a.id]?.text };

  String? _validateAttribute(ScanAttributeDefinition a, String? value) {
    final text = value?.trim() ?? ''; if (text.isEmpty) return null;
    switch (a.dataType) {
      case 'string': final limit = int.tryParse(a.extension); if (limit != null && text.length > limit) return 'Máximo $limit caracteres.'; if (a.regex.isNotEmpty && !RegExp(a.regex).hasMatch(text)) return 'No cumple el formato requerido.';
      case 'integer': if (int.tryParse(text) == null) return 'Ingresa un número entero.';
      case 'decimal': if (num.tryParse(text) == null) return 'Ingresa un número válido.';
      case 'date': try { DateTime.parse(text); } catch (_) { return 'Usa formato AAAA-MM-DD.'; }
      case 'json': try { jsonDecode(text); } catch (_) { return 'JSON inválido.'; }
      case 'list': if (a.options.isNotEmpty && !a.options.any((i) => i.code == text)) return 'Selecciona una opción válida.';
      case 'boolean': if (text != 'true' && text != 'false') return 'Selecciona Sí o No.';
    }
    return null;
  }

  ThemeData _theme(ThemeData base) => base.copyWith(
    scaffoldBackgroundColor: _bg,
    colorScheme: const ColorScheme.dark(primary: _accent, onPrimary: Color(0xFF082F49), secondary: Color(0xFF22D3EE), onSecondary: Color(0xFF083344), surface: _surface, onSurface: _text, surfaceContainerHighest: _surfaceAlt, onSurfaceVariant: _muted, outline: _border, error: Color(0xFFFDA4AF), onError: Color(0xFF4C0519)),
    textTheme: base.textTheme.apply(bodyColor: _text, displayColor: _text),
    disabledColor: const Color(0xFF94A3B8),
    hintColor: _muted,
    cardTheme: const CardThemeData(color: _surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: _border))),
    canvasColor: _surfaceAlt,
    splashColor: _accent.withAlpha(28),
    highlightColor: _accent.withAlpha(18),
    dividerColor: Colors.transparent,
    expansionTileTheme: const ExpansionTileThemeData(iconColor: _text, collapsedIconColor: _text, textColor: _text, collapsedTextColor: _text),
    dropdownMenuTheme: const DropdownMenuThemeData(textStyle: TextStyle(color: _text)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? const Color(0xFF94A3B8) : _text),
        backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _surfaceAlt : _surface),
        side: const WidgetStatePropertyAll(BorderSide(color: _border)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _text : const Color(0xFFE2E8F0)),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0F766E) : const Color(0xFF475569)),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: _muted),
      floatingLabelStyle: const TextStyle(color: _text),
      hintStyle: const TextStyle(color: _muted),
      helperStyle: const TextStyle(color: _muted),
      helperMaxLines: 3,
      errorStyle: const TextStyle(color: Color(0xFFFDA4AF)),
      filled: true,
      fillColor: _surfaceAlt,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.4)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF475569))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFDA4AF))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 1.4)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme(Theme.of(context)),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              if (actionError != null) _banner(actionError!, true),
              if (actionError == null && infoText != null) _banner(infoText!, false),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1180;
                    if (compact) {
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SizedBox(height: 840, child: _rightPane(true)),
                          const SizedBox(height: 16),
                          _leftPane(false),
                        ],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 400, child: _leftPane(true)),
                          const SizedBox(width: 16),
                          Expanded(child: _rightPane(false)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final statusOk = scannerError == null;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _border))),
      child: Row(children: [
        IconButton(tooltip: 'Volver', onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        const Text('SGD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(width: 12),
        Expanded(child: Text('Centro de escaneo · ${widget.projectName} · ${widget.nodeName}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: statusOk ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D), border: Border.all(color: statusOk ? const Color(0xFF34D399) : const Color(0xFFFCA5A5))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(statusOk ? Icons.check_circle_outline : Icons.portable_wifi_off, size: 16, color: statusOk ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
            const SizedBox(width: 8),
            Text(statusOk ? 'Escáner listo' : 'Escáner no disponible'),
          ]),
        ),
      ]),
    );
  }

  Widget _banner(String text, bool isError) {
    final color = isError ? const Color(0xFFFDA4AF) : const Color(0xFF86EFAC);
    final bg = isError ? const Color(0xFF4C0519) : const Color(0xFF052E16);
    return Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.55)), color: bg), child: Text(text, style: TextStyle(color: color, height: 1.4)));
  }

  Widget _leftPane(bool scrollable) {
    final child = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionCard('Escáner', 'Origen TWAIN y disponibilidad.', scannerExpanded, (v) => setState(() => scannerExpanded = v), _scannerBody()),
      const SizedBox(height: 16),
      _sectionCard('Configuración', 'Modo, color, resolución y timeout.', configExpanded, (v) => setState(() => configExpanded = v), _configBody()),
      const SizedBox(height: 16),
      _sectionCard('Documento', widget.documentTypes.isEmpty ? 'No hay tipos documentales; se usa el esquema heredado del contenedor.' : 'Selecciona el tipo documental y completa sus atributos.', metadataExpanded, (v) => setState(() => metadataExpanded = v), _documentBody()),
      if (widget.canReadDocuments) ...[
        const SizedBox(height: 16),
        _sectionCard('Documentos guardados', 'Historial del nodo actual.', documentsExpanded, (v) => setState(() => documentsExpanded = v), _documentsBody()),
      ],
    ]);
    return scrollable ? Scrollbar(thumbVisibility: true, child: SingleChildScrollView(child: child)) : child;
  }

  Widget _sectionCard(String title, String subtitle, bool expanded, ValueChanged<bool> onExpansionChanged, Widget child) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('section-$title'),
          initiallyExpanded: expanded,
          maintainState: true,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(color: _muted, height: 1.35))),
          children: [child],
        ),
      ),
    );
  }

  Widget _scannerBody() {
    if (scannerLoading) return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: _loadScanners, icon: const Icon(Icons.refresh), label: const Text('Actualizar'))),
      const SizedBox(height: 12),
      if (scannerError != null) Text(scannerError!, style: const TextStyle(color: Color(0xFFFDA4AF), height: 1.4)),
      if (scannerError == null && scanners.isEmpty) const Text('No se detectaron escáneres TWAIN en este equipo.', style: TextStyle(color: _muted)),
      if (scannerError == null && scanners.isNotEmpty)
        DropdownButtonFormField<int>(
          initialValue: selectedScannerId,
          decoration: const InputDecoration(labelText: 'Escáner disponible'),
          dropdownColor: _surfaceAlt,
          style: const TextStyle(color: _text),
          items: scanners.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} · ${s.manufacturer}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: widget.canWriteDocuments ? (value) => setState(() => selectedScannerId = value) : null,
        ),
    ]);
  }

  Widget _configBody() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<bool>(showSelectedIcon: false, segments: const [ButtonSegment(value: false, icon: Icon(Icons.filter_1), label: Text('Simple')), ButtonSegment(value: true, icon: Icon(Icons.copy_all_outlined), label: Text('Doble faz'))], selected: {duplex}, onSelectionChanged: widget.canWriteDocuments ? (value) => setState(() => duplex = value.first) : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: pixelType, decoration: const InputDecoration(labelText: 'Color'), dropdownColor: _surfaceAlt, style: const TextStyle(color: _text), items: pixelTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: _text)))).toList(), onChanged: widget.canWriteDocuments ? (value) => setState(() => pixelType = value ?? 'gray') : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(initialValue: dpi, decoration: const InputDecoration(labelText: 'Resolución'), dropdownColor: _surfaceAlt, style: const TextStyle(color: _text), items: dpiOptions.map((v) => DropdownMenuItem<int?>(value: v, child: Text(v == null ? 'Auto' : '$v DPI', style: const TextStyle(color: _text)))).toList(), onChanged: widget.canWriteDocuments ? (value) => setState(() => dpi = value) : null),
      const SizedBox(height: 12),
      TextFormField(controller: timeoutController, decoration: const InputDecoration(labelText: 'Timeout (segundos)'), keyboardType: TextInputType.number, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _scan(mode: _ScanMergeMode.replace)),
      const SizedBox(height: 6),
      SwitchListTile(value: discardBlankPages, onChanged: widget.canWriteDocuments ? (value) => setState(() => discardBlankPages = value) : null, contentPadding: EdgeInsets.zero, title: const Text('Descartar hojas en blanco', style: TextStyle(color: _text)), subtitle: const Text('Evita sumar páginas vacías cuando el driver lo soporta.', style: TextStyle(color: _muted))),
    ]);
  }

  Widget _documentBody() {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Proyecto: ${widget.projectName}\nNodo: ${widget.nodeName}\nTipo de contenedor: ${widget.nodeTypeName}', style: const TextStyle(color: _muted, height: 1.45)),
        const SizedBox(height: 14),
        TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Título del documento'), textInputAction: TextInputAction.next, validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el título.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción'), minLines: 2, maxLines: 3),
        const SizedBox(height: 12),
        if (widget.documentTypes.isNotEmpty)
          DropdownButtonFormField<String>(initialValue: selectedDocumentTypeId, decoration: const InputDecoration(labelText: 'Tipo documental'), dropdownColor: _surfaceAlt, style: const TextStyle(color: _text), items: widget.documentTypes.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.code})', overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text)))).toList(), onChanged: widget.canWriteDocuments ? (value) => setState(() => selectedDocumentTypeId = value) : null)
        else
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _border), color: _surfaceAlt), child: const Text('No hay tipos documentales definidos. La carga usa atributos heredados del contenedor.', style: TextStyle(color: _muted, height: 1.35))),
        const SizedBox(height: 16),
        Text(selectedDocumentType != null ? 'Atributos del tipo documental' : 'Atributos heredados del contenedor', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (activeAttributes.isEmpty) Text(selectedDocumentType != null ? 'Este tipo documental no define atributos adicionales.' : 'El contenedor actual no aporta atributos heredados.', style: const TextStyle(color: _muted)),
        ...activeAttributes.map(_attributeField),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: saving || !widget.canWriteDocuments ? null : _saveDocument, icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Guardar documento')),
        if (!widget.canWriteDocuments) ...[const SizedBox(height: 10), const Text('Tu perfil solo puede consultar documentos; no puede escanear ni guardar.', style: TextStyle(color: Color(0xFFFCD34D), height: 1.35))],
      ]),
    );
  }

  Widget _documentsBody() {
    if (documentsLoading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: _loadDocuments, icon: const Icon(Icons.refresh), label: const Text('Recargar'))),
      const SizedBox(height: 12),
      if (documentsError != null) Text(documentsError!, style: const TextStyle(color: Color(0xFFFDA4AF), height: 1.4)),
      if (documentsError == null && documents.isEmpty) const Text('Todavía no hay documentos guardados en este nodo.', style: TextStyle(color: _muted)),
      ...documents.map((d) => ListTile(contentPadding: EdgeInsets.zero, title: Text(d.title), subtitle: Text([if (d.documentTypeName.isNotEmpty) d.documentTypeName, '${d.pageCount} pág(s)', 'versión ${d.currentVersionNumber}', d.updatedAtLabel].join(' · ')))),
    ]);
  }

  Widget _attributeField(ScanAttributeDefinition a) {
    final helper = [a.code, a.dataType, if (a.extension.isNotEmpty) 'ext ${a.extension}', if (a.regex.isNotEmpty) 'regex'].join(' · ');
    if (a.dataType == 'list' || a.dataType == 'boolean') {
      final items = a.dataType == 'boolean'
          ? const [DropdownMenuItem<String>(value: '', child: Text('(sin valor)')), DropdownMenuItem<String>(value: 'true', child: Text('Sí')), DropdownMenuItem<String>(value: 'false', child: Text('No'))]
          : [const DropdownMenuItem<String>(value: '', child: Text('(sin valor)')), ...a.options.map((o) => DropdownMenuItem<String>(value: o.code, child: Text(o.label)))];
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(initialValue: attributeSelections[a.id], decoration: InputDecoration(labelText: a.name, helperText: helper), dropdownColor: _surfaceAlt, style: const TextStyle(color: _text), items: items.map((item) => DropdownMenuItem<String>(value: item.value, child: DefaultTextStyle.merge(style: const TextStyle(color: _text), child: item.child))).toList(), onChanged: (value) => setState(() => attributeSelections[a.id] = value == null || value.isEmpty ? null : value), validator: (value) => _validateAttribute(a, value)));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: attributeTextControllers[a.id],
        decoration: InputDecoration(labelText: a.name, helperText: helper, hintText: a.dataType == 'date' ? 'AAAA-MM-DD' : a.dataType == 'json' ? '{"clave":"valor"}' : null),
        minLines: a.dataType == 'json' ? 3 : 1,
        maxLines: a.dataType == 'json' ? 4 : 1,
        keyboardType: a.dataType == 'integer' ? TextInputType.number : a.dataType == 'decimal' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        textInputAction: a.dataType == 'json' ? TextInputAction.newline : TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        validator: (value) => _validateAttribute(a, value),
      ),
    );
  }

  Widget _rightPane(bool compact) {
    final title = previewMode == _ScanPreviewMode.pdf ? 'PDF temporal' : 'Vista previa y edición';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text(previewMode == _ScanPreviewMode.pdf ? 'Vista integrada del PDF temporal. No se expone descarga directa desde la UI.' : 'Edición de páginas, reordenamiento y ajustes sobre la sesión actual.', style: const TextStyle(color: _muted, height: 1.35)),
            ])),
            if (!compact) SizedBox(width: 340, child: _sessionSummary()),
          ]),
          if (compact) ...[const SizedBox(height: 12), _sessionSummary()],
          const SizedBox(height: 14),
          _toolbar(),
          const SizedBox(height: 18),
          Expanded(child: session == null || session!.pageCount == 0 ? _emptyPreview() : previewMode == _ScanPreviewMode.pdf ? _pdfPreview() : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _selectedPreview()),
            const SizedBox(height: 16),
            SizedBox(height: 210, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: session!.pages.length, separatorBuilder: (_, _) => const SizedBox(width: 12), itemBuilder: (_, index) => _thumbnail(session!.pages[index], session!.pages[index].pageNumber == selectedPageNumber))),
          ])),
        ]),
      ),
    );
  }

  Widget _sessionSummary() {
    final current = session;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: current == null ? const Text('Sin sesión de escaneo activa.', style: TextStyle(color: _muted)) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sesión actual', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(current.scannerName.isEmpty ? 'Escáner sin nombre' : current.scannerName),
          const SizedBox(height: 4),
          Text('${current.mode} · ${current.pageCount} pág(s)'),
          if (current.settings.dpi != null) Text('${current.settings.dpi!.toStringAsFixed(0)} DPI'),
          Text('${current.settings.pixelType} · blancas ${current.settings.discardBlankPages}', style: const TextStyle(color: _muted)),
          if (selectedDocumentType != null) ...[const SizedBox(height: 8), Text('Tipo documental: ${selectedDocumentType!.name}', style: const TextStyle(color: _muted))],
        ]),
      ),
    );
  }

  Widget _toolbar() {
    final current = session; final page = selectedPageNumber;
    final pageCount = current?.pageCount ?? 0;
    final canMutate = current != null && page != null;
    final canBack = canMutate && page > 1 && pageCount > 1;
    final canForward = canMutate && page < pageCount;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      _toolIcon(Icons.document_scanner_outlined, current == null ? 'Escanear' : 'Reemplazar sesión', scannerLoading || scanning || !widget.canWriteDocuments ? null : () => _scan(mode: _ScanMergeMode.replace), busy: scanning),
      _toolIcon(Icons.input_outlined, 'Insertar páginas después de la hoja seleccionada', scannerLoading || scanning || current == null || !widget.canWriteDocuments ? null : () => _scan(mode: _ScanMergeMode.insertAfterCurrent)),
      _toolIcon(Icons.playlist_add_outlined, 'Insertar páginas al final de la sesión', scannerLoading || scanning || current == null || !widget.canWriteDocuments ? null : () => _scan(mode: _ScanMergeMode.appendToEnd)),
      _toolIcon(Icons.preview_outlined, 'Ver edición de páginas', current == null ? null : () => setState(() => previewMode = _ScanPreviewMode.edit), selected: previewMode == _ScanPreviewMode.edit),
      _toolIcon(Icons.picture_as_pdf_outlined, 'Ver PDF temporal dentro de la aplicación', current == null ? null : () => setState(() => previewMode = _ScanPreviewMode.pdf), selected: previewMode == _ScanPreviewMode.pdf),
      _toolIcon(Icons.rotate_90_degrees_ccw_outlined, 'Rotar página 90 grados', !canMutate ? null : () => _mutateSession(() => twain.rotatePage(current.sessionId, page, 90))),
      _toolIcon(Icons.first_page, 'Mover página al inicio', !canBack ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page, 1))),
      _toolIcon(Icons.chevron_left, 'Mover página una posición hacia atrás', !canBack ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page, page - 1))),
      _toolIcon(Icons.chevron_right, 'Mover página una posición hacia adelante', !canForward ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page, page + 1))),
      _toolIcon(Icons.last_page, 'Mover página al final', !canForward ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page, current.pageCount))),
      _toolIcon(Icons.brightness_high_outlined, 'Subir brillo', !canMutate ? null : () => _mutateSession(() => twain.adjustPage(current.sessionId, page, brightness: 10, contrast: 0))),
      _toolIcon(Icons.brightness_low_outlined, 'Bajar brillo', !canMutate ? null : () => _mutateSession(() => twain.adjustPage(current.sessionId, page, brightness: -10, contrast: 0))),
      _toolIcon(Icons.contrast_outlined, 'Subir contraste', !canMutate ? null : () => _mutateSession(() => twain.adjustPage(current.sessionId, page, brightness: 0, contrast: 10))),
      _toolIcon(Icons.tonality_outlined, 'Bajar contraste', !canMutate ? null : () => _mutateSession(() => twain.adjustPage(current.sessionId, page, brightness: 0, contrast: -10))),
      _toolIcon(Icons.delete_outline, 'Eliminar página', !canMutate ? null : () => _mutateSession(() => twain.deletePage(current.sessionId, page)), isDanger: true),
    ]);
  }

  Widget _toolIcon(IconData icon, String tooltip, VoidCallback? onPressed, {bool selected = false, bool busy = false, bool isDanger = false}) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer : isDanger ? const Color(0xFF3F0D18) : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimaryContainer : isDanger ? const Color(0xFFFDA4AF) : scheme.onSurface;
    return Tooltip(message: tooltip, child: IconButton.filledTonal(onPressed: onPressed, style: IconButton.styleFrom(backgroundColor: bg, foregroundColor: fg), icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon)));
  }

  Widget _emptyPreview() => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: _border), color: const Color(0xFF040B19)), child: const Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.document_scanner_outlined, size: 56, color: _muted), SizedBox(height: 12), Text('Sin páginas escaneadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), SizedBox(height: 6), Text('Usa los botones superiores para escanear, insertar hojas o construir el PDF temporal.', textAlign: TextAlign.center, style: TextStyle(color: _muted, height: 1.4))]))));

  Widget _selectedPreview() {
    final page = selectedPage;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF040B19), borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: page == null ? const Center(child: Text('Selecciona una página.', style: TextStyle(color: _muted))) : InteractiveViewer(minScale: 0.6, maxScale: 4, child: Center(child: Image.network(twain.previewUrl(session!.sessionId, page.pageNumber, width: 1500, quality: 88), fit: BoxFit.contain, errorBuilder: (_, _, _) => const Center(child: Text('No se pudo renderizar la vista previa.', style: TextStyle(color: _muted)))))),
      ),
    );
  }

  Widget _pdfPreview() {
    final current = session!;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF040B19), borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: current.pages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 20),
        itemBuilder: (_, index) {
          final page = current.pages[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Página ${page.pageNumber}', textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => setState(() { selectedPageNumber = page.pageNumber; previewMode = _ScanPreviewMode.edit; }),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
                    child: AspectRatio(aspectRatio: 1 / 1.414, child: Image.network(twain.previewUrl(current.sessionId, page.pageNumber, width: 1200, quality: 88), fit: BoxFit.contain, errorBuilder: (_, _, _) => const Center(child: Text('No se pudo renderizar esta página.', style: TextStyle(color: Colors.black87))))),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _thumbnail(TwainScanPage page, bool selected) {
    final current = session!; final canBack = page.pageNumber > 1; final canForward = page.pageNumber < current.pageCount;
    return SizedBox(
      width: 164,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selectedPageNumber = page.pageNumber),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? _accent : _border, width: selected ? 2 : 1), color: const Color(0xFF040B19)),
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Página ${page.pageNumber}', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(twain.previewUrl(current.sessionId, page.pageNumber, width: 320, quality: 76), fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: _surfaceAlt, child: Center(child: Icon(Icons.broken_image_outlined)))))),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 2, runSpacing: 2, children: [
              Tooltip(message: 'Mover al inicio', child: IconButton(visualDensity: VisualDensity.compact, onPressed: !canBack ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page.pageNumber, 1)), icon: const Icon(Icons.first_page, size: 18))),
              Tooltip(message: 'Mover hacia atrás', child: IconButton(visualDensity: VisualDensity.compact, onPressed: !canBack ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page.pageNumber, page.pageNumber - 1)), icon: const Icon(Icons.chevron_left, size: 18))),
              Tooltip(message: 'Rotar', child: IconButton(visualDensity: VisualDensity.compact, onPressed: () => _mutateSession(() => twain.rotatePage(current.sessionId, page.pageNumber, 90)), icon: const Icon(Icons.rotate_90_degrees_ccw_outlined, size: 18))),
              Tooltip(message: 'Mover hacia adelante', child: IconButton(visualDensity: VisualDensity.compact, onPressed: !canForward ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page.pageNumber, page.pageNumber + 1)), icon: const Icon(Icons.chevron_right, size: 18))),
              Tooltip(message: 'Mover al final', child: IconButton(visualDensity: VisualDensity.compact, onPressed: !canForward ? null : () => _mutateSession(() => twain.movePage(current.sessionId, page.pageNumber, current.pageCount)), icon: const Icon(Icons.last_page, size: 18))),
              Tooltip(message: 'Eliminar', child: IconButton(visualDensity: VisualDensity.compact, onPressed: () { setState(() => selectedPageNumber = page.pageNumber); _mutateSession(() => twain.deletePage(current.sessionId, page.pageNumber)); }, icon: const Icon(Icons.delete_outline, size: 18))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class ScanDocumentTypeDefinition {
  const ScanDocumentTypeDefinition({required this.id, required this.name, required this.code, required this.description, required this.attributes});
  final String id, name, code, description;
  final List<ScanAttributeDefinition> attributes;
}

class ScanAttributeDefinition {
  const ScanAttributeDefinition({required this.id, required this.name, required this.code, required this.dataType, required this.extension, required this.regex, required this.options});
  final String id, name, code, dataType, extension, regex;
  final List<ScanAttributeOption> options;
}

class ScanAttributeOption {
  const ScanAttributeOption({required this.code, required this.label});
  final String code, label;
}

class SavedNodeDocument {
  const SavedNodeDocument({required this.id, required this.title, required this.documentTypeName, required this.currentVersionNumber, required this.pageCount, required this.updatedAtLabel});
  factory SavedNodeDocument.fromJson(Map<String, dynamic> json) => SavedNodeDocument(id: json['id'].toString(), title: (json['title'] ?? '').toString(), documentTypeName: (json['documentTypeName'] ?? '').toString(), currentVersionNumber: (json['currentVersionNumber'] as num?)?.toInt() ?? 1, pageCount: (json['pageCount'] as num?)?.toInt() ?? 0, updatedAtLabel: _formatUpdatedAt((json['updatedAt'] ?? '').toString()));
  final String id, title, documentTypeName, updatedAtLabel;
  final int currentVersionNumber, pageCount;
}

String _formatUpdatedAt(String value) {
  if (value.trim().isEmpty) return 'sin fecha';
  final parsed = DateTime.tryParse(value); if (parsed == null) return value;
  final local = parsed.toLocal(); String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}
