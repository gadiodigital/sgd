// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'scan_center_page.dart';

Widget buildScanCenterPage(_ScanCenterPageState state, BuildContext context) {
  return Theme(
    data: state._theme(Theme.of(context)),
    child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            state._topBar(),
            if (state.actionError != null) state._banner(state.actionError!, true),
            if (state.actionError == null && state.infoText != null) state._banner(state.infoText!, false),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1180;
                  if (compact) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        SizedBox(height: 840, child: state._rightPane(true)),
                        const SizedBox(height: 16),
                        state._leftPane(false),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 400, child: state._leftPane(true)),
                        const SizedBox(width: 16),
                        Expanded(child: state._rightPane(false)),
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

Widget buildScanTopBar(_ScanCenterPageState state) {
  final statusOk = state.scannerError == null;
  return Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: _ScanCenterPageState._surface,
      border: Border(bottom: BorderSide(color: _ScanCenterPageState._border)),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(state.context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        const Text(
          'SGD',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Centro de escaneo · ${state.widget.projectName} · ${state.widget.nodeName}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: statusOk ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
            border: Border.all(
              color: statusOk ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusOk ? Icons.check_circle_outline : Icons.portable_wifi_off,
                size: 16,
                color: statusOk ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
              ),
              const SizedBox(width: 8),
              Text(statusOk ? 'Escáner listo' : 'Escáner no disponible'),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildScanBanner(String text, bool isError) {
  final color = isError ? const Color(0xFFFDA4AF) : const Color(0xFF86EFAC);
  final bg = isError ? const Color(0xFF4C0519) : const Color(0xFF052E16);
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.55)),
      color: bg,
    ),
    child: Text(text, style: TextStyle(color: color, height: 1.4)),
  );
}

Widget buildScanLeftPane(_ScanCenterPageState state, bool scrollable) {
  final child = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      state._sectionCard(
        'Escáner',
        'Origen TWAIN y disponibilidad.',
        state.scannerExpanded,
        (v) => state.setState(() => state.scannerExpanded = v),
        state._scannerBody(),
      ),
      const SizedBox(height: 16),
      state._sectionCard(
        'Configuración',
        'Modo, color, resolución y timeout.',
        state.configExpanded,
        (v) => state.setState(() => state.configExpanded = v),
        state._configBody(),
      ),
      const SizedBox(height: 16),
      state._sectionCard(
        'Documento',
        state.widget.documentTypes.isEmpty
            ? 'No hay tipos documentales; se usa el esquema heredado del contenedor.'
            : 'Selecciona el tipo documental y completa sus atributos.',
        state.metadataExpanded,
        (v) => state.setState(() => state.metadataExpanded = v),
        state._documentBody(),
      ),
      if (state.widget.canReadDocuments) ...[
        const SizedBox(height: 16),
        state._sectionCard(
          'Documentos guardados',
          'Historial del nodo actual.',
          state.documentsExpanded,
          (v) => state.setState(() => state.documentsExpanded = v),
          state._documentsBody(),
        ),
      ],
    ],
  );
  return scrollable
      ? Scrollbar(thumbVisibility: true, child: SingleChildScrollView(child: child))
      : child;
}

Widget buildScanSectionCard(
  _ScanCenterPageState state,
  String title,
  String subtitle,
  bool expanded,
  ValueChanged<bool> onExpansionChanged,
  Widget child,
) {
  return Card(
    child: Theme(
      data: Theme.of(state.context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey<String>('section-$title'),
        initiallyExpanded: expanded,
        maintainState: true,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(color: _ScanCenterPageState._muted, height: 1.35)),
        ),
        children: [child],
      ),
    ),
  );
}

