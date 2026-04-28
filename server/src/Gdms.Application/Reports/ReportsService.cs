using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Signatures;
using Gdms.Domain.Workflow;

namespace Gdms.Application.Reports;

/// <summary>
/// Builds organization-scoped operational reports from existing bounded contexts.
/// </summary>
public sealed class ReportsService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentDispositionRepository _documentDispositionRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ILegalHoldRepository _legalHoldRepository;
    private readonly ISignatureEnvelopeRepository _signatureEnvelopeRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IWorkflowTaskRepository _workflowTaskRepository;

    /// <summary>
    /// Initializes the reports service with the required repositories.
    /// </summary>
    public ReportsService(
        ITenantRepository tenantRepository,
        IDocumentRepository documentRepository,
        ILegalHoldRepository legalHoldRepository,
        IWorkflowTaskRepository workflowTaskRepository,
        ISignatureEnvelopeRepository signatureEnvelopeRepository,
        IDocumentDispositionRepository documentDispositionRepository,
        IAuditEventRepository auditEventRepository)
    {
        _tenantRepository = tenantRepository;
        _documentRepository = documentRepository;
        _legalHoldRepository = legalHoldRepository;
        _workflowTaskRepository = workflowTaskRepository;
        _signatureEnvelopeRepository = signatureEnvelopeRepository;
        _documentDispositionRepository = documentDispositionRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Builds the current operational summary of an organization.
    /// </summary>
    public async Task<OperationalReportSummary> GetOperationalSummaryAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var documents = await _documentRepository.ListByTenantAsync(tenantId, cancellationToken);
        var workflowTasks = await _workflowTaskRepository.ListByTenantAsync(
            tenantId,
            null,
            cancellationToken);
        var signatures = await _signatureEnvelopeRepository.ListByTenantAsync(tenantId, cancellationToken);
        var auditEvents = await _auditEventRepository.ListRecentByTenantAsync(tenantId, 200, cancellationToken);
        var dispositionItems = await _documentDispositionRepository.ListDueAsync(
            tenantId,
            DateTimeOffset.UtcNow,
            cancellationToken);

        var legalHoldCount = 0;
        foreach (var document in documents)
        {
            var holds = await _legalHoldRepository.ListByDocumentAsync(
                tenantId,
                document.Id,
                cancellationToken);
            legalHoldCount += holds.Count(item => item.IsActive);
        }

        return new OperationalReportSummary(
            documents.Count,
            legalHoldCount,
            workflowTasks.Count(item => item.Status == WorkflowTaskStatus.Open),
            signatures.Count(item => item.Status == SignatureEnvelopeStatus.Pending),
            signatures.Count(item => item.Status == SignatureEnvelopeStatus.Cancelled),
            dispositionItems.Count,
            auditEvents.Count(item =>
                item.EventType == "LOGIN_FAILED" &&
                item.OccurredAtUtc >= DateTimeOffset.UtcNow.AddHours(-24)));
    }

    /// <summary>
    /// Builds the current platform-wide operational summary.
    /// </summary>
    public async Task<PlatformReportSummary> GetPlatformSummaryAsync(CancellationToken cancellationToken)
    {
        var tenants = await _tenantRepository.ListAsync(cancellationToken);
        var totalDocuments = 0;
        var openWorkflowTasks = 0;
        var pendingSignatures = 0;
        var cancelledSignatures = 0;

        foreach (var tenant in tenants)
        {
            var documents = await _documentRepository.ListByTenantAsync(tenant.Id, cancellationToken);
            var workflowTasks = await _workflowTaskRepository.ListByTenantAsync(
                tenant.Id,
                null,
                cancellationToken);
            var signatures = await _signatureEnvelopeRepository.ListByTenantAsync(tenant.Id, cancellationToken);

            totalDocuments += documents.Count;
            openWorkflowTasks += workflowTasks.Count(item => item.Status == WorkflowTaskStatus.Open);
            pendingSignatures += signatures.Count(item => item.Status == SignatureEnvelopeStatus.Pending);
            cancelledSignatures += signatures.Count(item => item.Status == SignatureEnvelopeStatus.Cancelled);
        }

        var auditEvents = await _auditEventRepository.ListRecentAsync(500, cancellationToken);
        var failedLoginsLast24Hours = auditEvents.Count(item =>
            item.EventType == "LOGIN_FAILED" &&
            item.OccurredAtUtc >= DateTimeOffset.UtcNow.AddHours(-24));

        return new PlatformReportSummary(
            tenants.Count,
            totalDocuments,
            openWorkflowTasks,
            pendingSignatures,
            cancelledSignatures,
            failedLoginsLast24Hours);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para reportes.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para reportes.");
        }
    }
}
