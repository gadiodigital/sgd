using Gdms.Application.Abstractions.Integrations;
using Gdms.Infrastructure.Configuration;
using Microsoft.Extensions.Options;

namespace Gdms.Infrastructure.Integrations;

/// <summary>
/// Provides a local signature-provider placeholder until an external PKI adapter is connected.
/// </summary>
public sealed class InternalSignatureProviderGateway : ISignatureProviderGateway
{
    private readonly SignatureProviderOptions _options;

    /// <summary>
    /// Initializes the gateway with provider configuration.
    /// </summary>
    public InternalSignatureProviderGateway(IOptions<SignatureProviderOptions> options)
    {
        _options = options.Value;
    }

    /// <inheritdoc />
    public Task<PreparedSignatureRequest> PrepareAsync(
        Guid tenantId,
        Guid documentId,
        string signerDisplayName,
        string signerEmail,
        string signatureLevel,
        CancellationToken cancellationToken)
    {
        var providerCode = string.IsNullOrWhiteSpace(_options.ProviderCode)
            ? "INTERNAL"
            : _options.ProviderCode.Trim().ToUpperInvariant();
        var externalReference = _options.GenerateReferences
            ? $"{providerCode}-{tenantId:N}-{documentId:N}"[..Math.Min(48, $"{providerCode}-{tenantId:N}-{documentId:N}".Length)]
            : null;

        return Task.FromResult(new PreparedSignatureRequest(providerCode, externalReference));
    }
}