Widget buildScanScannerBody(_ScanCenterPageState state) {
  if (state.scannerLoading) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
          onPressed: state._loadScanners,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ),
      const SizedBox(height: 12),
      if (state.scannerError != null)
        Text(
          state.scannerError!,
          style: const TextStyle(color: Color(0xFFFDA4AF), height: 1.4),
        ),
      if (state.scannerError == null && state.scanners.isEmpty)
        const Text(
          'No se detectaron escáneres TWAIN en este equipo.',
          style: TextStyle(color: _ScanCenterPageState._muted),
        ),
      if (state.scannerError == null && state.scanners.isNotEmpty)
        DropdownButtonFormField<int>(
          initialValue: state.selectedScannerId,
          decoration: const InputDecoration(labelText: 'Escáner disponible'),
          dropdownColor: _ScanCenterPageState._surfaceAlt,
          style: const TextStyle(color: _ScanCenterPageState._text),
          items: state.scanners
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    '${s.name} · ${s.manufacturer}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: state.widget.canWriteDocuments
              ? (value) => state.setState(() => state.selectedScannerId = value)
              : null,
        ),
    ],
  );
}

Widget buildScanConfigBody(_ScanCenterPageState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: false, icon: Icon(Icons.filter_1), label: Text('Simple')),
          ButtonSegment(value: true, icon: Icon(Icons.copy_all_outlined), label: Text('Doble faz')),
        ],
        selected: {state.duplex},
        onSelectionChanged: state.widget.canWriteDocuments
            ? (value) => state.setState(() => state.duplex = value.first)
            : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: state.pixelType,
        decoration: const InputDecoration(labelText: 'Color'),
        dropdownColor: _ScanCenterPageState._surfaceAlt,
        style: const TextStyle(color: _ScanCenterPageState._text),
        items: state.pixelTypes.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(color: _ScanCenterPageState._text)),
              ),
            )
            .toList(),
        onChanged: state.widget.canWriteDocuments
            ? (value) => state.setState(() => state.pixelType = value ?? 'gray')
            : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        initialValue: state.dpi,
        decoration: const InputDecoration(labelText: 'Resolución'),
        dropdownColor: _ScanCenterPageState._surfaceAlt,
        style: const TextStyle(color: _ScanCenterPageState._text),
        items: state.dpiOptions
            .map(
              (v) => DropdownMenuItem<int?>(
                value: v,
                child: Text(
                  v == null ? 'Auto' : '$v DPI',
                  style: const TextStyle(color: _ScanCenterPageState._text),
                ),
              ),
            )
            .toList(),
        onChanged: state.widget.canWriteDocuments
            ? (value) => state.setState(() => state.dpi = value)
            : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: state.timeoutController,
        decoration: const InputDecoration(labelText: 'Timeout (segundos)'),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => state._scan(mode: _ScanMergeMode.replace),
      ),
      const SizedBox(height: 6),
      SwitchListTile(
        value: state.discardBlankPages,
        onChanged: state.widget.canWriteDocuments
            ? (value) => state.setState(() => state.discardBlankPages = value)
            : null,
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Descartar hojas en blanco',
          style: TextStyle(color: _ScanCenterPageState._text),
        ),
        subtitle: const Text(
          'Evita sumar páginas vacías cuando el driver lo soporta.',
          style: TextStyle(color: _ScanCenterPageState._muted),
        ),
      ),
    ],
  );
}

