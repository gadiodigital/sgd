using System.Net.Mail;
using Gdms.Domain.Common;

namespace Gdms.Domain.Identity;

/// <summary>
/// Represents an identity user within a tenant boundary.
/// </summary>
public sealed class User
{
    private readonly List<Role> _roles = [];

    /// <summary>
    /// Initializes a new user aggregate.
    /// </summary>
    public User(
        Guid id,
        Guid tenantId,
        string email,
        string fullName,
        UserStatus status,
        DateTimeOffset createdAtUtc)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("El identificador del usuario es obligatorio.") : id;
        TenantId = tenantId == Guid.Empty ? throw new DomainRuleException("El tenant del usuario es obligatorio.") : tenantId;
        Email = NormalizeEmail(email);
        FullName = RequireText(fullName, "El nombre completo del usuario es obligatorio.", 160);
        Status = status;
        CreatedAtUtc = createdAtUtc;
    }

    /// <summary>
    /// Gets the user identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the tenant owner identifier.
    /// </summary>
    public Guid TenantId { get; }

    /// <summary>
    /// Gets the normalized email address.
    /// </summary>
    public string Email { get; }

    /// <summary>
    /// Gets the full display name.
    /// </summary>
    public string FullName { get; }

    /// <summary>
    /// Gets the current lifecycle status.
    /// </summary>
    public UserStatus Status { get; private set; }

    /// <summary>
    /// Gets the UTC creation timestamp.
    /// </summary>
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Gets the roles currently assigned to the user.
    /// </summary>
    public IReadOnlyCollection<Role> Roles => _roles.AsReadOnly();

    /// <summary>
    /// Creates a new user aggregate using platform defaults.
    /// </summary>
    public static User Create(
        Guid tenantId,
        string email,
        string fullName,
        UserStatus status,
        DateTimeOffset createdAtUtc)
    {
        return new User(Guid.NewGuid(), tenantId, email, fullName, status, createdAtUtc);
    }

    /// <summary>
    /// Rehydrates a user aggregate with its assigned roles.
    /// </summary>
    public static User Rehydrate(
        Guid id,
        Guid tenantId,
        string email,
        string fullName,
        UserStatus status,
        DateTimeOffset createdAtUtc,
        IEnumerable<Role> roles)
    {
        var user = new User(id, tenantId, email, fullName, status, createdAtUtc);
        foreach (var role in roles)
        {
            user.AssignRole(role);
        }

        return user;
    }

    /// <summary>
    /// Assigns a new role to the user in an idempotent way.
    /// </summary>
    public void AssignRole(Role role)
    {
        ArgumentNullException.ThrowIfNull(role);

        if (_roles.Any(existing => existing.Id == role.Id || existing.Code == role.Code))
        {
            return;
        }

        _roles.Add(role);
    }

    private static string NormalizeEmail(string value)
    {
        var normalized = RequireText(value, "El correo electrónico es obligatorio.", 320).ToLowerInvariant();

        try
        {
            var parsed = new MailAddress(normalized);
            return parsed.Address.ToLowerInvariant();
        }
        catch (FormatException)
        {
            throw new DomainRuleException("El correo electrónico informado no tiene un formato válido.");
        }
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
