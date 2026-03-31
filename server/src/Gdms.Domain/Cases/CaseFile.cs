using Gdms.Domain.Common;

namespace Gdms.Domain.Cases;

/// <summary>
/// Represents a tenant-scoped case file or expediente.
/// </summary>
public sealed class CaseFile
{
    private CaseFile(
        Guid id,
        Guid tenantId,
        string code,
        string title,
        string category,
        CaseFileStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        Code = code;
        Title = title;
        Category = category;
        Status = status;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public string Code { get; }
    public string Title { get; }
    public string Category { get; }
    public CaseFileStatus Status { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Creates a new open case file.
    /// </summary>
    public static CaseFile Create(
        Guid tenantId,
        string code,
        string title,
        string category,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant es obligatorio para crear un expediente.");
        }

        return new CaseFile(
            Guid.NewGuid(),
            tenantId,
            NormalizeCode(code),
            RequireText(title, "El título del expediente es obligatorio.", 160),
            RequireText(category, "La categoría del expediente es obligatoria.", 80).ToUpperInvariant(),
            CaseFileStatus.Open,
            createdByUserId,
            createdAtUtc);
    }

    /// <summary>
    /// Rehydrates a case file from persistence.
    /// </summary>
    public static CaseFile Rehydrate(
        Guid id,
        Guid tenantId,
        string code,
        string title,
        string category,
        CaseFileStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new CaseFile(id, tenantId, code, title, category, status, createdByUserId, createdAtUtc);
    }

    private static string NormalizeCode(string value)
    {
        var normalized = RequireText(value, "El código del expediente es obligatorio.", 40).ToUpperInvariant();
        if (!normalized.All(ch => char.IsLetterOrDigit(ch) || ch is '-' or '_'))
        {
            throw new DomainRuleException("El código del expediente solo admite letras, números, guión y guión bajo.");
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