Widget buildScanDocumentBody(_ScanCenterPageState state) {
  return Form(
    key: state.formKey,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Proyecto: ${state.widget.projectName}\n'
          'Nodo: ${state.widget.nodeName}\n'
          'Tipo de contenedor: ${state.widget.nodeTypeName}',
          style: const TextStyle(color: _ScanCenterPageState._muted, height: 1.45),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: state.titleController,
          decoration: const InputDecoration(labelText: 'Título del documento'),
          textInputAction: TextInputAction.next,
          validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el título.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: state.descriptionController,
          decoration: const InputDecoration(labelText: 'Descripción'),
          minLines: 2,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        if (state.widget.documentTypes.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: state.selectedDocumentTypeId,
            decoration: const InputDecoration(labelText: 'Tipo documental'),
            dropdownColor: _ScanCenterPageState._surfaceAlt,
            style: const TextStyle(color: _ScanCenterPageState._text),
            items: state.widget.documentTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      '${t.name} (${t.code})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ScanCenterPageState._text),
                    ),
                  ),
                )
                .toList(),
            onChanged: state.widget.canWriteDocuments
                ? (value) => state.setState(() => state.selectedDocumentTypeId = value)
                : null,
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ScanCenterPageState._border),
              color: _ScanCenterPageState._surfaceAlt,
            ),
            child: const Text(
              'No hay tipos documentales definidos. La carga usa atributos heredados del contenedor.',
              style: TextStyle(color: _ScanCenterPageState._muted, height: 1.35),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          state.selectedDocumentType != null
              ? 'Atributos del tipo documental'
              : 'Atributos heredados del contenedor',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (state.activeAttributes.isEmpty)
          Text(
            state.selectedDocumentType != null
                ? 'Este tipo documental no define atributos adicionales.'
                : 'El contenedor actual no aporta atributos heredados.',
            style: const TextStyle(color: _ScanCenterPageState._muted),
          ),
        ...state.activeAttributes.map(state._attributeField),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: state.saving || !state.widget.canWriteDocuments ? null : state._saveDocument,
          icon: state.saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: const Text('Guardar documento'),
        ),
        if (!state.widget.canWriteDocuments) ...[
          const SizedBox(height: 10),
          const Text(
            'Tu perfil solo puede consultar documentos; no puede escanear ni guardar.',
            style: TextStyle(color: Color(0xFFFCD34D), height: 1.35),
          ),
        ],
      ],
    ),
  );
}

Widget buildScanDocumentsBody(_ScanCenterPageState state) {
  if (state.documentsLoading) {
    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
          onPressed: state._loadDocuments,
          icon: const Icon(Icons.refresh),
          label: const Text('Recargar'),
        ),
      ),
      const SizedBox(height: 12),
      if (state.documentsError != null)
        Text(
          state.documentsError!,
          style: const TextStyle(color: Color(0xFFFDA4AF), height: 1.4),
        ),
      if (state.documentsError == null && state.documents.isEmpty)
        const Text(
          'Todavía no hay documentos guardados en este nodo.',
          style: TextStyle(color: _ScanCenterPageState._muted),
        ),
      ...state.documents.map(
        (d) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(d.title),
          subtitle: Text(
            [
              if (d.documentTypeName.isNotEmpty) d.documentTypeName,
              '${d.pageCount} pág(s)',
              'versión ${d.currentVersionNumber}',
              d.updatedAtLabel,
            ].join(' · '),
          ),
        ),
      ),
    ],
  );
}

Widget buildScanAttributeField(_ScanCenterPageState state, ScanAttributeDefinition a) {
  final helper = [
    a.code,
    a.dataType,
    if (a.extension.isNotEmpty) 'ext ${a.extension}',
    if (a.regex.isNotEmpty) 'regex',
  ].join(' · ');
  if (a.dataType == 'list' || a.dataType == 'boolean') {
    final items = a.dataType == 'boolean'
        ? const [
            DropdownMenuItem<String>(value: '', child: Text('(sin valor)')),
            DropdownMenuItem<String>(value: 'true', child: Text('Sí')),
            DropdownMenuItem<String>(value: 'false', child: Text('No')),
          ]
        : [
            const DropdownMenuItem<String>(value: '', child: Text('(sin valor)')),
            ...a.options.map((o) => DropdownMenuItem<String>(value: o.code, child: Text(o.label))),
          ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: state.attributeSelections[a.id],
        decoration: InputDecoration(labelText: a.name, helperText: helper),
        dropdownColor: _ScanCenterPageState._surfaceAlt,
        style: const TextStyle(color: _ScanCenterPageState._text),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item.value,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: _ScanCenterPageState._text),
                  child: item.child,
                ),
              ),
            )
            .toList(),
        onChanged: (value) => state.setState(
          () => state.attributeSelections[a.id] = value == null || value.isEmpty ? null : value,
        ),
        validator: (value) => state._validateAttribute(a, value),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: state.attributeTextControllers[a.id],
      decoration: InputDecoration(
        labelText: a.name,
        helperText: helper,
        hintText: a.dataType == 'date'
            ? 'AAAA-MM-DD'
            : a.dataType == 'json'
                ? '{"clave":"valor"}'
                : null,
      ),
      minLines: a.dataType == 'json' ? 3 : 1,
      maxLines: a.dataType == 'json' ? 4 : 1,
      keyboardType: a.dataType == 'integer'
          ? TextInputType.number
          : a.dataType == 'decimal'
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      textInputAction: a.dataType == 'json' ? TextInputAction.newline : TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(state.context).nextFocus(),
      validator: (value) => state._validateAttribute(a, value),
    ),
  );
}

