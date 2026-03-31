namespace Gdms.Application.Abstractions.Integrations;

/// <summary>
/// Defines the port used to prepare signature requests with an external provider.
/// </summary>
public interface ISignatureProviderGateway
{
    /// <summary>
    /// Creates provider-side metadata for a pending signature request.
    /// </summary>
    Task<PreparedSignatureRequest> PrepareAsync(
        Guid tenantId,
        Guid documentId,
        string signerDisplayName,
        string signerEmail,
        string signatureLevel,
        CancellationToken cancellationToken);
}
