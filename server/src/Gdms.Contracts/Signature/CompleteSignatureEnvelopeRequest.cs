namespace Gdms.Contracts.Signature;

/// <summary>
/// Represents the payload used to complete a signature request.
/// </summary>
public sealed record CompleteSignatureEnvelopeRequest(string? ExternalReference);
