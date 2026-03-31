import 'package:flutter/material.dart';

import 'scan_document_active_sessions_support.dart';

final class ScanDocumentActiveSessionsSummaryViewData {
  const ScanDocumentActiveSessionsSummaryViewData({
    required this.healthLabel,
    required this.healthBadgeLabel,
    required this.healthDescription,
    required this.healthBackgroundColor,
    required this.healthForegroundColor,
    required this.affectedSessions,
    required this.affectedRatioLabel,
    required this.severityLabel,
    required this.operationalRiskLabel,
    required this.operationalRiskBackgroundColor,
    required this.operationalRiskForegroundColor,
    required this.dominantStateLabel,
    required this.dominantPatternRecommendation,
    required this.nextStepRecommendation,
    required this.focus,
  });

  final String healthLabel;
  final String healthBadgeLabel;
  final String healthDescription;
  final Color healthBackgroundColor;
  final Color healthForegroundColor;
  final int affectedSessions;
  final String affectedRatioLabel;
  final String severityLabel;
  final String operationalRiskLabel;
  final Color operationalRiskBackgroundColor;
  final Color operationalRiskForegroundColor;
  final String dominantStateLabel;
  final String dominantPatternRecommendation;
  final String nextStepRecommendation;
  final String? focus;
}

final class ScanDocumentActiveSessionsSummarySupport {
  static ScanDocumentActiveSessionsSummaryViewData resolve(
    ScanDocumentSessionSummary summary,
  ) {
    final health = _resolveHealth(summary);
    final affectedSessions = health.affectedSessions(summary);
    final severity = _resolveAffectedSeverity(
      affectedSessions: affectedSessions,
      totalSessions: summary.totalSessions,
    );
    final dominantState = _resolveDominantState(summary);
    final operationalRisk = _resolveOperationalRisk(
      severity: severity,
      dominantState: dominantState,
    );
    return ScanDocumentActiveSessionsSummaryViewData(
      healthLabel: health.label,
      healthBadgeLabel: health.badgeLabel,
      healthDescription: health.description,
      healthBackgroundColor: health.backgroundColor,
      healthForegroundColor: health.foregroundColor,
      affectedSessions: affectedSessions,
      affectedRatioLabel: _formatAffectedRatio(
        affectedSessions: affectedSessions,
        totalSessions: summary.totalSessions,
      ),
      severityLabel: severity.label,
      operationalRiskLabel: operationalRisk.label,
      operationalRiskBackgroundColor: operationalRisk.backgroundColor,
      operationalRiskForegroundColor: operationalRisk.foregroundColor,
      dominantStateLabel: dominantState.label,
      dominantPatternRecommendation: dominantState.recommendation,
      nextStepRecommendation: severity.recommendation,
      focus: health.focus(summary),
    );
  }
}

_ScanDocumentSessionHealth _resolveHealth(ScanDocumentSessionSummary summary) {
  if (summary.totalSessions == 0) {
    return const _ScanDocumentSessionHealth(
      label: 'sin sesiones',
      badgeLabel: 'Sin datos',
      description: 'No hay sesiones visibles para resumir.',
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.blueGrey,
      affectedSessions: _zeroAffectedSessions,
      focus: _noFocus,
    );
  }
  if (summary.errorSessions > 0) {
    return const _ScanDocumentSessionHealth(
      label: 'con incidencias',
      badgeLabel: 'Atencion alta',
      description: 'Hay sesiones con error dentro del subconjunto visible.',
      backgroundColor: Colors.red,
      foregroundColor: Colors.red,
      affectedSessions: _errorAffectedSessions,
      focus: _errorFocus,
    );
  }
  if (summary.attentionSessions > 0) {
    return const _ScanDocumentSessionHealth(
      label: 'con seguimiento',
      badgeLabel: 'Revisar',
      description: 'No hay errores, pero si sesiones rehidratadas o inactivas.',
      backgroundColor: Colors.orange,
      foregroundColor: Colors.orange,
      affectedSessions: _attentionAffectedSessions,
      focus: _attentionFocus,
    );
  }
  return const _ScanDocumentSessionHealth(
    label: 'limpio',
    badgeLabel: 'OK',
    description: 'El subconjunto visible no muestra sesiones con atencion.',
    backgroundColor: Colors.green,
    foregroundColor: Colors.green,
    affectedSessions: _zeroAffectedSessions,
    focus: _noFocus,
  );
}

int _zeroAffectedSessions(ScanDocumentSessionSummary summary) => 0;
int _errorAffectedSessions(ScanDocumentSessionSummary summary) =>
    summary.errorSessions;
int _attentionAffectedSessions(ScanDocumentSessionSummary summary) =>
    summary.attentionSessions;
String? _noFocus(ScanDocumentSessionSummary summary) => null;
String _errorFocus(ScanDocumentSessionSummary summary) =>
    '${summary.errorSessions} con error para revisar primero';
