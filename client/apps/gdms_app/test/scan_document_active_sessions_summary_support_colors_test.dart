import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_support.dart';

import 'scan_document_active_sessions_summary_widget_test_support.dart';

void main() {
  test('expone colores de salud coherentes para lote limpio', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 2,
        totalPages: 5,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 1,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner O',
        adfSessions: 2,
        flatbedSessions: 0,
      ),
    );

    expect(viewData.healthBackgroundColor, Colors.green);
    expect(viewData.healthForegroundColor, Colors.green);
  });

  test('expone colores de salud coherentes para sin sesiones', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 0,
        totalPages: 0,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 0,
        errorSessions: 0,
        runningSessions: 0,
        uniqueScanners: 0,
        primaryScannerLabel: 'sin dato',
        adfSessions: 0,
        flatbedSessions: 0,
      ),
    );

    expect(viewData.healthBackgroundColor, Colors.blueGrey);
    expect(viewData.healthForegroundColor, Colors.blueGrey);
  });

  test('expone colores de salud coherentes para seguimiento', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 6,
        attentionSessions: 1,
        rehydratedSessions: 1,
        staleSessions: 0,
        completedSessions: 2,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner Q',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expect(viewData.healthBackgroundColor, Colors.orange);
    expect(viewData.healthForegroundColor, Colors.orange);
  });

  test('expone colores de salud coherentes para incidencias', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 7,
        attentionSessions: 2,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 1,
        errorSessions: 1,
        runningSessions: 2,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner T',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expect(viewData.healthBackgroundColor, Colors.red);
    expect(viewData.healthForegroundColor, Colors.red);
  });

  test('expone colores de riesgo coherentes para riesgo alto', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 4,
        totalPages: 8,
        attentionSessions: 2,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 2,
        errorSessions: 0,
        runningSessions: 2,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner P',
        adfSessions: 4,
        flatbedSessions: 0,
      ),
    );

    expect(viewData.operationalRiskLabel, 'alto');
    expect(viewData.operationalRiskBackgroundColor, Colors.red);
    expect(viewData.operationalRiskForegroundColor, Colors.red);
  });

  test('expone colores de riesgo coherentes para riesgo medio', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 8,
        totalPages: 16,
        attentionSessions: 2,
        rehydratedSessions: 1,
        staleSessions: 1,
        completedSessions: 5,
        errorSessions: 0,
        runningSessions: 3,
        uniqueScanners: 2,
        primaryScannerLabel: 'Scanner R',
        adfSessions: 6,
        flatbedSessions: 2,
      ),
    );

    expect(viewData.operationalRiskLabel, 'medio');
    expect(viewData.operationalRiskBackgroundColor, Colors.orange);
    expect(viewData.operationalRiskForegroundColor, Colors.orange);
  });

  test('expone colores de riesgo coherentes para riesgo bajo', () {
    final viewData = ScanDocumentActiveSessionsSummarySupport.resolve(
      buildScanSummary(
        totalSessions: 3,
        totalPages: 7,
        attentionSessions: 0,
        rehydratedSessions: 0,
        staleSessions: 0,
        completedSessions: 2,
        errorSessions: 0,
        runningSessions: 1,
        uniqueScanners: 1,
        primaryScannerLabel: 'Scanner S',
        adfSessions: 3,
        flatbedSessions: 0,
      ),
    );

    expect(viewData.operationalRiskLabel, 'bajo');
    expect(viewData.operationalRiskBackgroundColor, Colors.green);
    expect(viewData.operationalRiskForegroundColor, Colors.green);
  });
}
