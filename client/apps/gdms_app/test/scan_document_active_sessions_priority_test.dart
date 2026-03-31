import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_priority.dart';

import 'scan_document_active_sessions_test_support.dart';

void main() {
  test('devuelve null cuando ninguna sesion requiere atencion', () {
    final sessions = [
      buildActiveScanSession(
        sessionId: 's-1',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 3),
      ),
      buildActiveScanSession(
        sessionId: 's-2',
        scannerName: 'Canon',
        mode: 'flatbed-single',
        status: 'completed',
        pageCount: 1,
        touchedAgo: const Duration(minutes: 4),
      ),
    ];

    expect(resolvePrioritySessionId(sessions), isNull);
  });

  test('prioriza la primera sesion rehidratada visible', () {
    final sessions = [
      buildActiveScanSession(
        sessionId: 's-1',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 3),
      ),
      buildActiveScanSession(
        sessionId: 's-2',
        scannerName: 'Epson',
        mode: 'flatbed-single',
        status: 'completed',
        pageCount: 1,
        touchedAgo: const Duration(minutes: 8),
        isRehydrated: true,
      ),
      buildActiveScanSession(
        sessionId: 's-3',
        scannerName: 'Canon',
        mode: 'adf-duplex',
        status: 'error',
        pageCount: 9,
        touchedAgo: const Duration(hours: 3),
      ),
    ];

    expect(resolvePrioritySessionId(sessions), 's-2');
  });

  test('prioriza la primera sesion inactiva visible aunque no tenga error', () {
    final sessions = [
      buildActiveScanSession(
        sessionId: 's-1',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'completed',
        pageCount: 2,
        touchedAgo: const Duration(hours: 2),
      ),
      buildActiveScanSession(
        sessionId: 's-2',
        scannerName: 'Canon',
        mode: 'adf-duplex',
        status: 'error',
        pageCount: 6,
        touchedAgo: const Duration(hours: 3),
      ),
    ];

    expect(resolvePrioritySessionId(sessions), 's-1');
  });

  test(
    'omite sesiones solo dormidas y usa el primer elemento con atencion real segun el orden visible',
    () {
      final sessions = [
        buildActiveScanSession(
          sessionId: 's-1',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 2),
      ),
      buildActiveScanSession(
        sessionId: 's-2',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 20),
      ),
      buildActiveScanSession(
        sessionId: 's-3',
        scannerName: 'Canon',
        mode: 'adf-duplex',
        status: 'error',
        pageCount: 7,
        touchedAgo: const Duration(hours: 1),
        ),
      ];

      expect(resolvePrioritySessionId(sessions), 's-3');
    },
  );
}
