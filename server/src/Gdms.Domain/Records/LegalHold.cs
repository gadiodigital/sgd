using Gdms.Domain.Common;

namespace Gdms.Domain.Records;

/// <summary>
/// Represents a legal hold applied to a document.
/// </summary>
public sealed class LegalHold
{
    /// <summary>
    /// Initializes a new legal hold.
    /// </summary>
    public LegalHold(
        Guid id,
        Guid tenantId,
        Guid? documentId,
        string reason,
        bool isActive,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc,
        Guid? releasedByUserId,
        DateTimeOffset? releasedAtUtc,
        string? releaseReason)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("El legal hold debe tener identificador.") : id;
        TenantId = tenantId == Guid.Empty ? throw new DomainRuleException("El tenant del legal hold es obligatorio.") : tenantId;
        DocumentId = documentId is { } value && value != Guid.Empty ? value : null;
        Reason = RequireText(reason, "El motivo del legal hold es obligatorio.", 240);
        IsActive = isActive;
        CreatedByUserId = createdByUserId is { } creator && creator != Guid.Empty ? creator : null;
        CreatedAtUtc = createdAtUtc;
        ReleasedByUserId = releasedByUserId is { } releaser && releaser != Guid.Empty ? releaser : null;
        ReleasedAtUtc = releasedAtUtc;
        ReleaseReason = string.IsNullOrWhiteSpace(releaseReason)
            ? null
            : RequireText(releaseReason, "El motivo de liberación excede la longitud permitida.", 240);
    }

    /// <summary>
    /// Gets the hold identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the tenant owner identifier.
    /// </summary>
    public Guid TenantId { get; }

    /// <summary>
    /// Gets the held document identifier.
    /// </summary>
    public Guid? DocumentId { get; }

    /// <summary>
    /// Gets the hold reason.
    /// </summary>
    public string Reason { get; }

    /// <summary>
    /// Gets whether the hold is still active.
    /// </summary>
    public bool IsActive { get; }

    /// <summary>
    /// Gets the creator user identifier.
    /// </summary>
    public Guid? CreatedByUserId { get; }

    /// <summary>
    /// Gets the UTC creation timestamp.
    /// </summary>
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Gets the releasing user identifier when applicable.
    /// </summary>
    public Guid? ReleasedByUserId { get; }

    /// <summary>
    /// Gets the UTC release timestamp when applicable.
    /// </summary>
    public DateTimeOffset? ReleasedAtUtc { get; }

    /// <summary>
    /// Gets the release justification.
    /// </summary>
    public string? ReleaseReason { get; }

    /// <summary>
    /// Creates a new active legal hold.
    /// </summary>
    public static LegalHold Create(
        Guid tenantId,
        Guid documentId,
        string reason,
        Guid createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new LegalHold(
            Guid.NewGuid(),
            tenantId,
            documentId,
            reason,
            true,
            createdByUserId,
            createdAtUtc,
            null,
            null,
            null);
    }

    private static string RequireText(string value, string message, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new DomainRuleException(message);
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new DomainRuleException($"El valor '{normalized}' excede la longitud máxima permitida de {maxLength}.");
        }

        return normalized;
    }
}