Widget buildScanRightPane(_ScanCenterPageState state, bool compact) {
  final title = state.previewMode == _ScanPreviewMode.pdf ? 'PDF temporal' : 'Vista previa y edición';
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      state.previewMode == _ScanPreviewMode.pdf
                          ? 'Vista integrada del PDF temporal. No se expone descarga directa desde la UI.'
                          : 'Edición de páginas, reordenamiento y ajustes sobre la sesión actual.',
                      style: const TextStyle(color: _ScanCenterPageState._muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (!compact) SizedBox(width: 340, child: state._sessionSummary()),
            ],
          ),
          if (compact) ...[const SizedBox(height: 12), state._sessionSummary()],
          const SizedBox(height: 14),
          state._toolbar(),
          const SizedBox(height: 18),
          Expanded(
            child: state.session == null || state.session!.pageCount == 0
                ? state._emptyPreview()
                : state.previewMode == _ScanPreviewMode.pdf
                    ? state._pdfPreview()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: state._selectedPreview()),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 210,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.session!.pages.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 12),
                              itemBuilder: (_, index) => state._thumbnail(
                                state.session!.pages[index],
                                state.session!.pages[index].pageNumber == state.selectedPageNumber,
                              ),
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

Widget buildScanSessionSummary(_ScanCenterPageState state) {
  final current = state.session;
  return Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: current == null
          ? const Text('Sin sesión de escaneo activa.', style: TextStyle(color: _ScanCenterPageState._muted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sesión actual', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(current.scannerName.isEmpty ? 'Escáner sin nombre' : current.scannerName),
                const SizedBox(height: 4),
                Text('${current.mode} · ${current.pageCount} pág(s)'),
                if (current.settings.dpi != null) Text('${current.settings.dpi!.toStringAsFixed(0)} DPI'),
                Text(
                  '${current.settings.pixelType} · blancas ${current.settings.discardBlankPages}',
                  style: const TextStyle(color: _ScanCenterPageState._muted),
                ),
                if (state.selectedDocumentType != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tipo documental: ${state.selectedDocumentType!.name}',
                    style: const TextStyle(color: _ScanCenterPageState._muted),
                  ),
                ],
              ],
            ),
    ),
  );
}

