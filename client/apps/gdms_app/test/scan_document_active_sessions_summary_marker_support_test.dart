import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_marker_support.dart';

void main() {
  group('base markers', () {
    test('formatea rango de actividad', () {
      expect(formatActivityRange(const Duration(minutes: 45)), '45 min');
      expect(formatActivityRange(const Duration(hours: 2)), '2 h');
      expect(formatActivityRange(const Duration(hours: 1, minutes: 30)), '1 h 30 min');
      expect(formatActivityRange(const Duration(minutes: -30)), '30 min');
    });

    test('formatea promedio de paginas', () {
      expect(formatAveragePages(0, 0), '0.0');
      expect(formatAveragePages(9, 3), '3.0');
      expect(formatAveragePages(7, 2), '3.5');
    });

    test('resuelve mezcla de origen', () {
      expect(sourceMixLabel(2, 1), 'ORIGEN MIXTO');
      expect(sourceMixTooltip(2, 1), '2 ADF y 1 cama plana');
      expect(sourceMixLabel(2, 0), 'ORIGEN ADF');
      expect(sourceMixTooltip(2, 0), 'Solo ADF');
      expect(sourceMixLabel(0, 2), 'ORIGEN FLATBED');
      expect(sourceMixTooltip(0, 2), 'Solo cama plana');
      expect(sourceMixLabel(0, 0), 'ORIGEN SIN DATO');
      expect(sourceMixTooltip(0, 0), 'Sin origen operativo visible');
    });

    test('resuelve volumen documental', () {
      expect(volumeLabel(4), 'VOLUMEN BAJO');
      expect(volumeTooltip(4), 'Lote liviano de 4 paginas');
      expect(volumeLabel(12), 'VOLUMEN MEDIO');
      expect(volumeTooltip(12), 'Lote medio de 12 paginas');
      expect(volumeLabel(24), 'VOLUMEN ALTO');
      expect(volumeTooltip(24), 'Lote pesado de 24 paginas');
    });
  });

  group('attention density', () {
    test('resuelve baja sin sesiones afectadas', () {
      expect(attentionDensityLabel(0, 5), 'ATENCION BAJA');
      expect(
        attentionDensityTooltip(0, 5),
        'Subconjunto con poca o ninguna presion operativa',
      );
    });

    test('resuelve media', () {
      expect(attentionDensityLabel(1, 4), 'ATENCION MEDIA');
      expect(
        attentionDensityTooltip(1, 4),
        '1 de 4 sesiones requieren seguimiento',
      );
    });

    test('resuelve alta', () {
      expect(attentionDensityLabel(3, 4), 'ATENCION ALTA');
      expect(
        attentionDensityTooltip(3, 4),
        '3 de 4 sesiones requieren atencion',
      );
    });
  });

  group('execution density', () {
    test('resuelve baja', () {
      expect(runningDensityLabel(0, 4), 'EJECUCION BAJA');
      expect(
        runningDensityTooltip(0, 4),
        'Pocas o ninguna sesion activa en este lote',
      );
    });

    test('resuelve media', () {
      expect(runningDensityLabel(1, 3), 'EJECUCION MEDIA');
      expect(
        runningDensityTooltip(1, 3),
        '1 de 3 sesiones mantienen carga activa',
      );
    });

    test('resuelve alta', () {
      expect(runningDensityLabel(2, 3), 'EJECUCION ALTA');
      expect(
        runningDensityTooltip(2, 3),
        '2 de 3 sesiones siguen en ejecucion',
      );
    });
  });

  group('closure density', () {
    test('resuelve baja', () {
      expect(completionDensityLabel(0, 4), 'CIERRE BAJO');
      expect(
        completionDensityTooltip(0, 4),
        'Pocas o ninguna sesion finalizada en este lote',
      );
    });

    test('resuelve media', () {
      expect(completionDensityLabel(1, 3), 'CIERRE MEDIO');
      expect(
        completionDensityTooltip(1, 3),
        '1 de 3 sesiones ya permiten cierre parcial',
      );
    });

    test('resuelve alta', () {
      expect(completionDensityLabel(3, 4), 'CIERRE ALTO');
      expect(
        completionDensityTooltip(3, 4),
        '3 de 4 sesiones ya quedaron finalizadas',
      );
    });
  });

  group('failure density', () {
    test('resuelve baja', () {
      expect(errorDensityLabel(0, 4), 'FALLA BAJA');
      expect(
        errorDensityTooltip(0, 4),
        'Pocas o ninguna sesion con error en este lote',
      );
    });

    test('resuelve media', () {
      expect(errorDensityLabel(1, 4), 'FALLA MEDIA');
      expect(
        errorDensityTooltip(1, 4),
        '1 de 4 sesiones requieren revision por falla',
      );
    });

    test('resuelve alta', () {
      expect(errorDensityLabel(2, 4), 'FALLA ALTA');
      expect(errorDensityTooltip(2, 4), '2 de 4 sesiones quedaron en error');
    });
  });

  group('rehydration density', () {
    test('resuelve baja', () {
      expect(rehydrationDensityLabel(0, 4), 'REHIDRATACION BAJA');
      expect(
        rehydrationDensityTooltip(0, 4),
        'Pocas o ninguna sesion rehidratada en este lote',
      );
    });

    test('resuelve media', () {
      expect(rehydrationDensityLabel(1, 4), 'REHIDRATACION MEDIA');
      expect(
        rehydrationDensityTooltip(1, 4),
        '1 de 4 sesiones recuperadas requieren seguimiento',
      );
    });

    test('resuelve alta', () {
      expect(rehydrationDensityLabel(2, 4), 'REHIDRATACION ALTA');
      expect(
        rehydrationDensityTooltip(2, 4),
        '2 de 4 sesiones dependen de rehidratacion',
      );
    });
  });

  group('stale density', () {
    test('resuelve baja', () {
      expect(staleDensityLabel(0, 4), 'INACTIVIDAD BAJA');
      expect(
        staleDensityTooltip(0, 4),
        'Pocas o ninguna sesion inactiva en este lote',
      );
    });

    test('resuelve media', () {
      expect(staleDensityLabel(1, 4), 'INACTIVIDAD MEDIA');
      expect(
        staleDensityTooltip(1, 4),
        '1 de 4 sesiones inactivas requieren seguimiento',
      );
    });

    test('resuelve alta', () {
      expect(staleDensityLabel(2, 4), 'INACTIVIDAD ALTA');
      expect(staleDensityTooltip(2, 4), '2 de 4 sesiones quedaron inactivas');
    });
  });

  group('stability', () {
    test('resuelve estabilidad alta', () {
      expect(stabilityLabel(0, 0, 0, 4), 'ESTABILIDAD ALTA');
      expect(
        stabilityTooltip(0, 0, 0, 4),
        'Lote estable sin señales relevantes de degradacion',
      );
    });

    test('resuelve estabilidad media', () {
      expect(stabilityLabel(0, 1, 0, 4), 'ESTABILIDAD MEDIA');
      expect(
        stabilityTooltip(0, 1, 0, 4),
        '1 de 4 sesiones requieren seguimiento de estabilidad',
      );
    });

    test('resuelve estabilidad baja', () {
      expect(stabilityLabel(1, 1, 0, 3), 'ESTABILIDAD BAJA');
      expect(
        stabilityTooltip(1, 1, 0, 3),
        '2 de 3 sesiones muestran degradacion operativa',
      );
    });
  });

  group('recoverability', () {
    test('resuelve recuperabilidad alta', () {
      expect(recoverabilityLabel(0, 0, 2, 1), 'RECUPERABILIDAD ALTA');
      expect(
        recoverabilityTooltip(0, 0, 2, 1),
        '3 sesiones recuperables frente a 0 degradadas',
      );
    });

    test('resuelve recuperabilidad media en equilibrio', () {
      expect(recoverabilityLabel(1, 1, 1, 1), 'RECUPERABILIDAD MEDIA');
      expect(
        recoverabilityTooltip(1, 1, 1, 1),
        'Balanceado entre sesiones degradadas y recuperables',
      );
    });

    test('resuelve recuperabilidad baja cuando predominan degradadas', () {
      expect(recoverabilityLabel(2, 1, 1, 0), 'RECUPERABILIDAD BAJA');
      expect(
        recoverabilityTooltip(2, 1, 1, 0),
        '3 sesiones degradadas frente a 1 recuperables',
      );
    });

    test('resuelve recuperabilidad baja sin margen recuperable', () {
      expect(recoverabilityLabel(2, 1, 0, 0), 'RECUPERABILIDAD BAJA');
      expect(
        recoverabilityTooltip(2, 1, 0, 0),
        'Predominan sesiones degradadas sin margen claro de recuperacion',
      );
    });

    test('resuelve recuperabilidad sin señales suficientes', () {
      expect(recoverabilityLabel(0, 0, 0, 0), 'RECUPERABILIDAD ALTA');
      expect(
        recoverabilityTooltip(0, 0, 0, 0),
        'Lote sin señales suficientes para estimar recuperabilidad',
      );
    });
  });
}
