using Gdms.Domain.Common;

namespace Gdms.Domain.Tenancy;

/// <summary>
/// Represents an isolated customer workspace within the GDMS platform.
/// </summary>
public sealed class Tenant
{
    /// <summary>
    /// Initializes a new tenant aggregate.
    /// </summary>
    public Tenant(
        Guid id,
        string code,
        string name,
        string sector,
        string primaryCountryCode,
        DateTimeOffset createdAtUtc)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("El identificador del tenant es obligatorio.") : id;
        Code = NormalizeCode(code);
        Name = RequireText(name, "El nombre del tenant es obligatorio.", 160);
        Sector = RequireText(sector, "El sector del tenant es obligatorio.", 80);
        PrimaryCountryCode = NormalizeCountry(primaryCountryCode);
        CreatedAtUtc = createdAtUtc;
    }

    /// <summary>
    /// Gets the tenant identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the short code used in URLs, integrations and database partitions.
    /// </summary>
    public string Code { get; }

    /// <summary>
    /// Gets the commercial or legal tenant name.
    /// </summary>
    public string Name { get; }

    /// <summary>
    /// Gets the business sector used to activate vertical rules.
    /// </summary>
    public string Sector { get; }

    /// <summary>
    /// Gets the primary ISO country code for the tenant.
    /// </summary>
    public string PrimaryCountryCode { get; }

    /// <summary>
    /// Gets the creation timestamp in UTC.
    /// </summary>
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Creates a new tenant using platform defaults.
    /// </summary>
    public static Tenant Create(
        string code,
        string name,
        string sector,
        string primaryCountryCode,
        DateTimeOffset createdAtUtc)
    {
        return new Tenant(Guid.NewGuid(), code, name, sector, primaryCountryCode, createdAtUtc);
    }

    private static string NormalizeCode(string value)
    {
        var normalized = RequireText(value, "El código del tenant es obligatorio.", 32).ToUpperInvariant();
        if (!normalized.All(ch => char.IsLetterOrDigit(ch) || ch is '-' or '_'))
        {
            throw new DomainRuleException("El código del tenant solo admite letras, números, guión y guión bajo.");
        }

        return normalized;
    }

    private static string NormalizeCountry(string value)
    {
        var normalized = RequireText(value, "El código de país es obligatorio.", 2).ToUpperInvariant();
        if (normalized.Length != 2 || !normalized.All(char.IsLetter))
        {
            throw new DomainRuleException("El código de país debe estar en formato ISO alpha-2.");
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
