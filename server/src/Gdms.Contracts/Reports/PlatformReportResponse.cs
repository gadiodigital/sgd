namespace Gdms.Contracts.Reports;

/// <summary>
/// Represents the platform-wide report returned by the reports API.
/// </summary>
public sealed record PlatformReportResponse(
    int TotalTenants,
    int TotalDocuments,
    int OpenWorkflowTasks,
    int PendingSignatures,
    int CancelledSignatures,
    int FailedLoginsLast24Hours);
