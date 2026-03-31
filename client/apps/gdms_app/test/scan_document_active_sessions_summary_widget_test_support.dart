import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_summary_support.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

Future<void> pumpScanSummary(
  WidgetTester tester, {
  required ScanDocumentSessionSummary summary,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: ScanDocumentActiveSessionsSummary(summary: summary),
      ),
    ),
  );
}

ScanDocumentSessionSummary buildScanSummary({
  required int totalSessions,
  required int totalPages,
  required int attentionSessions,
  required int rehydratedSessions,
  required int staleSessions,
  required int completedSessions,
  required int errorSessions,
  required int runningSessions,
  required int uniqueScanners,
  required String primaryScannerLabel,
  required int adfSessions,
  required int flatbedSessions,
  DateTime? mostRecentActivityAtUtc,
  DateTime? oldestActivityAtUtc,
}) {
  return ScanDocumentSessionSummary(
    totalSessions: totalSessions,
    totalPages: totalPages,
    attentionSessions: attentionSessions,
    rehydratedSessions: rehydratedSessions,
    staleSessions: staleSessions,
    completedSessions: completedSessions,
    errorSessions: errorSessions,
    runningSessions: runningSessions,
    uniqueScanners: uniqueScanners,
    primaryScannerLabel: primaryScannerLabel,
    adfSessions: adfSessions,
    flatbedSessions: flatbedSessions,
    mostRecentActivityAtUtc: mostRecentActivityAtUtc,
    oldestActivityAtUtc: oldestActivityAtUtc,
  );
}

void expectSummaryTexts(Iterable<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsOneWidget);
  }
}

void expectSummaryTooltips(Iterable<String> tooltips) {
  for (final tooltip in tooltips) {
    expect(find.byTooltip(tooltip), findsOneWidget);
  }
}

void expectSummaryViewData(
  ScanDocumentActiveSessionsSummaryViewData viewData, {
  String? healthLabel,
  String? healthBadgeLabel,
  String? healthDescription,
  int? affectedSessions,
  String? affectedRatioLabel,
  String? severityLabel,
  String? operationalRiskLabel,
  String? dominantStateLabel,
  String? dominantPatternRecommendation,
  String? nextStepRecommendation,
  Object? focus = _unsetFocus,
}) {
  if (healthLabel != null) {
    expect(viewData.healthLabel, healthLabel);
  }
  if (healthBadgeLabel != null) {
    expect(viewData.healthBadgeLabel, healthBadgeLabel);
  }
  if (healthDescription != null) {
    expect(viewData.healthDescription, healthDescription);
  }
  if (affectedSessions != null) {
    expect(viewData.affectedSessions, affectedSessions);
  }
  if (affectedRatioLabel != null) {
    expect(viewData.affectedRatioLabel, affectedRatioLabel);
  }
  if (severityLabel != null) {
    expect(viewData.severityLabel, severityLabel);
  }
  if (operationalRiskLabel != null) {
    expect(viewData.operationalRiskLabel, operationalRiskLabel);
  }
  if (dominantStateLabel != null) {
    expect(viewData.dominantStateLabel, dominantStateLabel);
  }
  if (dominantPatternRecommendation != null) {
    expect(
      viewData.dominantPatternRecommendation,
      dominantPatternRecommendation,
    );
  }
  if (nextStepRecommendation != null) {
    expect(viewData.nextStepRecommendation, nextStepRecommendation);
  }
  if (!identical(focus, _unsetFocus)) {
    expect(viewData.focus, focus);
  }
}

const Object _unsetFocus = Object();
