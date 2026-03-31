using Gdms.Domain.Common;

namespace Gdms.Domain.Records;

/// <summary>
/// Represents a retention policy that can be assigned to documents.
/// </summary>
public sealed class RetentionPolicy
{
    /// <summary>
    /// Initializes a new retention policy.
    /// </summary>
    public RetentionPolicy(
        Guid id,
        Guid? tenantId,
        string code,
        string name,
        int retentionDays,
        RetentionDispositionAction dispositionAction,
        bool isActive)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("La política de retención debe tener identificador.") : id;
        TenantId = tenantId is { } value && value != Guid.Empty ? value : null;
        Code = NormalizeCode(code);
        Name = RequireText(name, "El nombre de la política de retención es obligatorio.", 120);
        RetentionDays = retentionDays > 0 ? retentionDays : throw new DomainRuleException("La retención en días debe ser mayor a cero.");
        DispositionAction = dispositionAction;
        IsActive = isActive;
    }

    /// <summary>
    /// Gets the policy identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the optional tenant owner identifier.
    /// </summary>
    public Guid? TenantId { get; }

    /// <summary>
    /// Gets the normalized policy code.
    /// </summary>
    public string Code { get; }

    /// <summary>
    /// Gets the display name.
    /// </summary>
    public string Name { get; }

    /// <summary>
    /// Gets the retention period in days.
    /// </summary>
    public int RetentionDays { get; }

    /// <summary>
    /// Gets the disposition outcome after retention.
    /// </summary>
    public RetentionDispositionAction DispositionAction { get; }

    /// <summary>
    /// Gets whether the policy is active.
    /// </summary>
    public bool IsActive { get; }

    private static string NormalizeCode(string value)
    {
        var normalized = RequireText(value, "El código de la política de retención es obligatorio.", 48).ToUpperInvariant();
        if (!normalized.All(ch => char.IsLetterOrDigit(ch) || ch == '_'))
        {
            throw new DomainRuleException("El código de política solo admite letras, números y guión bajo.");
        }

        return normalized;
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
