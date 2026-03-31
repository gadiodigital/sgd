namespace Gdms.Contracts.Records;

/// <summary>
/// Represents a document that is due for retention-driven disposition.
/// </summary>
public sealed record DispositionCandidateResponse(
    Guid DocumentId,
    string DocumentTypeCode,
    string Title,
    string CurrentStatus,
    string RetentionPolicyCode,
    int RetentionDays,
    string RecommendedAction,
    DateTimeOffset DueAtUtc,
    bool HasActiveLegalHold);