Widget buildScanToolbar(_ScanCenterPageState state) {
  final current = state.session;
  final page = state.selectedPageNumber;
  final pageCount = current?.pageCount ?? 0;
  final canMutate = current != null && page != null;
  final canBack = canMutate && page > 1 && pageCount > 1;
  final canForward = canMutate && page < pageCount;
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      state._toolIcon(
        Icons.document_scanner_outlined,
        current == null ? 'Escanear' : 'Reemplazar sesión',
        state.scannerLoading || state.scanning || !state.widget.canWriteDocuments
            ? null
            : () => state._scan(mode: _ScanMergeMode.replace),
        busy: state.scanning,
      ),
      state._toolIcon(
        Icons.input_outlined,
        'Insertar páginas después de la hoja seleccionada',
        state.scannerLoading || state.scanning || current == null || !state.widget.canWriteDocuments
            ? null
            : () => state._scan(mode: _ScanMergeMode.insertAfterCurrent),
      ),
      state._toolIcon(
        Icons.playlist_add_outlined,
        'Insertar páginas al final de la sesión',
        state.scannerLoading || state.scanning || current == null || !state.widget.canWriteDocuments
            ? null
            : () => state._scan(mode: _ScanMergeMode.appendToEnd),
      ),
      state._toolIcon(
        Icons.preview_outlined,
        'Ver edición de páginas',
        current == null ? null : () => state.setState(() => state.previewMode = _ScanPreviewMode.edit),
        selected: state.previewMode == _ScanPreviewMode.edit,
      ),
      state._toolIcon(
        Icons.picture_as_pdf_outlined,
        'Ver PDF temporal dentro de la aplicación',
        current == null ? null : () => state.setState(() => state.previewMode = _ScanPreviewMode.pdf),
        selected: state.previewMode == _ScanPreviewMode.pdf,
      ),
      state._toolIcon(
        Icons.rotate_90_degrees_ccw_outlined,
        'Rotar página 90 grados',
        !canMutate ? null : () => state._mutateSession(() => state.twain.rotatePage(current.sessionId, page, 90)),
      ),
      state._toolIcon(
        Icons.first_page,
        'Mover página al inicio',
        !canBack ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page, 1)),
      ),
      state._toolIcon(
        Icons.chevron_left,
        'Mover página una posición hacia atrás',
        !canBack ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page, page - 1)),
      ),
      state._toolIcon(
        Icons.chevron_right,
        'Mover página una posición hacia adelante',
        !canForward ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page, page + 1)),
      ),
      state._toolIcon(
        Icons.last_page,
        'Mover página al final',
        !canForward ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page, current.pageCount)),
      ),
      state._toolIcon(
        Icons.brightness_high_outlined,
        'Subir brillo',
        !canMutate ? null : () => state._mutateSession(() => state.twain.adjustPage(current.sessionId, page, brightness: 10, contrast: 0)),
      ),
      state._toolIcon(
        Icons.brightness_low_outlined,
        'Bajar brillo',
        !canMutate ? null : () => state._mutateSession(() => state.twain.adjustPage(current.sessionId, page, brightness: -10, contrast: 0)),
      ),
      state._toolIcon(
        Icons.contrast_outlined,
        'Subir contraste',
        !canMutate ? null : () => state._mutateSession(() => state.twain.adjustPage(current.sessionId, page, brightness: 0, contrast: 10)),
      ),
      state._toolIcon(
        Icons.tonality_outlined,
        'Bajar contraste',
        !canMutate ? null : () => state._mutateSession(() => state.twain.adjustPage(current.sessionId, page, brightness: 0, contrast: -10)),
      ),
      state._toolIcon(
        Icons.delete_outline,
        'Eliminar página',
        !canMutate ? null : () => state._mutateSession(() => state.twain.deletePage(current.sessionId, page)),
        isDanger: true,
      ),
    ],
  );
}

Widget buildScanToolIcon(
  _ScanCenterPageState state,
  IconData icon,
  String tooltip,
  VoidCallback? onPressed, {
  bool selected = false,
  bool busy = false,
  bool isDanger = false,
}) {
  final scheme = Theme.of(state.context).colorScheme;
  final bg = selected
      ? scheme.primaryContainer
      : isDanger
          ? const Color(0xFF3F0D18)
          : scheme.surfaceContainerHighest;
  final fg = selected
      ? scheme.onPrimaryContainer
      : isDanger
          ? const Color(0xFFFDA4AF)
          : scheme.onSurface;
  return Tooltip(
    message: tooltip,
    child: IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: bg, foregroundColor: fg),
      icon: busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
    ),
  );
}

