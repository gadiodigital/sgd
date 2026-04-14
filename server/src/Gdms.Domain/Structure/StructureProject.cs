using Gdms.Domain.Common;

namespace Gdms.Domain.Structure;

/// <summary>
/// Represents a tenant-scoped configurable document structure.
/// </summary>
public sealed class StructureProject
{
    private StructureProject(
        Guid id,
        Guid tenantId,
        string code,
        string name,
        string? description,
        StructureProjectStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        Code = code;
        Name = name;
        Description = description;
        Status = status;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public string Code { get; }
    public string Name { get; }
    public string? Description { get; }
    public StructureProjectStatus Status { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    public static StructureProject Create(
        Guid tenantId,
        string code,
        string name,
        string? description,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant es obligatorio para crear un proyecto documental.");
        }

        return new StructureProject(
            Guid.NewGuid(),
            tenantId,
            NormalizeCode(code, "El código del proyecto es obligatorio.", 48),
            RequireText(name, "El nombre del proyecto es obligatorio.", 160),
            NormalizeOptional(description, 500),
            StructureProjectStatus.Active,
            createdByUserId,
            createdAtUtc);
    }

    public static StructureProject Rehydrate(
        Guid id,
        Guid tenantId,
        string code,
        string name,
        string? description,
        StructureProjectStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new StructureProject(id, tenantId, code, name, description, status, createdByUserId, createdAtUtc);
    }

    internal static string NormalizeCode(string value, string requiredMessage, int maxLength)
    {
        var normalized = RequireText(value, requiredMessage, maxLength).ToUpperInvariant();
        if (!normalized.All(ch => char.IsLetterOrDigit(ch) || ch is '-' or '_'))
        {
            throw new DomainRuleException("El código solo admite letras, números, guión y guión bajo.");
        }

        return normalized;
    }

    internal static string RequireText(string value, string message, int maxLength)
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

    internal static string? NormalizeOptional(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new DomainRuleException($"El valor '{normalized}' excede la longitud máxima permitida de {maxLength}.");
        }

        return normalized;
    }
}
