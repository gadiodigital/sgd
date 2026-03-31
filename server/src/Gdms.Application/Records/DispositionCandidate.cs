namespace Gdms.Application.Records;

/// <summary>
/// Represents a document that reached its retention due date and is eligible for disposition.
/// </summary>
public sealed record DispositionCandidate(
    Guid DocumentId,
    string DocumentTypeCode,
    string Title,
    string CurrentStatus,
    string RetentionPolicyCode,
    int RetentionDays,
    string RecommendedAction,
    DateTimeOffset DueAtUtc,
    bool HasActiveLegalHold);
