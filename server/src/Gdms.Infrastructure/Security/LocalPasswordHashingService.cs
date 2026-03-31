using Gdms.Application.Abstractions.Security;
using Microsoft.AspNetCore.Identity;

namespace Gdms.Infrastructure.Security;

/// <summary>
/// Implements local password hashing using ASP.NET Core Identity primitives.
/// </summary>
public sealed class LocalPasswordHashingService : IPasswordHashingService
{
    private readonly PasswordHasher<object> _passwordHasher = new();

    /// <inheritdoc />
    public string HashPassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException("La contraseña es obligatoria.");
        }

        return _passwordHasher.HashPassword(new object(), password.Trim());
    }

    /// <inheritdoc />
    public bool VerifyPassword(string passwordHash, string providedPassword)
    {
        if (string.IsNullOrWhiteSpace(passwordHash) || string.IsNullOrWhiteSpace(providedPassword))
        {
            return false;
        }

        var result = _passwordHasher.VerifyHashedPassword(new object(), passwordHash, providedPassword.Trim());
        return result is PasswordVerificationResult.Success or PasswordVerificationResult.SuccessRehashNeeded;
    }
}
