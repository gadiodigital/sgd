using Gdms.Domain.Common;

namespace Gdms.Domain.RealEstate;

/// <summary>
/// Represents a tenant-scoped property file used by real-estate operators.
/// </summary>
public sealed class PropertyFile
{
    private PropertyFile(
        Guid id,
        Guid tenantId,
        string code,
        string title,
        string address,
        string operationType,
        PropertyFileStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        Code = code;
        Title = title;
        Address = address;
        OperationType = operationType;
        Status = status;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public string Code { get; }
    public string Title { get; }
    public string Address { get; }
    public string OperationType { get; }
    public PropertyFileStatus Status { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Creates a new active property file.
    /// </summary>
    public static PropertyFile Create(
        Guid tenantId,
        string code,
        string title,
        string address,
        string operationType,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant es obligatorio para crear un legajo inmobiliario.");
        }

        return new PropertyFile(
            Guid.NewGuid(),
            tenantId,
            NormalizeCode(code),
            RequireText(title, "El título del legajo inmobiliario es obligatorio.", 160),
            RequireText(address, "La dirección del inmueble es obligatoria.", 200),
            RequireText(operationType, "El tipo de operación del legajo es obligatorio.", 40).ToUpperInvariant(),
            PropertyFileStatus.Active,
            createdByUserId,
            createdAtUtc);
    }

    /// <summary>
    /// Rehydrates a property file from persistence.
    /// </summary>
    public static PropertyFile Rehydrate(
        Guid id,
        Guid tenantId,
        string code,
        string title,
        string address,
        string operationType,
        PropertyFileStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new PropertyFile(
            id,
            tenantId,
            code,
            title,
            address,
            operationType,
            status,
            createdByUserId,
            createdAtUtc);
    }

    private static string NormalizeCode(string value)
    {
        var normalized = RequireText(value, "El código del legajo inmobiliario es obligatorio.", 40).ToUpperInvariant();
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
