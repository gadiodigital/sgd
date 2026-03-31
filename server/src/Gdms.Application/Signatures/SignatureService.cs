using System.Text.Json;
using Gdms.Application.Abstractions.Integrations;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Signatures;

namespace Gdms.Application.Signatures;

/// <summary>
/// Coordinates the lifecycle of document signature requests.
/// </summary>
public sealed class SignatureService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ISignatureProviderGateway _signatureProviderGateway;
    private readonly ISignatureEnvelopeRepository _signatureEnvelopeRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with repositories required by signature flows.
    /// </summary>
    public SignatureService(
        ISignatureEnvelopeRepository signatureEnvelopeRepository,
        ISignatureProviderGateway signatureProviderGateway,
        ITenantRepository tenantRepository,
        IDocumentRepository documentRepository,
        IAuditEventRepository auditEventRepository)
    {
        _signatureEnvelopeRepository = signatureEnvelopeRepository;
        _signatureProviderGateway = signatureProviderGateway;
        _tenantRepository = tenantRepository;
        _documentRepository = documentRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists signature envelopes visible to a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<SignatureEnvelope>> ListByTenantAsync(
        Guid tenantId,
        Guid? documentId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var envelopes = await _signatureEnvelopeRepository.ListByTenantAsync(
            tenantId,
            cancellationToken);

        return documentId is null
            ? envelopes
            : envelopes.Where(item => item.DocumentId == documentId.Value).ToArray();
    }

    /// <summary>
    /// Creates a new signature request linked to an existing tenant document.
    /// </summary>
    public async Task<SignatureEnvelope> CreateAsync(
        Guid tenantId,
        Guid documentId,
        string signerDisplayName,
        string signerEmail,
        string signatureLevel,
        string? providerCode,
        DateTimeOffset? dueAtUtc,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado para solicitar firma.");
        }

        var preparedRequest = await _signatureProviderGateway.PrepareAsync(
            tenantId,
            documentId,
            signerDisplayName,
            signerEmail,
            signatureLevel,
            cancellationToken);

        var envelope = SignatureEnvelope.Create(
            tenantId,
            documentId,
            signerDisplayName,
            signerEmail,
            signatureLevel,
            string.IsNullOrWhiteSpace(providerCode)
                ? preparedRequest.ProviderCode
                : providerCode,
            preparedRequest.ExternalReference,
            actorUserId,
            DateTimeOffset.UtcNow,
            dueAtUtc);
        var persistedEnvelope = await _signatureEnvelopeRepository.AddAsync(envelope, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "SIGNATURE_REQUESTED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedEnvelope.Id,
                persistedEnvelope.SignerDisplayName,
                persistedEnvelope.SignerEmail,
                persistedEnvelope.SignatureLevel,
                persistedEnvelope.ProviderCode
            }),
            cancellationToken);

        return persistedEnvelope;
    }

    /// <summary>
    /// Completes a pending signature request.
    /// </summary>
    public async Task<SignatureEnvelope> CompleteAsync(
        Guid tenantId,
        Guid envelopeId,
        string? externalReference,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var envelope = await _signatureEnvelopeRepository.GetByIdAsync(envelopeId, cancellationToken);
        if (envelope is null || envelope.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe la solicitud de firma informada.");
        }

        envelope.Complete(actorUserId, DateTimeOffset.UtcNow, externalReference);
        await _signatureEnvelopeRepository.CompleteAsync(
            tenantId,
            envelopeId,
            actorUserId,
            envelope.CompletedAtUtc!.Value,
            envelope.ExternalReference,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            envelope.DocumentId,
            "SIGNATURE_COMPLETED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                envelope.Id,
                envelope.SignerEmail,
                envelope.ExternalReference,
                envelope.CompletedAtUtc
            }),
            cancellationToken);

        return envelope;
    }

    /// <summary>
    /// Cancels a pending signature request.
    /// </summary>
    public async Task<SignatureEnvelope> CancelAsync(
        Guid tenantId,
        Guid envelopeId,
        string reason,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var envelope = await _signatureEnvelopeRepository.GetByIdAsync(envelopeId, cancellationToken);
        if (envelope is null || envelope.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe la solicitud de firma informada.");
        }

        envelope.Cancel(actorUserId, DateTimeOffset.UtcNow, reason);
        await _signatureEnvelopeRepository.CancelAsync(
            tenantId,
            envelopeId,
            actorUserId,
            envelope.CancelledAtUtc!.Value,
            envelope.CancellationReason!,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            envelope.DocumentId,
            "SIGNATURE_CANCELLED",
            "WARN",
            JsonSerializer.Serialize(new
            {
                envelope.Id,
                envelope.SignerEmail,
                envelope.CancellationReason,
                envelope.CancelledAtUtc
            }),
            cancellationToken);

        return envelope;
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para firma.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para firma.");
        }
    }
}
