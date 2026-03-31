namespace Gdms.Application.Evidence;

/// <summary>
/// Represents the exported evidence package of one document.
/// </summary>
public sealed record DocumentEvidencePackage(
    Guid TenantId,
    Guid DocumentId,
    string DocumentTypeCode,
    string Title,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset ExportedAtUtc,
    IReadOnlyCollection<DocumentEvidenceVersion> Versions,
    IReadOnlyDictionary<string, object?> Metadata,
    IReadOnlyCollection<DocumentEvidenceAuditEvent> AuditEvents,
    IReadOnlyCollection<DocumentEvidenceWorkflowTask> WorkflowTasks,
    IReadOnlyCollection<DocumentEvidenceSignature> Signatures,
    IReadOnlyCollection<DocumentEvidenceLegalHold> LegalHolds);

/// <summary>
/// Represents one immutable document version inside an evidence package.
/// </summary>
public sealed record DocumentEvidenceVersion(
    Guid VersionId,
    int VersionNumber,
    string StorageObjectKey,
    string MimeType,
    string FileHashSha256,
    long FileSizeBytes,
    Guid? UploadedByUserId,
    DateTimeOffset UploadedAtUtc);

/// <summary>
/// Represents one audit event linked to the document.
/// </summary>
public sealed record DocumentEvidenceAuditEvent(
    long AuditEventId,
    string TenantCode,
    Guid? ActorUserId,
    string EventType,
    string Severity,
    DateTimeOffset OccurredAtUtc);

/// <summary>
/// Represents one workflow task linked to the document.
/// </summary>
public sealed record DocumentEvidenceWorkflowTask(
    Guid WorkflowTaskId,
    string Title,
    string? Notes,
    string Status,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? DueAtUtc,
    Guid? CompletedByUserId,
    DateTimeOffset? CompletedAtUtc);

/// <summary>
/// Represents one signature request linked to the document.
/// </summary>
public sealed record DocumentEvidenceSignature(
    Guid SignatureEnvelopeId,
    string SignerDisplayName,
    string SignerEmail,
    string SignatureLevel,
    string ProviderCode,
    string? ExternalReference,
    string Status,
    Guid? RequestedByUserId,
    DateTimeOffset RequestedAtUtc,
    DateTimeOffset? DueAtUtc,
    Guid? CompletedByUserId,
    DateTimeOffset? CompletedAtUtc);

/// <summary>
/// Represents one legal hold linked to the document.
/// </summary>
public sealed record DocumentEvidenceLegalHold(
    Guid LegalHoldId,
    string Reason,
    bool IsActive,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc,
    Guid? ReleasedByUserId,
    DateTimeOffset? ReleasedAtUtc,
    string? ReleaseReason);
