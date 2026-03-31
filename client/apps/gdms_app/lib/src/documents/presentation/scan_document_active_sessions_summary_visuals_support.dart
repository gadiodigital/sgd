import 'package:flutter/material.dart';

({Color background, Color foreground}) severityColors(String label) =>
    switch (label) {
      'alta' => (background: Colors.red, foreground: Colors.red),
      'media' => (background: Colors.orange, foreground: Colors.orange),
      'baja' => (background: Colors.amber, foreground: Colors.orange),
      _ => (background: Colors.green, foreground: Colors.green),
    };

String dominantStateChipLabel(String label) =>
    label.startsWith('equilibrado entre')
    ? 'EQUILIBRADO'
    : label.startsWith('sin estado dominante')
    ? 'SIN ESTADO'
    : label.startsWith('sin datos')
    ? 'SIN DATOS'
    : label.startsWith('running')
    ? 'RUNNING'
    : label.startsWith('completed')
    ? 'COMPLETED'
    : label.startsWith('error')
    ? 'ERROR'
    : 'MIXTO';

({Color background, Color foreground}) dominantStateColors(String label) =>
    label.startsWith('error')
    ? (background: Colors.red, foreground: Colors.red)
    : label.startsWith('running')
    ? (background: Colors.blue, foreground: Colors.blue)
    : label.startsWith('completed')
    ? (background: Colors.green, foreground: Colors.green)
    : label.startsWith('equilibrado entre')
    ? (background: Colors.deepPurple, foreground: Colors.deepPurple)
    : (background: Colors.blueGrey, foreground: Colors.blueGrey);

Wrap summarySignalRow(
  ThemeData theme, {
  required String text,
  required String chipLabel,
  required String tooltip,
  required Color backgroundColor,
  required Color foregroundColor,
}) => Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    Text(text),
    summaryChip(
      theme,
      label: chipLabel,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    ),
  ],
);

Widget summaryChip(
  ThemeData theme, {
  required String label,
  String? tooltip,
  required Color backgroundColor,
  required Color foregroundColor,
}) => Tooltip(
  message: tooltip ?? label,
  child: Chip(
    label: Text(label),
    backgroundColor: backgroundColor.withValues(alpha: 0.14),
    side: BorderSide(color: backgroundColor.withValues(alpha: 0.3)),
    labelStyle: theme.textTheme.bodySmall?.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w600,
    ),
    visualDensity: VisualDensity.compact,
  ),
);
