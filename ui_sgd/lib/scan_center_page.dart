import 'dart:convert';

import 'package:flutter/material.dart';

import 'external_launcher_stub.dart'
    if (dart.library.html) 'external_launcher_web.dart'
    if (dart.library.io) 'external_launcher_io.dart';
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
    required this.attributes,
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
  final List<ScanAttributeDefinition> attributes;
  final bool canReadDocuments;
  final bool canWriteDocuments;

  @override
  State<ScanCenterPage> createState() => _ScanCenterPageState();
}

class _ScanCenterPageState extends State<ScanCenterPage> {
  final formKey = GlobalKey<FormState>();
  late final WindowsTwainClient twain;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController timeoutController;
  final attributeTextControllers = <String, TextEditingController>{};
  final attributeSelections = <String, String?>{};

  final dpiOptions = const <int?>[null, 100, 150, 200, 300, 600];
  final pixelTypes = const <String, String>{
    'bw': 'B/N',
    'gray': 'Grises',
    'color': 'Color',
  };

  List<TwainScannerDescriptor> scanners = const [];
  List<SavedNodeDocument> documents = const [];
  TwainScanSession? session;
  int? selectedPageNumber;

  int? selectedScannerId;
  int? dpi = 300;
  String pixelType = 'gray';
  bool duplex = false;
  bool discardBlankPages = false;

  bool scannerLoading = true;
  bool documentsLoading = false;
  bool scanning = false;
  bool saving = false;
  bool attemptedScannerAutoStart = false;

  String? scannerError;
  String? documentsError;
  String? actionError;
  String? infoText;

