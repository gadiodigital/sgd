namespace Gdms.Contracts.Signature;

/// <summary>
/// Captures the tenant request used to cancel a pending signature envelope.
/// </summary>
public sealed record CancelSignatureEnvelopeRequest(string Reason);
