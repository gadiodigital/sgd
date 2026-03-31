String continuityLabel(int runningSessions, int completedSessions) {
  if (runningSessions <= 0 && completedSessions <= 0) {
    return 'CONTINUIDAD SIN DATO';
  }
  if (runningSessions > completedSessions) return 'CONTINUIDAD ACTIVA';
  if (completedSessions > runningSessions) return 'CONTINUIDAD CIERRE';
  return 'CONTINUIDAD MIXTA';
}

String continuityTooltip(int runningSessions, int completedSessions) {
  if (runningSessions <= 0 && completedSessions <= 0) {
    return 'Sin señales suficientes para estimar continuidad operativa';
  }
  if (runningSessions > completedSessions) {
    return '$runningSessions sesiones activas frente a $completedSessions finalizadas';
  }
  if (completedSessions > runningSessions) {
    return '$completedSessions sesiones finalizadas frente a $runningSessions activas';
  }
  return 'Balanceado entre sesiones activas y finalizadas';
}

String pressureLabel(
  int attentionSessions,
  int runningSessions,
  int totalSessions,
) {
  final pressured = attentionSessions + runningSessions;
  if (totalSessions <= 0 || pressured <= 0) return 'PRESION BAJA';
  final ratio = pressured / totalSessions;
  if (ratio >= 0.75) return 'PRESION ALTA';
  if (ratio >= 0.4) return 'PRESION MEDIA';
  return 'PRESION BAJA';
}

String pressureTooltip(
  int attentionSessions,
  int runningSessions,
  int totalSessions,
) {
  final pressured = attentionSessions + runningSessions;
  if (totalSessions <= 0 || pressured <= 0) {
    return 'Lote con baja exigencia operativa visible';
  }
  if (pressured / totalSessions >= 0.75) {
    return '$pressured señales activas o con seguimiento sobre $totalSessions sesiones';
  }
  if (pressured / totalSessions >= 0.4) {
    return '$pressured sesiones sostienen carga visible sobre $totalSessions';
  }
  return '$pressured sesiones con presion puntual sobre $totalSessions';
}

String balanceLabel(int runningSessions, int completedSessions) {
  if (runningSessions <= 0 && completedSessions <= 0) return 'BALANCE SIN DATO';
  if (runningSessions > completedSessions) return 'BALANCE EJECUCION';
  if (completedSessions > runningSessions) return 'BALANCE CIERRE';
  return 'BALANCE MIXTO';
}

String balanceTooltip(int runningSessions, int completedSessions) {
  if (runningSessions <= 0 && completedSessions <= 0) {
    return 'Sin señales suficientes para estimar balance operativo';
  }
  if (runningSessions > completedSessions) {
    return 'Predomina la ejecucion sobre el cierre';
  }
  if (completedSessions > runningSessions) {
    return 'Predomina el cierre sobre la ejecucion';
  }
  return 'Balanceado entre ejecucion y cierre';
}

String maturityLabel(
  int completedSessions,
  int errorSessions,
  int totalSessions,
) {
  final resolved = completedSessions + errorSessions;
  if (totalSessions <= 0 || resolved <= 0) return 'MADUREZ BAJA';
  final ratio = resolved / totalSessions;
  if (ratio >= 0.7) return 'MADUREZ ALTA';
  if (ratio >= 0.35) return 'MADUREZ MEDIA';
  return 'MADUREZ BAJA';
}

String maturityTooltip(
  int completedSessions,
  int errorSessions,
  int totalSessions,
) {
  final resolved = completedSessions + errorSessions;
  if (totalSessions <= 0 || resolved <= 0) {
    return 'Lote todavia temprano, con poca resolucion visible';
  }
  if (resolved / totalSessions >= 0.7) {
    return '$resolved de $totalSessions sesiones ya estan resueltas';
  }
  if (resolved / totalSessions >= 0.35) {
    return '$resolved de $totalSessions sesiones muestran avance de resolucion';
  }
  return '$resolved de $totalSessions sesiones resueltas parcialmente';
}
