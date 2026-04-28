import 'package:core/core.dart';
import 'dart:collection';

import '../domain/operational_report_overview.dart';
import '../domain/reports_repository.dart';

enum ReportsLens { all, compliance, workflow, signatures, security }

enum PlatformReportMetricKind {
  tenants,
  documents,
  openWorkflowTasks,
  pendingSignatures,
  cancelledSignatures,
  failedLoginsLast24Hours,
}

/// Coordinates loading of the operational reports dashboard.
final class ReportsViewModel extends ViewModel {
  ReportsViewModel(this._repository);

  final ReportsRepository _repository;
  OperationalReportOverview? _overview;
  ReportsLens _selectedLens = ReportsLens.all;

  OperationalReportOverview? get overview => _overview;
  ReportsLens get selectedLens => _selectedLens;

  UnmodifiableListView<ReportMetricItem> get visibleOperationalMetrics {
    final overview = _overview;
    if (overview == null) {
      return UnmodifiableListView(const <ReportMetricItem>[]);
    }

    final metrics = <ReportMetricItem>[
      ReportMetricItem(
        label: 'Documentos',
        value: overview.totalDocuments,
        colorHex: 0xFF1565C0,
        lens: ReportsLens.all,
      ),
      ReportMetricItem(
        label: 'Legal holds',
        value: overview.activeLegalHolds,
        colorHex: 0xFFEF6C00,
        lens: ReportsLens.compliance,
      ),
      ReportMetricItem(
        label: 'Workflow abierto',
        value: overview.openWorkflowTasks,
        colorHex: 0xFF5E35B1,
        lens: ReportsLens.workflow,
      ),
      ReportMetricItem(
        label: 'Firmas pendientes',
        value: overview.pendingSignatures,
        colorHex: 0xFF00897B,
        lens: ReportsLens.signatures,
      ),
      ReportMetricItem(
        label: 'Firmas canceladas',
        value: overview.cancelledSignatures,
        colorHex: 0xFF757575,
        lens: ReportsLens.signatures,
      ),
      ReportMetricItem(
        label: 'Disposición pendiente',
        value: overview.pendingDispositionItems,
        colorHex: 0xFFC62828,
        lens: ReportsLens.compliance,
      ),
      ReportMetricItem(
        label: 'Failed logins 24h',
        value: overview.failedLoginsLast24Hours,
        colorHex: 0xFF6D4C41,
        lens: ReportsLens.security,
      ),
    ];

    final filtered = _selectedLens == ReportsLens.all
        ? metrics
        : metrics
              .where((item) => item.lens == _selectedLens)
              .toList(growable: false);
    return UnmodifiableListView(filtered);
  }

  UnmodifiableListView<PlatformReportMetricItem> get visiblePlatformMetrics {
    final platformSummary = _overview?.platformSummary;
    if (platformSummary == null) {
      return UnmodifiableListView(const <PlatformReportMetricItem>[]);
    }

    return UnmodifiableListView([
      PlatformReportMetricItem(
        label: 'Organizaciones',
        value: platformSummary.totalTenants,
        colorHex: 0xFF3949AB,
        kind: PlatformReportMetricKind.tenants,
      ),
      PlatformReportMetricItem(
        label: 'Documentos',
        value: platformSummary.totalDocuments,
        colorHex: 0xFF1565C0,
        kind: PlatformReportMetricKind.documents,
      ),
      PlatformReportMetricItem(
        label: 'Workflow abierto',
        value: platformSummary.openWorkflowTasks,
        colorHex: 0xFF5E35B1,
        kind: PlatformReportMetricKind.openWorkflowTasks,
      ),
      PlatformReportMetricItem(
        label: 'Firmas pendientes',
        value: platformSummary.pendingSignatures,
        colorHex: 0xFF00897B,
        kind: PlatformReportMetricKind.pendingSignatures,
      ),
      PlatformReportMetricItem(
        label: 'Firmas canceladas',
        value: platformSummary.cancelledSignatures,
        colorHex: 0xFF757575,
        kind: PlatformReportMetricKind.cancelledSignatures,
      ),
      PlatformReportMetricItem(
        label: 'Failed logins 24h',
        value: platformSummary.failedLoginsLast24Hours,
        colorHex: 0xFF6D4C41,
        kind: PlatformReportMetricKind.failedLoginsLast24Hours,
      ),
    ]);
  }

  void updateLens(ReportsLens lens) {
    _selectedLens = lens;
    notifyListeners();
  }

  Future<void> load() async {
    await run(() async {
      _overview = await _repository.loadOverview();
      setMessage('Reporte operativo sincronizado.');
    });
  }
}

final class ReportMetricItem {
  const ReportMetricItem({
    required this.label,
    required this.value,
    required this.colorHex,
    required this.lens,
  });

  final String label;
  final int value;
  final int colorHex;
  final ReportsLens lens;
}

final class PlatformReportMetricItem {
  const PlatformReportMetricItem({
    required this.label,
    required this.value,
    required this.colorHex,
    required this.kind,
  });

  final String label;
  final int value;
  final int colorHex;
  final PlatformReportMetricKind kind;
}
