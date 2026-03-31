import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_visuals_support.dart';

void main() {
  group('severityColors', () {
    test('resuelve alta', () {
      final value = severityColors('alta');
      expect(value.background, Colors.red);
      expect(value.foreground, Colors.red);
    });

    test('resuelve media', () {
      final value = severityColors('media');
      expect(value.background, Colors.orange);
      expect(value.foreground, Colors.orange);
    });

    test('resuelve baja', () {
      final value = severityColors('baja');
      expect(value.background, Colors.amber);
      expect(value.foreground, Colors.orange);
    });

    test('resuelve default', () {
      final value = severityColors('nula');
      expect(value.background, Colors.green);
      expect(value.foreground, Colors.green);
    });

    test('resuelve fallback para severidad desconocida', () {
      final value = severityColors('otra');
      expect(value.background, Colors.green);
      expect(value.foreground, Colors.green);
    });
  });

  group('dominantStateChipLabel', () {
    test('resuelve equilibrado', () {
      expect(
        dominantStateChipLabel('equilibrado entre running / error (2)'),
        'EQUILIBRADO',
      );
    });

    test('resuelve sin estado', () {
      expect(dominantStateChipLabel('sin estado dominante'), 'SIN ESTADO');
    });

    test('resuelve sin datos', () {
      expect(dominantStateChipLabel('sin datos'), 'SIN DATOS');
    });

    test('resuelve running', () {
      expect(dominantStateChipLabel('running (4)'), 'RUNNING');
    });

    test('resuelve completed', () {
      expect(dominantStateChipLabel('completed (3)'), 'COMPLETED');
    });

    test('resuelve completed por prefijo extendido', () {
      expect(dominantStateChipLabel('completed tardio (3)'), 'COMPLETED');
    });

    test('resuelve error', () {
      expect(dominantStateChipLabel('error (2)'), 'ERROR');
    });

    test('resuelve mixto por fallback', () {
      expect(dominantStateChipLabel('otro estado'), 'MIXTO');
    });
  });

  group('dominantStateColors', () {
    test('resuelve error', () {
      final value = dominantStateColors('error (2)');
      expect(value.background, Colors.red);
      expect(value.foreground, Colors.red);
    });

    test('resuelve running', () {
      final value = dominantStateColors('running (2)');
      expect(value.background, Colors.blue);
      expect(value.foreground, Colors.blue);
    });

    test('resuelve completed', () {
      final value = dominantStateColors('completed (2)');
      expect(value.background, Colors.green);
      expect(value.foreground, Colors.green);
    });

    test('resuelve equilibrado', () {
      final value = dominantStateColors(
        'equilibrado entre running / completed (2)',
      );
      expect(value.background, Colors.deepPurple);
      expect(value.foreground, Colors.deepPurple);
    });

    test('resuelve sin datos con fallback neutro', () {
      final value = dominantStateColors('sin datos');
      expect(value.background, Colors.blueGrey);
      expect(value.foreground, Colors.blueGrey);
    });

    test('resuelve fallback', () {
      final value = dominantStateColors('sin estado dominante');
      expect(value.background, Colors.blueGrey);
      expect(value.foreground, Colors.blueGrey);
    });
  });
}
