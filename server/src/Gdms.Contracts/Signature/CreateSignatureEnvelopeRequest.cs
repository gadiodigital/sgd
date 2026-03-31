namespace Gdms.Contracts.Signature;

/// <summary>
/// Represents the payload required to create a signature request.
/// </summary>
public sealed record CreateSignatureEnvelopeRequest(
    Guid DocumentId,
    string SignerDisplayName,
    string SignerEmail,
    string SignatureLevel,
    string? ProviderCode,
    DateTimeOffset? DueAtUtc);
