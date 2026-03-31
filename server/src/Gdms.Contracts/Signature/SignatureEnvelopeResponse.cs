namespace Gdms.Contracts.Signature;

/// <summary>
/// Represents a signature request returned to API clients.
/// </summary>
public sealed record SignatureEnvelopeResponse(
    Guid Id,
    Guid TenantId,
    Guid DocumentId,
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
    DateTimeOffset? CompletedAtUtc,
    Guid? CancelledByUserId,
    DateTimeOffset? CancelledAtUtc,
    string? CancellationReason);
