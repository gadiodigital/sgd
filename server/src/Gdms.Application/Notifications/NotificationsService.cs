using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Signatures;
using Gdms.Domain.Workflow;

namespace Gdms.Application.Notifications;

/// <summary>
/// Aggregates actionable tenant notifications from existing bounded contexts.
/// </summary>
public sealed class NotificationsService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentDispositionRepository _documentDispositionRepository;
    private readonly ISignatureEnvelopeRepository _signatureEnvelopeRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IWorkflowTaskRepository _workflowTaskRepository;

    /// <summary>
    /// Initializes the notification aggregator with the required repositories.
    /// </summary>
    public NotificationsService(
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository,
        IWorkflowTaskRepository workflowTaskRepository,
        IDocumentDispositionRepository documentDispositionRepository,
        ISignatureEnvelopeRepository signatureEnvelopeRepository)
    {
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
        _workflowTaskRepository = workflowTaskRepository;
        _documentDispositionRepository = documentDispositionRepository;
        _signatureEnvelopeRepository = signatureEnvelopeRepository;
    }

    /// <summary>
    /// Builds the current notification inbox of an organization.
    /// </summary>
    public async Task<IReadOnlyCollection<NotificationItem>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para consultar notificaciones.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para consultar notificaciones.");
        }

        var asOfUtc = DateTimeOffset.UtcNow;
        var workflowTasks = await _workflowTaskRepository.ListByTenantAsync(
            tenantId,
            null,
            cancellationToken);
        var signatureEnvelopes = await _signatureEnvelopeRepository.ListByTenantAsync(tenantId, cancellationToken);
        var dispositionCandidates = await _documentDispositionRepository.ListDueAsync(
            tenantId,
            asOfUtc,
            cancellationToken);
        var auditEvents = await _auditEventRepository.ListRecentByTenantAsync(
            tenantId,
            50,
            cancellationToken);

        var notifications = new List<NotificationItem>();
        notifications.AddRange(BuildWorkflowNotifications(workflowTasks));
        notifications.AddRange(BuildSignatureNotifications(signatureEnvelopes));
        notifications.AddRange(BuildDispositionNotifications(dispositionCandidates));
        notifications.AddRange(BuildSecurityNotifications(auditEvents, asOfUtc));

        return notifications
            .OrderByDescending(item => item.OccurredAtUtc)
            .Take(20)
            .ToArray();
    }

    private static IReadOnlyCollection<NotificationItem> BuildSignatureNotifications(
        IReadOnlyCollection<SignatureEnvelope> envelopes)
    {
        var pendingItems = envelopes
            .Where(envelope => envelope.Status == SignatureEnvelopeStatus.Pending)
            .Select(envelope => new NotificationItem(
                "SIGNATURE",
                $"Firma pendiente: {envelope.SignerDisplayName}",
                envelope.DueAtUtc is null
                    ? $"Solicitud {envelope.SignatureLevel} pendiente de cierre."
                    : $"Solicitud {envelope.SignatureLevel} con vencimiento {envelope.DueAtUtc:dd/MM/yyyy}.",
                envelope.DueAtUtc is { } dueAtUtc && dueAtUtc < DateTimeOffset.UtcNow
                    ? "WARNING"
                    : "INFO",
                envelope.DueAtUtc ?? envelope.RequestedAtUtc));

        var cancelledItems = envelopes
            .Where(envelope => envelope.Status == SignatureEnvelopeStatus.Cancelled)
            .Where(envelope => envelope.CancelledAtUtc is { } cancelledAtUtc
                && cancelledAtUtc >= DateTimeOffset.UtcNow.AddDays(-7))
            .Select(envelope => new NotificationItem(
                "SIGNATURE",
                $"Firma cancelada: {envelope.SignerDisplayName}",
                string.IsNullOrWhiteSpace(envelope.CancellationReason)
                    ? "La solicitud de firma fue cancelada recientemente."
                    : $"Cancelada: {envelope.CancellationReason}.",
                "WARNING",
                envelope.CancelledAtUtc!.Value));

        return pendingItems.Concat(cancelledItems).ToArray();
    }

    private static IReadOnlyCollection<NotificationItem> BuildWorkflowNotifications(
        IReadOnlyCollection<WorkflowTask> tasks)
    {
        return tasks
            .Where(task => task.Status == WorkflowTaskStatus.Open)
            .Select(task => new NotificationItem(
                "WORKFLOW",
                task.Title,
                task.DueAtUtc is null
                    ? "Tarea pendiente sin vencimiento asignado."
                    : $"Tarea pendiente con vencimiento {task.DueAtUtc:dd/MM/yyyy}.",
                task.DueAtUtc is { } dueAtUtc && dueAtUtc < DateTimeOffset.UtcNow
                    ? "WARNING"
                    : "INFO",
                task.DueAtUtc ?? task.CreatedAtUtc))
            .ToArray();
    }

    private static IReadOnlyCollection<NotificationItem> BuildDispositionNotifications(
        IReadOnlyCollection<Records.DispositionCandidate> candidates)
    {
        return candidates.Select(candidate => new NotificationItem(
            "RECORDS",
            $"Disposición pendiente: {candidate.Title}",
            candidate.HasActiveLegalHold
                ? "Existe legal hold activo. Revisión requerida."
                : $"Acción recomendada: {candidate.RecommendedAction}.",
            candidate.HasActiveLegalHold ? "CRITICAL" : "WARNING",
            candidate.DueAtUtc))
            .ToArray();
    }

    private static IReadOnlyCollection<NotificationItem> BuildSecurityNotifications(
        IReadOnlyCollection<AuditEventEntry> events,
        DateTimeOffset asOfUtc)
    {
        return events
            .Where(item => item.EventType == "LOGIN_FAILED")
            .Where(item => item.OccurredAtUtc >= asOfUtc.AddHours(-24))
            .Select(item => new NotificationItem(
                "SECURITY",
                "Intento fallido de inicio de sesión",
                "Se registró un intento fallido de autenticación en las últimas 24 horas.",
                "WARNING",
                item.OccurredAtUtc))
            .ToArray();
    }
}
