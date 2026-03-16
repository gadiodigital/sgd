// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'scan_center_page.dart';

List<ScanAttributeDefinition> collectAllKnownAttributes(_ScanCenterPageState state) {
  final byId = <String, ScanAttributeDefinition>{};
  for (final a in state.widget.fallbackAttributes) {
    byId[a.id] = a;
  }
  for (final t in state.widget.documentTypes) {
    for (final a in t.attributes) {
      byId[a.id] = a;
    }
  }
  return byId.values.toList();
}

ScanDocumentTypeDefinition? findSelectedDocumentType(_ScanCenterPageState state) {
  for (final t in state.widget.documentTypes) {
    if (t.id == state.selectedDocumentTypeId) {
      return t;
    }
  }
  return null;
}

TwainScanPage? findSelectedPage(_ScanCenterPageState state) {
  final current = state.session;
  if (current == null || state.selectedPageNumber == null) {
    return null;
  }
  for (final p in current.pages) {
    if (p.pageNumber == state.selectedPageNumber) {
      return p;
    }
  }
  return current.pages.isEmpty ? null : current.pages.first;
}

Future<void> scanBootstrap(_ScanCenterPageState state) async {
  await Future.wait([
    state._loadScanners(),
    if (state.widget.canReadDocuments) state._loadDocuments(),
  ]);
}

Future<void> scanLoadScanners(_ScanCenterPageState state) async {
  state.setState(() {
    state.scannerLoading = true;
    state.scannerError = null;
  });
  try {
    final found = await state.twain.listScanners();
    if (!state.mounted) {
      return;
    }
    state.setState(() {
      state.scanners = found;
      state.selectedScannerId = found.any((i) => i.id == state.selectedScannerId)
          ? state.selectedScannerId
          : (found.isNotEmpty ? found.first.id : null);
    });
  } catch (error) {
    if (state._shouldAutoStartScanner(error) && !state.attemptedScannerAutoStart) {
      state.attemptedScannerAutoStart = true;
      if (await startLocalScannerHost()) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (state.mounted) {
          await state._loadScanners();
        }
        return;
      }
    }
    if (state.mounted) {
      state.setState(() => state.scannerError = state._friendlyScannerError(error));
    }
  } finally {
    if (state.mounted) {
      state.setState(() => state.scannerLoading = false);
    }
  }
}

Future<void> scanLoadDocuments(_ScanCenterPageState state) async {
  state.setState(() {
    state.documentsLoading = true;
    state.documentsError = null;
  });
  try {
    final items = await state.widget.api.listNodeDocuments(
      state.widget.projectId,
      state.widget.nodeId,
    );
    if (!state.mounted) {
      return;
    }
    state.setState(() => state.documents = items.map(SavedNodeDocument.fromJson).toList());
  } catch (error) {
    if (state.mounted) {
      state.setState(() => state.documentsError = state._errorText(error));
    }
  } finally {
    if (state.mounted) {
      state.setState(() => state.documentsLoading = false);
    }
  }
}

bool shouldAutoStartScanner(_ScanCenterPageState state, Object error) {
  final text = state._errorText(error).toLowerCase();
  return text.contains('127.0.0.1:43127') &&
      (text.contains('connection refused') ||
          text.contains('rechazó la conexión') ||
          text.contains('socketexception'));
}

String friendlyScannerError(_ScanCenterPageState state, Object error) {
  if (state._shouldAutoStartScanner(error)) {
    final command = localScannerStartCommand();
    return 'No se pudo conectar con windows-twain en http://127.0.0.1:43127.'
        '\n\nLa pantalla de escaneo necesita que el host local del escáner esté levantado.'
        '${command == null ? '' : '\n\nComando sugerido:\n$command'}';
  }
  return state._errorText(error);
}

String scanErrorText(Object error) =>
    error is ApiException ? error.message : error is TwainApiException ? error.message : error.toString();