  @override
  void initState() {
    super.initState();
    twain = widget.twain ?? WindowsTwainClient();
    final initialTitle = widget.nodeCode.isEmpty ? widget.nodeName : '${widget.nodeCode} - ${widget.nodeName}';
    titleController = TextEditingController(text: initialTitle);
    descriptionController = TextEditingController();
    timeoutController = TextEditingController(text: '90');

    for (final attribute in widget.attributes) {
      attributeTextControllers[attribute.id] = TextEditingController();
      attributeSelections[attribute.id] = null;
    }

    _bootstrap();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    timeoutController.dispose();
    for (final controller in attributeTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadScanners(),
      if (widget.canReadDocuments) _loadDocuments(),
    ]);
  }

  TwainScanPage? get selectedPage {
    final currentSession = session;
    if (currentSession == null || selectedPageNumber == null) {
      return null;
    }
    for (final page in currentSession.pages) {
      if (page.pageNumber == selectedPageNumber) {
        return page;
      }
    }
    return currentSession.pages.isEmpty ? null : currentSession.pages.first;
  }

  Future<void> _loadScanners() async {
    setState(() {
      scannerLoading = true;
      scannerError = null;
    });
    try {
      final found = await twain.listScanners();
      if (!mounted) {
        return;
      }
      setState(() {
        scanners = found;
        selectedScannerId = found.any((item) => item.id == selectedScannerId)
            ? selectedScannerId
            : (found.isNotEmpty ? found.first.id : null);
      });
    } catch (error) {
      if (_shouldAutoStartScanner(error) && !attemptedScannerAutoStart) {
        attemptedScannerAutoStart = true;
        final started = await startLocalScannerHost();
        if (started) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) {
            await _loadScanners();
          }
          return;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() => scannerError = _friendlyScannerError(error));
    } finally {
      if (mounted) {
        setState(() => scannerLoading = false);
      }
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      documentsLoading = true;
      documentsError = null;
    });
    try {
      final items = await widget.api.listNodeDocuments(widget.projectId, widget.nodeId);
      if (!mounted) {
        return;
      }
      setState(() {
        documents = items.map(SavedNodeDocument.fromJson).toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => documentsError = _errorText(error));
    } finally {
      if (mounted) {
        setState(() => documentsLoading = false);
      }
    }
  }

  bool _shouldAutoStartScanner(Object error) {
    final text = _errorText(error).toLowerCase();
    return text.contains('127.0.0.1:43127') &&
        (text.contains('connection refused') || text.contains('rechazó la conexión') || text.contains('socketexception'));
  }

  String _friendlyScannerError(Object error) {
    if (_shouldAutoStartScanner(error)) {
      final command = localScannerStartCommand();
      final commandText = command == null ? '' : '\n\nComando sugerido:\n$command';
      return 'No se pudo conectar con windows-twain en http://127.0.0.1:43127.'
          '\n\nLa pantalla de escaneo necesita que el host local del escáner esté levantado.'
          '$commandText';
    }
    return _errorText(error);
  }

  String _errorText(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is TwainApiException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _scan({required bool mergeIntoCurrent}) async {
    if (!widget.canWriteDocuments) {
      return;
    }
    setState(() {
      scanning = true;
      actionError = null;
      infoText = null;
    });
    try {
      final timeout = int.tryParse(timeoutController.text.trim()) ?? 90;
      if (timeout < 15 || timeout > 300) {
        throw TwainApiException('El timeout debe estar entre 15 y 300 segundos.');
      }

      final newSession = await twain.startScan(
        duplex: duplex,
        scannerId: selectedScannerId,
        dpi: dpi,
        pixelType: pixelType,
        discardBlankPages: discardBlankPages,
        timeoutSeconds: timeout,
      );

      TwainScanSession nextSession = newSession;
      if (mergeIntoCurrent && session != null && session!.pageCount > 0 && newSession.pageCount == 0) {
        nextSession = session!;
      } else if (mergeIntoCurrent && session != null && session!.pageCount > 0 && newSession.pageCount > 0) {
        final insertAfter = selectedPageNumber ?? session!.pageCount;
        nextSession = await twain.mergeSession(
          session!.sessionId,
          newSession.sessionId,
          insertAfterPageNumber: insertAfter,
        );
        selectedPageNumber = (insertAfter + 1).clamp(1, nextSession.pageCount);
      } else {
        selectedPageNumber = newSession.pageCount > 0 ? 1 : null;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        session = nextSession;
        infoText = nextSession.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => actionError = _friendlyScannerError(error));
    } finally {
      if (mounted) {
        setState(() => scanning = false);
      }
    }
  }

  Future<void> _mutateSession(Future<TwainScanSession> Function() action) async {
    setState(() {
      actionError = null;
      infoText = null;
    });
    try {
      final updated = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        session = updated;
        if (updated.pageCount == 0) {
          selectedPageNumber = null;
        } else {
          final candidate = selectedPageNumber ?? 1;
          selectedPageNumber = candidate.clamp(1, updated.pageCount);
        }
        infoText = updated.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => actionError = _errorText(error));
    }
  }

  Future<void> _saveDocument() async {
    if (!widget.canWriteDocuments) {
      return;
    }
    if (session == null || session!.pageCount == 0) {
      setState(() => actionError = 'Escanea al menos una página antes de guardar.');
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      saving = true;
      actionError = null;
      infoText = null;
    });

    final attributeValues = <String, dynamic>{};
    for (final attribute in widget.attributes) {
      final value = _attributeValue(attribute);
      if (value != null && value.trim().isNotEmpty) {
        attributeValues[attribute.id] = value.trim();
      }
    }

    try {
      await widget.api.createDocumentFromScan(
        widget.projectId,
        widget.nodeId,
        {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'sessionId': session!.sessionId,
          'attributeValues': attributeValues,
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        session = null;
        selectedPageNumber = null;
        infoText = 'Documento guardado correctamente en la base de datos.';
      });
      if (widget.canReadDocuments) {
        await _loadDocuments();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => actionError = _errorText(error));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  String? _attributeValue(ScanAttributeDefinition attribute) {
    switch (attribute.dataType) {
      case 'list':
      case 'boolean':
        return attributeSelections[attribute.id];
      default:
        return attributeTextControllers[attribute.id]?.text;
    }
  }

  String? _validateAttribute(ScanAttributeDefinition attribute, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    switch (attribute.dataType) {
      case 'string':
        if (attribute.extension.isNotEmpty) {
          final limit = int.tryParse(attribute.extension);
          if (limit != null && text.length > limit) {
            return 'Máximo $limit caracteres.';
          }
        }
        if (attribute.regex.isNotEmpty && !RegExp(attribute.regex).hasMatch(text)) {
          return 'No cumple el formato requerido.';
        }
      case 'integer':
        if (int.tryParse(text) == null) {
          return 'Ingresa un número entero.';
        }
      case 'decimal':
        if (num.tryParse(text) == null) {
          return 'Ingresa un número válido.';
        }
      case 'date':
        try {
          DateTime.parse(text);
        } catch (_) {
          return 'Usa formato AAAA-MM-DD.';
        }
      case 'json':
        try {
          jsonDecode(text);
        } catch (_) {
          return 'JSON inválido.';
        }
      case 'list':
        if (attribute.options.isNotEmpty && !attribute.options.any((item) => item.code == text)) {
          return 'Selecciona una opción válida.';
        }
      case 'boolean':
        if (text != 'true' && text != 'false') {
          return 'Selecciona Sí o No.';
        }
    }
    return null;
  }

  Future<void> _openSessionPdf() async {
    final current = session;
    if (current == null) {
      return;
    }
    final opened = await openExternalUrl(twain.pdfUrl(current.sessionId));
    if (!mounted) {
      return;
    }
    if (!opened) {
      setState(() => actionError = 'No se pudo abrir el PDF temporal de la sesión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const bg = Color(0xFF0F172A);
    const surface = Color(0xFF1E293B);
    const border = Color(0xFF334155);
    const accent = Color(0xFF3B82F6);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: bg,
        cardTheme: const CardThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: border,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent),
          ),
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              if (actionError != null)
                _banner(actionError!, isError: true)
              else if (infoText != null)
                _banner(infoText!, isError: false),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1180;
                    if (compact) {
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _leftColumn(),
                          const SizedBox(height: 16),
                          SizedBox(height: 860, child: _rightColumn(compact: true)),
                        ],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 380, child: _leftColumn()),
                          const SizedBox(width: 16),
                          Expanded(child: _rightColumn(compact: false)),
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
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          const Text(
            'SGD',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '/ Centro de escaneo • ${widget.projectName} • ${widget.nodeName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: scannerError == null
                  ? Colors.green.withValues(alpha: 0.14)
                  : Colors.red.withValues(alpha: 0.14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  scannerError == null ? Icons.check_circle_outline : Icons.portable_wifi_off,
                  size: 16,
                  color: scannerError == null ? Colors.green.shade300 : Colors.red.shade300,
                ),
                const SizedBox(width: 8),
                Text(scannerError == null ? 'Escáner listo' : 'Escáner no disponible'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(String text, {required bool isError}) {
    final color = isError ? Colors.red.shade300 : Colors.green.shade300;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        color: color.withValues(alpha: 0.10),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }

  Widget _leftColumn() {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _scannerCard(),
          const SizedBox(height: 16),
          _configCard(),
          const SizedBox(height: 16),
          _documentCard(),
          if (widget.canReadDocuments) ...[
            const SizedBox(height: 16),
            _documentsCard(),
          ],
        ],
      ),
    );
  }

  Widget _rightColumn({required bool compact}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vista previa y edición',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (!compact) SizedBox(width: 340, child: _sessionSummaryCard()),
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 12),
              _sessionSummaryCard(),
            ],
            const SizedBox(height: 14),
            _toolbar(),
            const SizedBox(height: 18),
            Expanded(
              child: session == null || session!.pageCount == 0
                  ? _emptyPreview()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _selectedPreview()),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 196,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: session!.pages.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final page = session!.pages[index];
                              final selected = page.pageNumber == selectedPageNumber;
                              return _thumbnail(page, selected);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: scannerLoading || scanning || !widget.canWriteDocuments ? null : () => _scan(mergeIntoCurrent: false),
          icon: scanning
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.document_scanner_outlined),
          label: Text(session == null ? 'Escanear' : 'Reescanear'),
        ),
        FilledButton.tonalIcon(
          onPressed: scannerLoading || scanning || session == null || !widget.canWriteDocuments ? null : () => _scan(mergeIntoCurrent: true),
          icon: const Icon(Icons.playlist_add_outlined),
          label: const Text('Insertar hojas'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null ? null : _openSessionPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PDF temporal'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null ? null : () => _mutateSession(() => twain.rotatePage(session!.sessionId, selectedPageNumber!, 90)),
          icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
          label: const Text('Rotar'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null || selectedPageNumber == 1
              ? null
              : () => _mutateSession(() => twain.movePage(session!.sessionId, selectedPageNumber!, selectedPageNumber! - 1)),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Mover antes'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null || selectedPageNumber == session!.pageCount
              ? null
              : () => _mutateSession(() => twain.movePage(session!.sessionId, selectedPageNumber!, selectedPageNumber! + 1)),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Mover después'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null
              ? null
              : () => _mutateSession(() => twain.adjustPage(session!.sessionId, selectedPageNumber!, brightness: 10, contrast: 0)),
          icon: const Icon(Icons.brightness_5_outlined),
          label: const Text('+ brillo'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null
              ? null
              : () => _mutateSession(() => twain.adjustPage(session!.sessionId, selectedPageNumber!, brightness: -10, contrast: 0)),
          icon: const Icon(Icons.brightness_2_outlined),
          label: const Text('- brillo'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null
              ? null
              : () => _mutateSession(() => twain.adjustPage(session!.sessionId, selectedPageNumber!, brightness: 0, contrast: 10)),
          icon: const Icon(Icons.contrast_outlined),
          label: const Text('+ contraste'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null
              ? null
              : () => _mutateSession(() => twain.adjustPage(session!.sessionId, selectedPageNumber!, brightness: 0, contrast: -10)),
          icon: const Icon(Icons.tonality_outlined),
          label: const Text('- contraste'),
        ),
        FilledButton.tonalIcon(
          onPressed: session == null || selectedPageNumber == null
              ? null
              : () => _mutateSession(() => twain.deletePage(session!.sessionId, selectedPageNumber!)),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar'),
        ),
      ],
    );
  }

  Widget _selectedPreview() {
    final page = selectedPage;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: page == null
            ? const Center(child: Text('Selecciona una página.'))
            : InteractiveViewer(
                minScale: 0.6,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    twain.previewUrl(session!.sessionId, page.pageNumber, width: 1500, quality: 88),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _scannerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Escáner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                FilledButton.tonalIcon(
                  onPressed: scannerLoading ? null : _loadScanners,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (scannerLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (scannerError != null)
              Text(scannerError!, style: TextStyle(color: Colors.red.shade300))
            else if (scanners.isEmpty)
              const Text('No se detectaron escáneres TWAIN en este equipo.')
            else
              DropdownButtonFormField<int>(
                initialValue: selectedScannerId,
                decoration: const InputDecoration(labelText: 'Escáner disponible'),
                items: scanners
                    .map(
                      (scanner) => DropdownMenuItem(
                        value: scanner.id,
                        child: Text('${scanner.name} • ${scanner.manufacturer}'),
                      ),
                    )
                    .toList(),
                onChanged: widget.canWriteDocuments ? (value) => setState(() => selectedScannerId = value) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _configCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Configuración', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.filter_1), label: Text('Simple')),
                ButtonSegment(value: true, icon: Icon(Icons.copy_all_outlined), label: Text('Doble faz')),
              ],
              selected: {duplex},
              onSelectionChanged: widget.canWriteDocuments ? (value) => setState(() => duplex = value.first) : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: pixelType,
              decoration: const InputDecoration(labelText: 'Color'),
              items: pixelTypes.entries
                  .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                  .toList(),
              onChanged: widget.canWriteDocuments ? (value) => setState(() => pixelType = value ?? 'gray') : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: dpi,
              decoration: const InputDecoration(labelText: 'Resolución'),
              items: dpiOptions
                  .map(
                    (value) => DropdownMenuItem<int?>(
                      value: value,
                      child: Text(value == null ? 'Auto' : '$value DPI'),
                    ),
                  )
                  .toList(),
              onChanged: widget.canWriteDocuments ? (value) => setState(() => dpi = value) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: timeoutController,
              decoration: const InputDecoration(labelText: 'Timeout (segundos)'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _scan(mergeIntoCurrent: false),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: discardBlankPages,
              onChanged: widget.canWriteDocuments ? (value) => setState(() => discardBlankPages = value) : null,
              contentPadding: EdgeInsets.zero,
              title: const Text('Descartar hojas en blanco'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Metadatos del documento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Proyecto: ${widget.projectName}\nNodo: ${widget.nodeName}\nTipo de nodo: ${widget.nodeTypeName}',
                style: TextStyle(color: Colors.blueGrey.shade100),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título del documento'),
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el título.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                minLines: 2,
              ),
              if (widget.attributes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Atributos heredados del tipo', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...widget.attributes.map(_attributeField),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saving || !widget.canWriteDocuments ? null : _saveDocument,
                icon: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar documento'),
              ),
              if (!widget.canWriteDocuments) ...[
                const SizedBox(height: 10),
                Text(
                  'Tu perfil solo puede consultar documentos; no puede escanear ni guardar.',
                  style: TextStyle(color: Colors.orange.shade200),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _attributeField(ScanAttributeDefinition attribute) {
    final helperPieces = <String>[
      attribute.dataType,
      if (attribute.extension.isNotEmpty) 'ext ${attribute.extension}',
      if (attribute.regex.isNotEmpty) 'regex',
    ];
    final helperText = helperPieces.join(' • ');

    switch (attribute.dataType) {
      case 'list':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: attributeSelections[attribute.id],
            decoration: InputDecoration(labelText: attribute.name, helperText: helperText.isEmpty ? null : helperText),
            items: [
              const DropdownMenuItem<String>(value: '', child: Text('(sin valor)')),
              ...attribute.options.map((item) => DropdownMenuItem(value: item.code, child: Text(item.label))),
            ],
            onChanged: (value) => setState(() => attributeSelections[attribute.id] = value == null || value.isEmpty ? null : value),
            validator: (value) => _validateAttribute(attribute, value),
          ),
        );
      case 'boolean':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: attributeSelections[attribute.id],
            decoration: InputDecoration(labelText: attribute.name, helperText: helperText.isEmpty ? null : helperText),
            items: const [
              DropdownMenuItem<String>(value: '', child: Text('(sin valor)')),
              DropdownMenuItem<String>(value: 'true', child: Text('Sí')),
              DropdownMenuItem<String>(value: 'false', child: Text('No')),
            ],
            onChanged: (value) => setState(() => attributeSelections[attribute.id] = value == null || value.isEmpty ? null : value),
            validator: (value) => _validateAttribute(attribute, value),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: attributeTextControllers[attribute.id],
            decoration: InputDecoration(
              labelText: attribute.name,
              helperText: helperText.isEmpty ? null : helperText,
              hintText: attribute.dataType == 'date'
                  ? 'AAAA-MM-DD'
                  : attribute.dataType == 'json'
                      ? '{"clave":"valor"}'
                      : null,
            ),
            minLines: attribute.dataType == 'json' ? 3 : 1,
            maxLines: attribute.dataType == 'json' ? 4 : 1,
            keyboardType: switch (attribute.dataType) {
              'integer' => TextInputType.number,
              'decimal' => const TextInputType.numberWithOptions(decimal: true),
              _ => TextInputType.text,
            },
            validator: (value) => _validateAttribute(attribute, value),
          ),
        );
    }
  }

  Widget _documentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Documentos guardados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                FilledButton.tonalIcon(
                  onPressed: documentsLoading ? null : _loadDocuments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recargar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (documentsLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (documentsError != null)
              Text(documentsError!, style: TextStyle(color: Colors.red.shade300))
            else if (documents.isEmpty)
              const Text('Todavía no hay documentos guardados en este nodo.')
            else
              ...documents.map(
                (document) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(document.title),
                  subtitle: Text('${document.pageCount} pág(s) • versión ${document.currentVersionNumber} • ${document.updatedAtLabel}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sessionSummaryCard() {
    final current = session;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: current == null
            ? const Text('Sin sesión de escaneo activa.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sesión actual', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(current.scannerName.isEmpty ? 'Escáner sin nombre' : current.scannerName),
                  Text('${current.mode} • ${current.pageCount} pág(s)'),
                  if (current.settings.dpi != null) Text('${current.settings.dpi!.toStringAsFixed(0)} DPI'),
                  Text('${current.settings.pixelType} • blancas ${current.settings.discardBlankPages}'),
                ],
              ),
      ),
    );
  }

  Widget _emptyPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
        color: const Color(0xFF0B1220),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner_outlined, size: 56),
              SizedBox(height: 12),
              Text('Sin páginas escaneadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Usa “Escanear” para iniciar una sesión o “Insertar hojas” para agregar páginas a una sesión existente.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(TwainScanPage page, bool selected) {
    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selectedPageNumber = page.pageNumber),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
              width: selected ? 2 : 1,
            ),
            color: const Color(0xFF0B1220),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Página ${page.pageNumber}', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    twain.previewUrl(session!.sessionId, page.pageNumber, width: 300, quality: 74),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: page.pageNumber == 1
                        ? null
                        : () => _mutateSession(() => twain.movePage(session!.sessionId, page.pageNumber, page.pageNumber - 1)),
                    icon: const Icon(Icons.arrow_back, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: page.pageNumber == session!.pageCount
                        ? null
                        : () => _mutateSession(() => twain.movePage(session!.sessionId, page.pageNumber, page.pageNumber + 1)),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _mutateSession(() => twain.rotatePage(session!.sessionId, page.pageNumber, 90)),
                    icon: const Icon(Icons.rotate_90_degrees_ccw_outlined, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() => selectedPageNumber = page.pageNumber);
                      _mutateSession(() => twain.deletePage(session!.sessionId, page.pageNumber));
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanAttributeDefinition {
  const ScanAttributeDefinition({
    required this.id,
    required this.name,
    required this.code,
    required this.dataType,
    required this.extension,
    required this.regex,
    required this.options,
  });

  final String id;
  final String name;
  final String code;
  final String dataType;
  final String extension;
  final String regex;
  final List<ScanAttributeOption> options;
}

class ScanAttributeOption {
  const ScanAttributeOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
}

class SavedNodeDocument {
  const SavedNodeDocument({
    required this.id,
    required this.title,
    required this.currentVersionNumber,
    required this.pageCount,
    required this.updatedAtLabel,
  });

  factory SavedNodeDocument.fromJson(Map<String, dynamic> json) => SavedNodeDocument(
        id: json['id'].toString(),
        title: (json['title'] ?? '').toString(),
        currentVersionNumber: (json['currentVersionNumber'] as num?)?.toInt() ?? 1,
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        updatedAtLabel: _formatUpdatedAt((json['updatedAt'] ?? '').toString()),
      );

  final String id;
  final String title;
  final int currentVersionNumber;
  final int pageCount;
  final String updatedAtLabel;
}

String _formatUpdatedAt(String value) {
  if (value.trim().isEmpty) {
    return 'sin fecha';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}
