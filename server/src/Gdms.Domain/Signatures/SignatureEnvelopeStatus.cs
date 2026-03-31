namespace Gdms.Domain.Signatures;

/// <summary>
/// Defines the lifecycle states of a document signature envelope.
/// </summary>
public enum SignatureEnvelopeStatus
{
    Pending = 0,
    Signed = 1,
    Cancelled = 2
}
