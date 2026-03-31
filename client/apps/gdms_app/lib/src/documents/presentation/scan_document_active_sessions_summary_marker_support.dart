String formatActivityRange(Duration duration) {
  final totalMinutes = duration.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours <= 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

String formatAveragePages(int totalPages, int totalSessions) {
  if (totalSessions <= 0) return '0.0';
  return (totalPages / totalSessions).toStringAsFixed(1);
}

String sourceMixLabel(int adfSessions, int flatbedSessions) {
  if (adfSessions > 0 && flatbedSessions > 0) return 'ORIGEN MIXTO';
  if (adfSessions > 0) return 'ORIGEN ADF';
  if (flatbedSessions > 0) return 'ORIGEN FLATBED';
  return 'ORIGEN SIN DATO';
}

String sourceMixTooltip(int adfSessions, int flatbedSessions) {
  if (adfSessions > 0 && flatbedSessions > 0) {
    return '$adfSessions ADF y $flatbedSessions cama plana';
  }
  if (adfSessions > 0) return 'Solo ADF';
  if (flatbedSessions > 0) return 'Solo cama plana';
  return 'Sin origen operativo visible';
}

String volumeLabel(int totalPages) {
  if (totalPages >= 20) return 'VOLUMEN ALTO';
  if (totalPages >= 8) return 'VOLUMEN MEDIO';
  return 'VOLUMEN BAJO';
}

String volumeTooltip(int totalPages) {
  if (totalPages >= 20) return 'Lote pesado de $totalPages paginas';
  if (totalPages >= 8) return 'Lote medio de $totalPages paginas';
  return 'Lote liviano de $totalPages paginas';
}

String attentionDensityLabel(int attentionSessions, int totalSessions) {
  if (totalSessions <= 0 || attentionSessions <= 0) return 'ATENCION BAJA';
  final ratio = attentionSessions / totalSessions;
  if (ratio >= 0.5) return 'ATENCION ALTA';
  if (ratio >= 0.25) return 'ATENCION MEDIA';
  return 'ATENCION BAJA';
}

String attentionDensityTooltip(int attentionSessions, int totalSessions) {
  if (totalSessions <= 0 || attentionSessions <= 0) {
    return 'Subconjunto con poca o ninguna presion operativa';
  }
  final ratio = attentionSessions / totalSessions;
  if (ratio >= 0.5) {
    return '$attentionSessions de $totalSessions sesiones requieren atencion';
  }
  if (ratio >= 0.25) {
    return '$attentionSessions de $totalSessions sesiones requieren seguimiento';
  }
  return '$attentionSessions de $totalSessions sesiones con seguimiento puntual';
}

String runningDensityLabel(int runningSessions, int totalSessions) {
  if (totalSessions <= 0 || runningSessions <= 0) return 'EJECUCION BAJA';
  final ratio = runningSessions / totalSessions;
  if (ratio >= 0.5) return 'EJECUCION ALTA';
  if (ratio >= 0.25) return 'EJECUCION MEDIA';
  return 'EJECUCION BAJA';
}

String runningDensityTooltip(int runningSessions, int totalSessions) {
  if (totalSessions <= 0 || runningSessions <= 0) {
    return 'Pocas o ninguna sesion activa en este lote';
  }
  final ratio = runningSessions / totalSessions;
  if (ratio >= 0.5) {
    return '$runningSessions de $totalSessions sesiones siguen en ejecucion';
  }
  if (ratio >= 0.25) {
    return '$runningSessions de $totalSessions sesiones mantienen carga activa';
  }
  return '$runningSessions de $totalSessions sesiones activas';
}

String completionDensityLabel(int completedSessions, int totalSessions) {
  if (totalSessions <= 0 || completedSessions <= 0) return 'CIERRE BAJO';
  final ratio = completedSessions / totalSessions;
  if (ratio >= 0.6) return 'CIERRE ALTO';
  if (ratio >= 0.3) return 'CIERRE MEDIO';
  return 'CIERRE BAJO';
}

String completionDensityTooltip(int completedSessions, int totalSessions) {
  if (totalSessions <= 0 || completedSessions <= 0) {
    return 'Pocas o ninguna sesion finalizada en este lote';
  }
  final ratio = completedSessions / totalSessions;
  if (ratio >= 0.6) {
    return '$completedSessions de $totalSessions sesiones ya quedaron finalizadas';
  }
  if (ratio >= 0.3) {
    return '$completedSessions de $totalSessions sesiones ya permiten cierre parcial';
  }
  return '$completedSessions de $totalSessions sesiones finalizadas';
}

String errorDensityLabel(int errorSessions, int totalSessions) {
  if (totalSessions <= 0 || errorSessions <= 0) return 'FALLA BAJA';
  final ratio = errorSessions / totalSessions;
  if (ratio >= 0.4) return 'FALLA ALTA';
  if (ratio >= 0.2) return 'FALLA MEDIA';
  return 'FALLA BAJA';
}

String errorDensityTooltip(int errorSessions, int totalSessions) {
  if (totalSessions <= 0 || errorSessions <= 0) {
    return 'Pocas o ninguna sesion con error en este lote';
  }
  final ratio = errorSessions / totalSessions;
  if (ratio >= 0.4) {
    return '$errorSessions de $totalSessions sesiones quedaron en error';
  }
  if (ratio >= 0.2) {
    return '$errorSessions de $totalSessions sesiones requieren revision por falla';
  }
  return '$errorSessions de $totalSessions sesiones con error puntual';
}

String rehydrationDensityLabel(int rehydratedSessions, int totalSessions) {
  if (totalSessions <= 0 || rehydratedSessions <= 0) {
    return 'REHIDRATACION BAJA';
  }
  final ratio = rehydratedSessions / totalSessions;
  if (ratio >= 0.4) return 'REHIDRATACION ALTA';
  if (ratio >= 0.2) return 'REHIDRATACION MEDIA';
  return 'REHIDRATACION BAJA';
}

String rehydrationDensityTooltip(int rehydratedSessions, int totalSessions) {
  if (totalSessions <= 0 || rehydratedSessions <= 0) {
    return 'Pocas o ninguna sesion rehidratada en este lote';
  }
  final ratio = rehydratedSessions / totalSessions;
  if (ratio >= 0.4) {
    return '$rehydratedSessions de $totalSessions sesiones dependen de rehidratacion';
  }
  if (ratio >= 0.2) {
    return '$rehydratedSessions de $totalSessions sesiones recuperadas requieren seguimiento';
  }
  return '$rehydratedSessions de $totalSessions sesiones rehidratadas';
}

String staleDensityLabel(int staleSessions, int totalSessions) {
  if (totalSessions <= 0 || staleSessions <= 0) return 'INACTIVIDAD BAJA';
  final ratio = staleSessions / totalSessions;
  if (ratio >= 0.4) return 'INACTIVIDAD ALTA';
  if (ratio >= 0.2) return 'INACTIVIDAD MEDIA';
  return 'INACTIVIDAD BAJA';
}

String staleDensityTooltip(int staleSessions, int totalSessions) {
  if (totalSessions <= 0 || staleSessions <= 0) {
    return 'Pocas o ninguna sesion inactiva en este lote';
  }
  final ratio = staleSessions / totalSessions;
  if (ratio >= 0.4) {
    return '$staleSessions de $totalSessions sesiones quedaron inactivas';
  }
  if (ratio >= 0.2) {
    return '$staleSessions de $totalSessions sesiones inactivas requieren seguimiento';
  }
  return '$staleSessions de $totalSessions sesiones inactivas';
}

String stabilityLabel(
  int errorSessions,
  int rehydratedSessions,
  int staleSessions,
  int totalSessions,
) {
  final affected = errorSessions + rehydratedSessions + staleSessions;
  if (totalSessions <= 0 || affected <= 0) return 'ESTABILIDAD ALTA';
  final ratio = affected / totalSessions;
  if (ratio >= 0.5) return 'ESTABILIDAD BAJA';
  if (ratio >= 0.25) return 'ESTABILIDAD MEDIA';
  return 'ESTABILIDAD ALTA';
}

String stabilityTooltip(
  int errorSessions,
  int rehydratedSessions,
  int staleSessions,
  int totalSessions,
) {
  final affected = errorSessions + rehydratedSessions + staleSessions;
  if (totalSessions <= 0 || affected <= 0) {
    return 'Lote estable sin señales relevantes de degradacion';
  }
  if (affected / totalSessions >= 0.5) {
    return '$affected de $totalSessions sesiones muestran degradacion operativa';
  }
  if (affected / totalSessions >= 0.25) {
    return '$affected de $totalSessions sesiones requieren seguimiento de estabilidad';
  }
  return '$affected de $totalSessions sesiones con desvio puntual de estabilidad';
}

String recoverabilityLabel(
  int errorSessions,
  int staleSessions,
  int completedSessions,
  int runningSessions,
) {
  final recoverable = completedSessions + runningSessions;
  final degraded = errorSessions + staleSessions;
  if (recoverable <= 0 && degraded > 0) {
    return 'RECUPERABILIDAD BAJA';
  }
  if (degraded > recoverable) {
    return 'RECUPERABILIDAD BAJA';
  }
  if (degraded == recoverable && degraded > 0) {
    return 'RECUPERABILIDAD MEDIA';
  }
  return 'RECUPERABILIDAD ALTA';
}

String recoverabilityTooltip(
  int errorSessions,
  int staleSessions,
  int completedSessions,
  int runningSessions,
) {
  final recoverable = completedSessions + runningSessions;
  final degraded = errorSessions + staleSessions;
  if (recoverable <= 0 && degraded <= 0) {
    return 'Lote sin señales suficientes para estimar recuperabilidad';
  }
  if (recoverable <= 0 && degraded > 0) {
    return 'Predominan sesiones degradadas sin margen claro de recuperacion';
  }
  if (degraded > recoverable) {
    return '$degraded sesiones degradadas frente a $recoverable recuperables';
  }
  if (degraded == recoverable && degraded > 0) {
    return 'Balanceado entre sesiones degradadas y recuperables';
  }
  return '$recoverable sesiones recuperables frente a $degraded degradadas';
}
