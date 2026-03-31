namespace Gdms.Application.Reports;

/// <summary>
/// Represents the operational summary exposed by the reports module.
/// </summary>
public sealed record OperationalReportSummary(
    int TotalDocuments,
    int ActiveLegalHolds,
    int OpenWorkflowTasks,
    int PendingSignatures,
    int CancelledSignatures,
    int PendingDispositionItems,
    int FailedLoginsLast24Hours);
