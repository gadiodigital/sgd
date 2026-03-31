using Gdms.Domain.Common;

namespace Gdms.Domain.Corporate;

/// <summary>
/// Represents a tenant-scoped corporate record file.
/// </summary>
public sealed class CorporateRecordFile
{
    private CorporateRecordFile(
        Guid id,
        Guid tenantId,
        string code,
        string title,
        string category,
        string ownerArea,
        CorporateRecordFileStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        Code = code;
        Title = title;
        Category = category;
        OwnerArea = ownerArea;
        Status = status;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public string Code { get; }
    public string Title { get; }
    public string Category { get; }
    public string OwnerArea { get; }
    public CorporateRecordFileStatus Status { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Creates a new active corporate record file.
    /// </summary>
    public static CorporateRecordFile Create(
        Guid tenantId,
        string code,
        string title,
        string category,
        string ownerArea,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant es obligatorio para crear un legajo corporativo.");
        }

        return new CorporateRecordFile(
            Guid.NewGuid(),
            tenantId,
            NormalizeCode(code),
            RequireText(title, "El título del legajo corporativo es obligatorio.", 160),
            RequireText(category, "La categoría del legajo corporativo es obligatoria.", 80).ToUpperInvariant(),
            RequireText(ownerArea, "El área responsable del legajo corporativo es obligatoria.", 80).ToUpperInvariant(),
            CorporateRecordFileStatus.Active,
            createdByUserId,
            createdAtUtc);
    }

    /// <summary>
    /// Rehydrates a corporate record file from persistence.
    /// </summary>
    public static CorporateRecordFile Rehydrate(
        Guid id,
        Guid tenantId,
        string code,
        string title,
        string category,
        string ownerArea,
        CorporateRecordFileStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new CorporateRecordFile(
            id,
            tenantId,
            code,
            title,
            category,
            ownerArea,
            status,
            createdByUserId,
            createdAtUtc);
    }

    private static string NormalizeCode(string value)
    {
        var normalized = RequireText(value, "El código del legajo corporativo es obligatorio.", 40).ToUpperInvariant();
        if (!normalized.All(ch => char.IsLetterOrDigit(ch) || ch is '-' or '_'))
        {
            throw new DomainRuleException("El código del legajo solo admite letras, números, guión y guión bajo.");
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
