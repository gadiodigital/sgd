import 'document_scan_preset.dart';
import 'document_scan_view_model.dart';
import '../domain/scan_source.dart';

extension DocumentScanViewModelCapabilities on DocumentScanViewModel {
  bool get canScanSimplex => supportsOperation('scan-adf-simplex');
  bool get canScanDuplex => supportsOperation('scan-adf-duplex');
  bool get canScanFlatbed => supportsOperation('scan-flatbed-single');
  bool get canUseAdf => canScanSimplex || canScanDuplex;
  bool get canScan =>
      !isBusy &&
      serviceAvailable &&
      selectedScanner != null &&
      switch (source) {
        ScanSource.adf => duplex ? canScanDuplex : canScanSimplex,
        ScanSource.flatbed => canScanFlatbed,
      };
  bool get canShowPreviousPage => currentPreviewPage > 1;
  bool get canShowNextPage =>
      lastScannedFile != null &&
      currentPreviewPage < lastScannedFile!.pageCount;
  bool get canDeleteCurrentPage =>
      supportsOperation('delete-page') &&
      lastScannedFile != null &&
      lastScannedFile!.pageCount > 0;
  bool get canMoveCurrentPageBackward =>
      supportsOperation('move-page') && canShowPreviousPage;
  bool get canMoveCurrentPageForward =>
      supportsOperation('move-page') && canShowNextPage;
  bool get canRotateCurrentPage =>
      supportsOperation('rotate-page') && lastScannedFile != null;
  bool get canAdjustCurrentPage =>
      supportsOperation('adjust-page') && lastScannedFile != null;
  bool get canMergeScans =>
      supportsOperation('merge-session') && lastScannedFile != null && canScan;
  bool get canRefreshSessionDetails =>
      supportsOperation('get-session') && lastScannedFile != null;
  bool get canResumeLastSession =>
      !isBusy &&
      lastScannedFile == null &&
      serviceAvailable &&
      supportsOperation('get-session') &&
      lastKnownSessionId != null &&
      lastKnownSessionId!.trim().isNotEmpty;
  bool canApplyPreset(DocumentScanPreset preset) =>
      preset.duplex ? canScanDuplex : canScanSimplex;
  bool supportsOperation(String operationId) =>
      serviceStatus == null ||
      serviceStatus!.operations.isEmpty ||
      serviceStatus!.supportsOperation(operationId);
}
