using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Documents;
using Gdms.Domain.Records;

namespace Gdms.Application.Records;

/// <summary>
/// Coordinates retention and legal-hold use cases.
/// </summary>
public sealed class RecordsService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly IDocumentDispositionRepository _documentDispositionRepository;
    private readonly ILegalHoldRepository _legalHoldRepository;
    private readonly IRetentionPolicyRepository _retentionPolicyRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with records-management dependencies.
    /// </summary>
    public RecordsService(
        ITenantRepository tenantRepository,
        IDocumentRepository documentRepository,
        IDocumentDispositionRepository documentDispositionRepository,
        IRetentionPolicyRepository retentionPolicyRepository,
        ILegalHoldRepository legalHoldRepository,
        IAuditEventRepository auditEventRepository)
    {
        _tenantRepository = tenantRepository;
        _documentRepository = documentRepository;
        _documentDispositionRepository = documentDispositionRepository;
        _retentionPolicyRepository = retentionPolicyRepository;
        _legalHoldRepository = legalHoldRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists active retention policies available to a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<RetentionPolicy>> ListRetentionPoliciesAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _retentionPolicyRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Applies a retention policy to a document.
    /// </summary>
    public async Task ApplyRetentionPolicyAsync(
        Guid tenantId,
        Guid documentId,
        string policyCode,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var document = await GetDocumentWithinTenantAsync(tenantId, documentId, cancellationToken);
        var policy = await _retentionPolicyRepository.GetByCodeAsync(tenantId, policyCode, cancellationToken)
            ?? throw new DomainRuleException($"No existe una política de retención activa con código '{policyCode}'.");

        await _documentRepository.AssignRetentionPolicyAsync(
            tenantId,
            document.Id,
            policy.Id,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            document.Id,
            "RETENTION_POLICY_APPLIED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                DocumentId = document.Id,
                RetentionPolicyId = policy.Id,
                policy.Code,
                policy.RetentionDays,
                DispositionAction = policy.DispositionAction.ToString().ToUpperInvariant()
            }),
            cancellationToken);
    }

    /// <summary>
    /// Lists the legal holds of a document.
    /// </summary>
    public async Task<IReadOnlyCollection<LegalHold>> ListLegalHoldsAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        await GetDocumentWithinTenantAsync(tenantId, documentId, cancellationToken);
        return await _legalHoldRepository.ListByDocumentAsync(tenantId, documentId, cancellationToken);
    }

    /// <summary>
    /// Creates a new legal hold for a document.
    /// </summary>
    public async Task<LegalHold> CreateLegalHoldAsync(
        Guid tenantId,
        Guid documentId,
        string reason,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var document = await GetDocumentWithinTenantAsync(tenantId, documentId, cancellationToken);
        var legalHold = LegalHold.Create(tenantId, document.Id, reason, actorUserId, DateTimeOffset.UtcNow);
        var persistedLegalHold = await _legalHoldRepository.AddAsync(legalHold, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            document.Id,
            "LEGAL_HOLD_CREATED",
            "WARNING",
            JsonSerializer.Serialize(new
            {
                persistedLegalHold.Id,
                persistedLegalHold.Reason,
                persistedLegalHold.CreatedAtUtc
            }),
            cancellationToken);

        return persistedLegalHold;
    }

    /// <summary>
    /// Releases an active legal hold.
    /// </summary>
    public async Task<LegalHold> ReleaseLegalHoldAsync(
        Guid tenantId,
        Guid legalHoldId,
        string releaseReason,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var releasedLegalHold = await _legalHoldRepository.ReleaseAsync(
            tenantId,
            legalHoldId,
            actorUserId,
            releaseReason,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            releasedLegalHold.DocumentId,
            "LEGAL_HOLD_RELEASED",
            "WARNING",
            JsonSerializer.Serialize(new
            {
                releasedLegalHold.Id,
                releasedLegalHold.DocumentId,
                releasedLegalHold.ReleaseReason,
                releasedLegalHold.ReleasedAtUtc
            }),
            cancellationToken);

        return releasedLegalHold;
    }

    /// <summary>
    /// Lists the documents whose retention period already expired.
    /// </summary>
    public async Task<IReadOnlyCollection<DispositionCandidate>> ListDispositionCandidatesAsync(
        Guid tenantId,
        DateTimeOffset asOfUtc,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _documentDispositionRepository.ListDueAsync(tenantId, asOfUtc, cancellationToken);
    }

    /// <summary>
    /// Executes the policy-driven disposition for a due document.
    /// </summary>
    public async Task ExecuteDispositionAsync(
        Guid tenantId,
        Guid documentId,
        Guid actorUserId,
        DateTimeOffset asOfUtc,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var candidate = await _documentDispositionRepository.GetDueByIdAsync(
            tenantId,
            documentId,
            asOfUtc,
            cancellationToken)
            ?? throw new DomainRuleException("El documento informado no tiene una disposición pendiente a la fecha indicada.");

        if (candidate.RecommendedAction == "REVIEW")
        {
            throw new DomainRuleException("La política de retención requiere revisión manual y no admite disposición automática.");
        }

        if (candidate.RecommendedAction == "DELETE" && candidate.HasActiveLegalHold)
        {
            throw new DomainRuleException("No se puede ejecutar una disposición DELETE mientras exista un legal hold activo.");
        }

        var nextStatus = candidate.RecommendedAction == "ARCHIVE"
            ? DocumentStatus.Archived
            : DocumentStatus.Disposed;

        await _documentDispositionRepository.ApplyDispositionAsync(
            tenantId,
            candidate.DocumentId,
            candidate.RecommendedAction,
            nextStatus,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            candidate.DocumentId,
            "DOCUMENT_DISPOSITION_EXECUTED",
            candidate.RecommendedAction == "DELETE" ? "CRITICAL" : "WARNING",
            JsonSerializer.Serialize(new
            {
                candidate.DocumentId,
                candidate.RetentionPolicyCode,
                candidate.RecommendedAction,
                candidate.DueAtUtc,
                candidate.HasActiveLegalHold,
                NextStatus = nextStatus.ToString().ToUpperInvariant()
            }),
            cancellationToken);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para la operación de records management.");
        }
    }

    private async Task<Domain.Documents.Document> GetDocumentWithinTenantAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant.");
        }

        return document;
    }
}