Future<void> scanPages(_ScanCenterPageState state, {required _ScanMergeMode mode}) async {
  if (!state.widget.canWriteDocuments) {
    return;
  }
  state.setState(() {
    state.scanning = true;
    state.actionError = null;
    state.infoText = null;
  });
  try {
    final timeout = int.tryParse(state.timeoutController.text.trim()) ?? 90;
    if (timeout < 15 || timeout > 300) {
      throw TwainApiException('El timeout debe estar entre 15 y 300 segundos.');
    }
    final newSession = await state.twain.startScan(
      duplex: state.duplex,
      scannerId: state.selectedScannerId,
      dpi: state.dpi,
      pixelType: state.pixelType,
      discardBlankPages: state.discardBlankPages,
      timeoutSeconds: timeout,
    );
    TwainScanSession next = newSession;
    int? nextSelected = newSession.pageCount > 0 ? 1 : null;
    final current = state.session;
    if (mode != _ScanMergeMode.replace && current != null && current.pageCount > 0) {
      if (newSession.pageCount == 0) {
        next = current;
        nextSelected = state.selectedPageNumber;
      } else {
        final insertAfter = mode == _ScanMergeMode.appendToEnd
            ? current.pageCount
            : (state.selectedPageNumber ?? current.pageCount);
        next = await state.twain.mergeSession(
          current.sessionId,
          newSession.sessionId,
          insertAfterPageNumber: insertAfter,
        );
        nextSelected = (insertAfter + 1).clamp(1, next.pageCount);
      }
    }
    if (!state.mounted) {
      return;
    }
    state.setState(() {
      state.session = next;
      state.selectedPageNumber = nextSelected;
      state.previewMode = _ScanPreviewMode.edit;
      state.infoText = next.message;
    });
  } catch (error) {
    if (state.mounted) {
      state.setState(() => state.actionError = state._friendlyScannerError(error));
    }
  } finally {
    if (state.mounted) {
      state.setState(() => state.scanning = false);
    }
  }
}

Future<void> mutateScanSession(
  _ScanCenterPageState state,
  Future<TwainScanSession> Function() action,
) async {
  state.setState(() {
    state.actionError = null;
    state.infoText = null;
  });
  try {
    final updated = await action();
    if (!state.mounted) {
      return;
    }
    state.setState(() {
      state.session = updated;
      state.selectedPageNumber =
          updated.pageCount == 0 ? null : (state.selectedPageNumber ?? 1).clamp(1, updated.pageCount);
      if (updated.pageCount == 0) {
        state.previewMode = _ScanPreviewMode.edit;
      }
      state.infoText = updated.message;
    });
  } catch (error) {
    if (state.mounted) {
      state.setState(() => state.actionError = state._errorText(error));
    }
  }
}

Future<void> saveScannedDocument(_ScanCenterPageState state) async {
  if (!state.widget.canWriteDocuments) {
    return;
  }
  if (state.session == null || state.session!.pageCount == 0) {
    state.setState(() => state.actionError = 'Escanea al menos una página antes de guardar el documento.');
    return;
  }
  if (!(state.formKey.currentState?.validate() ?? false)) {
    state.setState(() => state.metadataExpanded = true);
    return;
  }
  state.setState(() {
    state.saving = true;
    state.actionError = null;
    state.infoText = null;
  });
  final values = <String, dynamic>{};
  for (final a in state.activeAttributes) {
    final v = state._attributeValue(a);
    if (v != null && v.trim().isNotEmpty) {
      values[a.id] = v.trim();
    }
  }
  try {
    await state.widget.api.createDocumentFromScan(
      state.widget.projectId,
      state.widget.nodeId,
      {
        'title': state.titleController.text.trim(),
        'description': state.descriptionController.text.trim(),
        'sessionId': state.session!.sessionId,
        'documentTypeId': state.selectedDocumentTypeId,
        'attributeValues': values,
      },
    );
    if (!state.mounted) {
      return;
    }
    state.setState(() {
      state.session = null;
      state.selectedPageNumber = null;
      state.previewMode = _ScanPreviewMode.edit;
      state.infoText = 'Documento guardado correctamente en la base de datos.';
    });
    if (state.widget.canReadDocuments) {
      await state._loadDocuments();
    }
  } catch (error) {
    if (state.mounted) {
      state.setState(() => state.actionError = state._errorText(error));
    }
  } finally {
    if (state.mounted) {
      state.setState(() => state.saving = false);
    }
  }
}

