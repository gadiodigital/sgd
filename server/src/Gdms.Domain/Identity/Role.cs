using Gdms.Domain.Common;

namespace Gdms.Domain.Identity;

/// <summary>
/// Represents an assignable authorization role.
/// </summary>
public sealed class Role
{
    /// <summary>
    /// Initializes a new role.
    /// </summary>
    public Role(Guid id, string code, string name, string description)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("El identificador del rol es obligatorio.") : id;
        Code = NormalizeCode(code);
        Name = RequireText(name, "El nombre del rol es obligatorio.", 100);
        Description = RequireText(description, "La descripción del rol es obligatoria.", 240);
    }

    /// <summary>
    /// Gets the role identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the normalized role code.
    /// </summary>
    public string Code { get; }

    /// <summary>
    /// Gets the display role name.
    /// </summary>
    public string Name { get; }

    /// <summary>
    /// Gets the business description of the role.
    /// </summary>
    public string Description { get; }

    private static string NormalizeCode(string value)
    {
        var normalized = RequireText(value, "El código del rol es obligatorio.", 32).ToUpperInvariant();
        if (!normalized.All(ch => char.IsLetterOrDigit(ch) || ch == '_'))
        {
            throw new DomainRuleException("El código del rol solo admite letras, números y guión bajo.");
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
