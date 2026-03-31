using System.Security.Cryptography;
using System.Text;
using Gdms.Infrastructure.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Gdms.Infrastructure.Security;

/// <summary>
/// Provides a symmetric signing key shared by JWT issuance and validation.
/// </summary>
public sealed class JwtSigningKeyProvider
{
    /// <summary>
    /// Initializes the provider and resolves the active signing key.
    /// </summary>
    public JwtSigningKeyProvider(IOptions<JwtOptions> options, IHostEnvironment hostEnvironment)
    {
        var configuredKey = options.Value.SigningKey?.Trim();
        if (string.IsNullOrWhiteSpace(configuredKey))
        {
            if (!hostEnvironment.IsDevelopment())
            {
                throw new InvalidOperationException("La clave JWT es obligatoria fuera del entorno de desarrollo.");
            }

            configuredKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        }

        if (configuredKey.Length < 32)
        {
            throw new InvalidOperationException("La clave JWT debe tener al menos 32 caracteres.");
        }

        SecurityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuredKey));
    }

    /// <summary>
    /// Gets the resolved symmetric key.
    /// </summary>
    public SymmetricSecurityKey SecurityKey { get; }
}