String? readAttributeValue(_ScanCenterPageState state, ScanAttributeDefinition a) =>
    switch (a.dataType) {
      'list' || 'boolean' => state.attributeSelections[a.id],
      _ => state.attributeTextControllers[a.id]?.text,
    };

String? validateAttributeValue(ScanAttributeDefinition a, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  switch (a.dataType) {
    case 'string':
      final limit = int.tryParse(a.extension);
      if (limit != null && text.length > limit) {
        return 'Máximo $limit caracteres.';
      }
      if (a.regex.isNotEmpty && !RegExp(a.regex).hasMatch(text)) {
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
      if (a.options.isNotEmpty && !a.options.any((i) => i.code == text)) {
        return 'Selecciona una opción válida.';
      }
    case 'boolean':
      if (text != 'true' && text != 'false') {
        return 'Selecciona Sí o No.';
      }
  }
  return null;
}

ThemeData buildScanTheme(ThemeData base) => base.copyWith(
      scaffoldBackgroundColor: _ScanCenterPageState._bg,
      colorScheme: const ColorScheme.dark(
        primary: _ScanCenterPageState._accent,
        onPrimary: Color(0xFF082F49),
        secondary: Color(0xFF22D3EE),
        onSecondary: Color(0xFF083344),
        surface: _ScanCenterPageState._surface,
        onSurface: _ScanCenterPageState._text,
        surfaceContainerHighest: _ScanCenterPageState._surfaceAlt,
        onSurfaceVariant: _ScanCenterPageState._muted,
        outline: _ScanCenterPageState._border,
        error: Color(0xFFFDA4AF),
        onError: Color(0xFF4C0519),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _ScanCenterPageState._text,
        displayColor: _ScanCenterPageState._text,
      ),
      disabledColor: const Color(0xFF94A3B8),
      hintColor: _ScanCenterPageState._muted,
      cardTheme: const CardThemeData(
        color: _ScanCenterPageState._surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: _ScanCenterPageState._border),
        ),
      ),
      canvasColor: _ScanCenterPageState._surfaceAlt,
      splashColor: _ScanCenterPageState._accent.withAlpha(28),
      highlightColor: _ScanCenterPageState._accent.withAlpha(18),
      dividerColor: Colors.transparent,
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: _ScanCenterPageState._text,
        collapsedIconColor: _ScanCenterPageState._text,
        textColor: _ScanCenterPageState._text,
        collapsedTextColor: _ScanCenterPageState._text,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: _ScanCenterPageState._text),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? const Color(0xFF94A3B8)
                : _ScanCenterPageState._text,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _ScanCenterPageState._surfaceAlt
                : _ScanCenterPageState._surface,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: _ScanCenterPageState._border),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _ScanCenterPageState._text
              : const Color(0xFFE2E8F0),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF0F766E)
              : const Color(0xFF475569),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: _ScanCenterPageState._muted),
        floatingLabelStyle: const TextStyle(color: _ScanCenterPageState._text),
        hintStyle: const TextStyle(color: _ScanCenterPageState._muted),
        helperStyle: const TextStyle(color: _ScanCenterPageState._muted),
        helperMaxLines: 3,
        errorStyle: const TextStyle(color: Color(0xFFFDA4AF)),
        filled: true,
        fillColor: _ScanCenterPageState._surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ScanCenterPageState._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ScanCenterPageState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ScanCenterPageState._accent, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFDA4AF)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 1.4),
        ),
      ),
    );
