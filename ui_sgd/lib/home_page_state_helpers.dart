// ignore_for_file: library_private_types_in_public_api

part of 'main.dart';

CurrentUser readCurrentUser(_HomePageState state) => state.widget.session.user;

List<String> readPermissionCodesForProject(_HomePageState state, String? projectId) {
  if (state.currentUser.isPlatformAdmin) {
    return state.widget.session.allPermissionCodes;
  }
  if (projectId == null) {
    return const [];
  }
  for (final membership in state.widget.session.memberships) {
    if (membership.projectId == projectId) {
      return membership.permissionCodes;
    }
  }
  return const [];
}

bool hasPermission(_HomePageState state, String permissionCode, String? projectId) {
  if (state.currentUser.isPlatformAdmin) {
    return true;
  }
  return state
      .permissionCodesForProject(projectId ?? state.currentProjectId)
      .contains(permissionCode);
}

void ensureSectionAvailable(_HomePageState state) {
  final options = state.availableSections;
  if (!options.contains(state.section)) {
    state.section = options.first;
  }
}

Section preferredSectionFor(_HomePageState state, String projectId) {
  if (state.can('types.read', projectId)) {
    return Section.tipos;
  }
  if (state.can('hierarchy.read', projectId)) {
    return Section.arbol;
  }
  if (state.can('security.read', projectId)) {
    return Section.seguridad;
  }
  return Section.proyectos;
}

List<T> sortItems<T>(List<T> items, int Function(T a, T b) sorter) {
  items.sort(sorter);
  return items;
}

void showSnack(_HomePageState state, String text) {
  ScaffoldMessenger.of(state.context).showSnackBar(SnackBar(content: Text(text)));
}

String homeErrorText(Object error) => error is ApiException ? error.message : error.toString();

bool shouldAutoStartApi(Object error, String Function(Object error) errorText) {
  final text = errorText(error).toLowerCase();
  return text.contains('127.0.0.1:8081') &&
      (text.contains('connection refused') ||
          text.contains('rechazó la conexión') ||
          text.contains('socketexception'));
}

String friendlyLoadError(
  Object error,
  bool Function(Object error) shouldAutoStart,
  String Function(Object error) errorText,
) {
  if (shouldAutoStart(error)) {
    final command = localApiStartCommand();
    final commandText = command == null ? '' : '\n\nComando sugerido:\n$command';
    return 'No se pudo conectar con la API local SGD en http://127.0.0.1:8081.'
        '\n\nLa UI ahora necesita que `sgd_api` esté levantada para leer y guardar datos.'
        '$commandText';
  }
  return errorText(error);
}

String nextId() => DateTime.now().microsecondsSinceEpoch.toString();
void focusNext(BuildContext context) => FocusScope.of(context).nextFocus();

String renderAttributeValueLabel(AttributeItem attr, String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return '-';
  }
  if (attr.dataType != 'list') {
    return rawValue;
  }
  for (final option in attr.options) {
    if (option.code == rawValue) {
      return option.label;
    }
  }
  return rawValue;
}

bool hasAttributeValue(String? rawValue) => rawValue != null && rawValue.trim().isNotEmpty;

String renderAttributeSummary(
  AttributeItem attr,
  String Function(String dataType) typeLabelBuilder,
) {
  final parts = <String>[typeLabelBuilder(attr.dataType)];
  if (attr.dataType == 'list') {
    parts.add(attr.options.isEmpty ? 'sin opciones' : '${attr.options.length} opciones');
    return parts.join(' • ');
  }
  if (attr.extension.isNotEmpty) {
    parts.add('ext ${attr.extension}');
  }
  if (attr.regex.isNotEmpty) {
    parts.add('regex');
  }
  return parts.join(' • ');
}

int readDocumentCount(Map<String, List<NodeDocumentSummary>> documentsByNodeId, String nodeId) =>
    documentsByNodeId[nodeId]?.length ?? 0;

TextInputType keyboardTypeFor(String dataType) => switch (dataType) {
      'integer' => TextInputType.number,
      'decimal' => const TextInputType.numberWithOptions(decimal: true),
      _ => TextInputType.text,
    };

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return 'Ingresa $label.';
  }
  return null;
}

String? validateProjectSlug(
  String? value,
  String? excludeProjectId,
  List<Project> projects,
) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Ingresa slug.';
  }
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(text)) {
    return 'Usa minúsculas, números y guiones.';
  }
  if (projects.any((project) => project.slug == text && project.id != excludeProjectId)) {
    return 'Ese slug ya existe.';
  }
  return null;
}

String? validateIdentifierCode(String? value, {String label = 'código'}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Ingresa $label.';
  }
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text)) {
    return 'Usa letras, números, guion o guion bajo.';
  }
  return null;
}

String? validateLoginName(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Ingresa usuario.';
  }
  if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(text)) {
    return 'Usa minúsculas, números, punto, guion o guion bajo.';
  }
  return null;
}

String? validateOrder(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Ingresa orden.';
  }
  final parsed = int.tryParse(text);
  if (parsed == null) {
    return 'Debe ser un número entero.';
  }
  if (parsed < 0) {
    return 'No puede ser negativo.';
  }
  return null;
}

bool isValidRegex(String value) {
  try {
    RegExp(value);
    return true;
  } catch (_) {
    return false;
  }
}

String? validateAttributeRawValue(AttributeItem attr, String value) {
  if (value.isEmpty) {
    return null;
  }
  switch (attr.dataType) {
    case 'integer':
      return int.tryParse(value) == null ? 'Debe ser un entero.' : null;
    case 'decimal':
      return num.tryParse(value) == null ? 'Debe ser un decimal válido.' : null;
    case 'date':
      return DateTime.tryParse(value) == null
          ? 'Usa una fecha válida, por ejemplo 2026-03-15.'
          : null;
    case 'boolean':
      final normalized = value.toLowerCase();
      return const {'true', 'false', '1', '0', 'si', 'sí', 'no'}.contains(normalized)
          ? null
          : 'Usa true/false, 1/0 o si/no.';
    case 'json':
      try {
        jsonDecode(value);
        return null;
      } catch (_) {
        return 'Ingresa JSON válido.';
      }
    default:
      if (attr.extension.isNotEmpty) {
        final maxLength = int.tryParse(attr.extension);
        if (maxLength != null && value.length > maxLength) {
          return 'Máximo $maxLength caracteres.';
        }
      }
      if (attr.regex.isNotEmpty && !RegExp(attr.regex).hasMatch(value)) {
        return 'No cumple la validación.';
      }
      return null;
  }
}

NodeTypeItem? findTypeById(List<NodeTypeItem> items, String id) {
  for (final item in items) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

NodeItem? findNodeById(List<NodeItem> items, String id) {
  for (final item in items) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

List<NodeItem> findChildrenByParent(List<NodeItem> items, String? parentId) =>
    items.where((n) => n.parentId == parentId).toList();

List<NodeTypeItem> findChildTypes(
  List<RuleItem> rules,
  List<NodeTypeItem> types,
  String parentTypeId,
) {
  final ids = rules
      .where((r) => r.parentTypeId == parentTypeId)
      .map((r) => r.childTypeId)
      .toSet();
  return types.where((t) => ids.contains(t.id)).toList();
}