Widget buildScanEmptyPreview() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _ScanCenterPageState._border),
      color: const Color(0xFF040B19),
    ),
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_outlined, size: 56, color: _ScanCenterPageState._muted),
            SizedBox(height: 12),
            Text('Sin páginas escaneadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text(
              'Usa los botones superiores para escanear, insertar hojas o construir el PDF temporal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ScanCenterPageState._muted, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSelectedPreview(_ScanCenterPageState state) {
  final page = state.selectedPage;
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF040B19),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _ScanCenterPageState._border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: page == null
          ? const Center(child: Text('Selecciona una página.', style: TextStyle(color: _ScanCenterPageState._muted)))
          : InteractiveViewer(
              minScale: 0.6,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  state.twain.previewUrl(state.session!.sessionId, page.pageNumber, width: 1500, quality: 88),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'No se pudo renderizar la vista previa.',
                      style: TextStyle(color: _ScanCenterPageState._muted),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}

Widget buildPdfPreview(_ScanCenterPageState state) {
  final current = state.session!;
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF040B19),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _ScanCenterPageState._border),
    ),
    child: ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: current.pages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (_, index) {
        final page = current.pages[index];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Página ${page.pageNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _ScanCenterPageState._muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => state.setState(() {
                    state.selectedPageNumber = page.pageNumber;
                    state.previewMode = _ScanPreviewMode.edit;
                  }),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
                    child: AspectRatio(
                      aspectRatio: 1 / 1.414,
                      child: Image.network(
                        state.twain.previewUrl(current.sessionId, page.pageNumber, width: 1200, quality: 88),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text('No se pudo renderizar esta página.', style: TextStyle(color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget buildScanThumbnail(_ScanCenterPageState state, TwainScanPage page, bool selected) {
  final current = state.session!;
  final canBack = page.pageNumber > 1;
  final canForward = page.pageNumber < current.pageCount;
  return SizedBox(
    width: 164,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => state.setState(() => state.selectedPageNumber = page.pageNumber),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _ScanCenterPageState._accent : _ScanCenterPageState._border,
            width: selected ? 2 : 1,
          ),
          color: const Color(0xFF040B19),
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
                  state.twain.previewUrl(current.sessionId, page.pageNumber, width: 320, quality: 76),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: _ScanCenterPageState._surfaceAlt,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                Tooltip(
                  message: 'Mover al inicio',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: !canBack ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page.pageNumber, 1)),
                    icon: const Icon(Icons.first_page, size: 18),
                  ),
                ),
                Tooltip(
                  message: 'Mover hacia atrás',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: !canBack ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page.pageNumber, page.pageNumber - 1)),
                    icon: const Icon(Icons.chevron_left, size: 18),
                  ),
                ),
                Tooltip(
                  message: 'Rotar',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => state._mutateSession(() => state.twain.rotatePage(current.sessionId, page.pageNumber, 90)),
                    icon: const Icon(Icons.rotate_90_degrees_ccw_outlined, size: 18),
                  ),
                ),
                Tooltip(
                  message: 'Mover hacia adelante',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: !canForward ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page.pageNumber, page.pageNumber + 1)),
                    icon: const Icon(Icons.chevron_right, size: 18),
                  ),
                ),
                Tooltip(
                  message: 'Mover al final',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: !canForward ? null : () => state._mutateSession(() => state.twain.movePage(current.sessionId, page.pageNumber, current.pageCount)),
                    icon: const Icon(Icons.last_page, size: 18),
                  ),
                ),
                Tooltip(
                  message: 'Eliminar',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      state.setState(() => state.selectedPageNumber = page.pageNumber);
                      state._mutateSession(() => state.twain.deletePage(current.sessionId, page.pageNumber));
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
