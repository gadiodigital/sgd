import 'dart:convert';

import 'package:flutter/material.dart';

import 'domain/scan_entities.dart';
import 'local_scanner_runtime_stub.dart'
    if (dart.library.io) 'local_scanner_runtime_io.dart';
import 'sgd_api_client.dart';
import 'windows_twain_client.dart';

part 'scan_center_page_logic.dart';
part 'scan_center_page_ui.dart';

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
  static const _bg = Color(0xFF0B1120),
      _surface = Color(0xFF172033),
      _surfaceAlt = Color(0xFF1F2A3F),
      _border = Color(0xFF334155),
      _accent = Color(0xFF7DD3FC),
      _text = Color(0xFFF8FAFC),
      _muted = Color(0xFFCBD5E1);

  final formKey = GlobalKey<FormState>();
  late final WindowsTwainClient twain;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController timeoutController;
  final attributeTextControllers = <String, TextEditingController>{};
  final attributeSelections = <String, String?>{};
  final dpiOptions = const <int?>[null, 100, 150, 200, 300, 600];
  final pixelTypes = const {
    'bw': 'Blanco y negro',
    'gray': 'Escala de grises',
    'color': 'Color',
  };
  List<TwainScannerDescriptor> scanners = const [];
  List<SavedNodeDocument> documents = const [];
  TwainScanSession? session;
  int? selectedPageNumber;
  int? selectedScannerId;
  int? dpi = 300;
  String pixelType = 'gray';
  String? selectedDocumentTypeId;
  bool duplex = false;
  bool discardBlankPages = false;
  bool scannerLoading = true;
  bool documentsLoading = false;
  bool scanning = false;
  bool saving = false;
  bool attemptedScannerAutoStart = false;
  bool scannerExpanded = true;
  bool configExpanded = true;
  bool metadataExpanded = true;
  bool documentsExpanded = false;
  _ScanPreviewMode previewMode = _ScanPreviewMode.edit;
  String? scannerError;
  String? documentsError;
  String? actionError;
  String? infoText;

  @override
  void initState() {
    super.initState();
    twain = widget.twain ?? WindowsTwainClient();
    titleController = TextEditingController(
      text: widget.nodeCode.isEmpty
          ? widget.nodeName
          : '${widget.nodeCode} - ${widget.nodeName}',
    );
    descriptionController = TextEditingController();
    timeoutController = TextEditingController(text: '90');
    selectedDocumentTypeId =
        widget.documentTypes.isNotEmpty ? widget.documentTypes.first.id : null;
    for (final a in _allKnownAttributes) {
      attributeTextControllers[a.id] = TextEditingController();
      attributeSelections[a.id] = null;
    }
    _bootstrap();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    timeoutController.dispose();
    for (final c in attributeTextControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<ScanAttributeDefinition> get _allKnownAttributes =>
      collectAllKnownAttributes(this);

  ScanDocumentTypeDefinition? get selectedDocumentType =>
      findSelectedDocumentType(this);

  List<ScanAttributeDefinition> get activeAttributes =>
      selectedDocumentType?.attributes ?? widget.fallbackAttributes;

  TwainScanPage? get selectedPage => findSelectedPage(this);

  Future<void> _bootstrap() => scanBootstrap(this);
  Future<void> _loadScanners() => scanLoadScanners(this);
  Future<void> _loadDocuments() => scanLoadDocuments(this);
  bool _shouldAutoStartScanner(Object error) => shouldAutoStartScanner(this, error);
  String _friendlyScannerError(Object error) => friendlyScannerError(this, error);
  String _errorText(Object error) => scanErrorText(error);
  Future<void> _scan({required _ScanMergeMode mode}) => scanPages(this, mode: mode);
  Future<void> _mutateSession(Future<TwainScanSession> Function() action) =>
      mutateScanSession(this, action);
  Future<void> _saveDocument() => saveScannedDocument(this);
  String? _attributeValue(ScanAttributeDefinition a) => readAttributeValue(this, a);
  String? _validateAttribute(ScanAttributeDefinition a, String? value) =>
      validateAttributeValue(a, value);
  ThemeData _theme(ThemeData base) => buildScanTheme(base);

  @override
  Widget build(BuildContext context) => buildScanCenterPage(this, context);

  Widget _topBar() => buildScanTopBar(this);
  Widget _banner(String text, bool isError) => buildScanBanner(text, isError);
  Widget _leftPane(bool scrollable) => buildScanLeftPane(this, scrollable);
  Widget _sectionCard(
    String title,
    String subtitle,
    bool expanded,
    ValueChanged<bool> onExpansionChanged,
    Widget child,
  ) =>
      buildScanSectionCard(
        this,
        title,
        subtitle,
        expanded,
        onExpansionChanged,
        child,
      );
  Widget _scannerBody() => buildScanScannerBody(this);
  Widget _configBody() => buildScanConfigBody(this);
  Widget _documentBody() => buildScanDocumentBody(this);
  Widget _documentsBody() => buildScanDocumentsBody(this);
  Widget _attributeField(ScanAttributeDefinition a) => buildScanAttributeField(this, a);
  Widget _rightPane(bool compact) => buildScanRightPane(this, compact);
  Widget _sessionSummary() => buildScanSessionSummary(this);
  Widget _toolbar() => buildScanToolbar(this);
  Widget _toolIcon(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed, {
    bool selected = false,
    bool busy = false,
    bool isDanger = false,
  }) =>
      buildScanToolIcon(
        this,
        icon,
        tooltip,
        onPressed,
        selected: selected,
        busy: busy,
        isDanger: isDanger,
      );
  Widget _emptyPreview() => buildScanEmptyPreview();
  Widget _selectedPreview() => buildSelectedPreview(this);
  Widget _pdfPreview() => buildPdfPreview(this);
  Widget _thumbnail(TwainScanPage page, bool selected) =>
      buildScanThumbnail(this, page, selected);
}
