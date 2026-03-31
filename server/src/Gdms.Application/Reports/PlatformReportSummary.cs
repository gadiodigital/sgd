namespace Gdms.Application.Reports;

/// <summary>
/// Represents a platform-wide operational summary for platform administrators.
/// </summary>
public sealed record PlatformReportSummary(
    int TotalTenants,
    int TotalDocuments,
    int OpenWorkflowTasks,
    int PendingSignatures,
    int CancelledSignatures,
    int FailedLoginsLast24Hours);