String _attentionFocus(ScanDocumentSessionSummary summary) =>
    '${summary.rehydratedSessions} rehidratadas · ${summary.staleSessions} inactivas';

String _formatAffectedRatio({
  required int affectedSessions,
  required int totalSessions,
}) {
  if (totalSessions <= 0) {
    return 'sin datos';
  }
  final ratio = (affectedSessions * 100) / totalSessions;
  return '${ratio.toStringAsFixed(0)}% del subconjunto visible';
}

_AffectedSeverity _resolveAffectedSeverity({
  required int affectedSessions,
  required int totalSessions,
}) {
  if (totalSessions <= 0 || affectedSessions <= 0) {
    return const _AffectedSeverity(
      'nula',
      'Mantener monitoreo normal sobre el subconjunto visible.',
    );
  }
  final ratio = affectedSessions / totalSessions;
  if (ratio >= 0.5) {
    return const _AffectedSeverity(
      'alta',
      'Priorizar limpieza o reanudacion sobre las sesiones afectadas.',
    );
  }
  if (ratio >= 0.25) {
    return const _AffectedSeverity(
      'media',
      'Revisar el subconjunto afectado antes de seguir cargando trabajo.',
    );
  }
  return const _AffectedSeverity(
    'baja',
    'Resolver las sesiones afectadas sin interrumpir la operacion general.',
  );
}

_DominantState _resolveDominantState(ScanDocumentSessionSummary summary) {
  if (summary.totalSessions <= 0) {
    return const _DominantState(
      'sin datos',
      'No hay suficiente informacion para priorizar por estado.',
    );
  }
  final entries = <MapEntry<String, int>>[
    MapEntry('running', summary.runningSessions),
    MapEntry('completed', summary.completedSessions),
    MapEntry('error', summary.errorSessions),
  ];
  entries.sort((left, right) => right.value.compareTo(left.value));
  final top = entries.first;
  if (top.value <= 0) {
    return const _DominantState(
      'sin estado dominante',
      'No hay estados operativos con volumen relevante.',
    );
  }
  final tiedStates = entries
      .where((entry) => entry.value == top.value)
      .toList(growable: false);
  if (tiedStates.length > 1) {
    final labels = tiedStates.map((entry) => entry.key).join(' / ');
    return _DominantState(
      'equilibrado entre $labels (${top.value})',
      'Conviene revisar varios frentes antes de decidir una accion masiva.',
    );
  }
  return switch (top.key) {
    'running' => _DominantState(
      '${top.key} (${top.value})',
      'La mayor carga sigue activa; evitar descartes amplios.',
    ),
    'completed' => _DominantState(
      '${top.key} (${top.value})',
      'Hay margen para limpieza o exportacion del subconjunto visible.',
    ),
    'error' => _DominantState(
      '${top.key} (${top.value})',
      'Conviene abrir o descartar errores antes de seguir operando.',
    ),
    _ => _DominantState(
      '${top.key} (${top.value})',
      'Revisar el estado principal antes de aplicar acciones masivas.',
    ),
  };
}

_OperationalRisk _resolveOperationalRisk({
  required _AffectedSeverity severity,
  required _DominantState dominantState,
}) {
  if (severity.label == 'alta') {
    return const _OperationalRisk(
      'alto',
      backgroundColor: Colors.red,
      foregroundColor: Colors.red,
    );
  }
  if (severity.label == 'media' &&
      dominantState.label.contains('equilibrado entre')) {
    return const _OperationalRisk(
      'alto',
      backgroundColor: Colors.red,
      foregroundColor: Colors.red,
    );
  }
  if (severity.label == 'media' || severity.label == 'baja') {
    return const _OperationalRisk(
      'medio',
      backgroundColor: Colors.orange,
      foregroundColor: Colors.orange,
    );
  }
  return const _OperationalRisk(
    'bajo',
    backgroundColor: Colors.green,
    foregroundColor: Colors.green,
  );
}

class _ScanDocumentSessionHealth {
  const _ScanDocumentSessionHealth({
    required this.label,
    required this.badgeLabel,
    required this.description,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.affectedSessions,
    required this.focus,
  });

  final String label;
  final String badgeLabel;
  final String description;
  final Color backgroundColor;
  final Color foregroundColor;
  final int Function(ScanDocumentSessionSummary summary) affectedSessions;
  final String? Function(ScanDocumentSessionSummary summary) focus;
}

class _AffectedSeverity {
  const _AffectedSeverity(this.label, this.recommendation);
  final String label;
  final String recommendation;
}

class _DominantState {
  const _DominantState(this.label, this.recommendation);
  final String label;
  final String recommendation;
}

class _OperationalRisk {
  const _OperationalRisk(
    this.label, {
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}
