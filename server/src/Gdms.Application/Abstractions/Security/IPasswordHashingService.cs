namespace Gdms.Application.Abstractions.Security;

/// <summary>
/// Provides password hashing and verification primitives for local authentication.
/// </summary>
public interface IPasswordHashingService
{
    /// <summary>
    /// Hashes a clear-text password using the configured password policy.
    /// </summary>
    string HashPassword(string password);

    /// <summary>
    /// Verifies a clear-text password against a stored hash.
    /// </summary>
    bool VerifyPassword(string passwordHash, string providedPassword);
}
