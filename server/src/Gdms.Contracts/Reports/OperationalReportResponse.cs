namespace Gdms.Contracts.Reports;

/// <summary>
/// Represents the operational summary returned by the reports API.
/// </summary>
public sealed record OperationalReportResponse(
    int TotalDocuments,
    int ActiveLegalHolds,
    int OpenWorkflowTasks,
    int PendingSignatures,
    int CancelledSignatures,
    int PendingDispositionItems,
    int FailedLoginsLast24Hours);
