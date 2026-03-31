/// Represents one record pending retention or disposition action.
final class DispositionItem {
  const DispositionItem({
    required this.documentId,
    required this.documentTitle,
    required this.actionCode,
    required this.actionLabel,
    required this.dueDateLabel,
    required this.hasLegalHold,
  });

  final String documentId;
  final String documentTitle;
  final String actionCode;
  final String actionLabel;
  final String dueDateLabel;
  final bool hasLegalHold;

  bool get canExecute => !hasLegalHold && actionCode != 'REVIEW';
}

/// Summarizes records management workload and due actions.
final class RecordsOverview {
  const RecordsOverview({
    required this.policiesInUse,
    required this.legalHoldsActive,
    required this.dueThisWeek,
    required this.pendingReview,
    required this.dispositionQueue,
  });

  final int policiesInUse;
  final int legalHoldsActive;
  final int dueThisWeek;
  final int pendingReview;
  final List<DispositionItem> dispositionQueue;
}
