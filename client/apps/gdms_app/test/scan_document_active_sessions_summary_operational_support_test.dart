import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_operational_support.dart';

void main() {
  group('continuity', () {
    test('resuelve continuidad sin dato', () {
      expect(continuityLabel(0, 0), 'CONTINUIDAD SIN DATO');
      expect(
        continuityTooltip(0, 0),
        'Sin señales suficientes para estimar continuidad operativa',
      );
    });

    test('resuelve continuidad activa', () {
      expect(continuityLabel(3, 1), 'CONTINUIDAD ACTIVA');
      expect(
        continuityTooltip(3, 1),
        '3 sesiones activas frente a 1 finalizadas',
      );
    });

    test('resuelve continuidad cierre', () {
      expect(continuityLabel(1, 4), 'CONTINUIDAD CIERRE');
      expect(
        continuityTooltip(1, 4),
        '4 sesiones finalizadas frente a 1 activas',
      );
    });

    test('resuelve continuidad mixta', () {
      expect(continuityLabel(2, 2), 'CONTINUIDAD MIXTA');
      expect(
        continuityTooltip(2, 2),
        'Balanceado entre sesiones activas y finalizadas',
      );
    });
  });

  group('pressure', () {
    test('resuelve presion baja con total invalido', () {
      expect(pressureLabel(2, 1, 0), 'PRESION BAJA');
      expect(
        pressureTooltip(2, 1, 0),
        'Lote con baja exigencia operativa visible',
      );
    });

    test('resuelve presion baja sin carga', () {
      expect(pressureLabel(0, 0, 5), 'PRESION BAJA');
      expect(
        pressureTooltip(0, 0, 5),
        'Lote con baja exigencia operativa visible',
      );
    });

    test('resuelve presion baja puntual', () {
      expect(pressureLabel(0, 1, 3), 'PRESION BAJA');
      expect(
        pressureTooltip(0, 1, 3),
        '1 sesiones con presion puntual sobre 3',
      );
    });

    test('resuelve presion media', () {
      expect(pressureLabel(1, 1, 4), 'PRESION MEDIA');
      expect(
        pressureTooltip(1, 1, 4),
        '2 sesiones sostienen carga visible sobre 4',
      );
    });

    test('resuelve presion alta', () {
      expect(pressureLabel(3, 2, 5), 'PRESION ALTA');
      expect(
        pressureTooltip(3, 2, 5),
        '5 señales activas o con seguimiento sobre 5 sesiones',
      );
    });
  });

  group('balance', () {
    test('resuelve balance sin dato', () {
      expect(balanceLabel(0, 0), 'BALANCE SIN DATO');
      expect(
        balanceTooltip(0, 0),
        'Sin señales suficientes para estimar balance operativo',
      );
    });

    test('resuelve balance ejecucion', () {
      expect(balanceLabel(4, 1), 'BALANCE EJECUCION');
      expect(balanceTooltip(4, 1), 'Predomina la ejecucion sobre el cierre');
    });

    test('resuelve balance cierre', () {
      expect(balanceLabel(1, 4), 'BALANCE CIERRE');
      expect(balanceTooltip(1, 4), 'Predomina el cierre sobre la ejecucion');
    });

    test('resuelve balance mixto', () {
      expect(balanceLabel(2, 2), 'BALANCE MIXTO');
      expect(balanceTooltip(2, 2), 'Balanceado entre ejecucion y cierre');
    });
  });

  group('maturity', () {
    test('resuelve madurez baja parcial', () {
      expect(maturityLabel(1, 0, 4), 'MADUREZ BAJA');
      expect(
        maturityTooltip(1, 0, 4),
        '1 de 4 sesiones resueltas parcialmente',
      );
    });

    test('resuelve madurez baja', () {
      expect(maturityLabel(0, 0, 4), 'MADUREZ BAJA');
      expect(
        maturityTooltip(0, 0, 4),
        'Lote todavia temprano, con poca resolucion visible',
      );
    });

    test('resuelve madurez media', () {
      expect(maturityLabel(2, 0, 4), 'MADUREZ MEDIA');
      expect(
        maturityTooltip(2, 0, 4),
        '2 de 4 sesiones muestran avance de resolucion',
      );
    });

    test('resuelve madurez alta', () {
      expect(maturityLabel(3, 1, 5), 'MADUREZ ALTA');
      expect(maturityTooltip(3, 1, 5), '4 de 5 sesiones ya estan resueltas');
    });
  });
}
