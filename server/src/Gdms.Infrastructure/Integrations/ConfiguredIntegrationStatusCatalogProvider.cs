using Gdms.Application.Abstractions.Integrations;
using Gdms.Infrastructure.Configuration;
using Microsoft.Extensions.Options;

namespace Gdms.Infrastructure.Integrations;

/// <summary>
/// Resolves integration statuses from configured infrastructure options.
/// </summary>
public sealed class ConfiguredIntegrationStatusCatalogProvider : IIntegrationStatusCatalogProvider
{
    private readonly FirebaseOptions _firebaseOptions;
    private readonly PostgresOptions _postgresOptions;
    private readonly SignatureProviderOptions _signatureProviderOptions;
    private readonly StorageOptions _storageOptions;

    /// <summary>
    /// Initializes the provider with current infrastructure options.
    /// </summary>
    public ConfiguredIntegrationStatusCatalogProvider(
        IOptions<PostgresOptions> postgresOptions,
        IOptions<FirebaseOptions> firebaseOptions,
        IOptions<StorageOptions> storageOptions,
        IOptions<SignatureProviderOptions> signatureProviderOptions)
    {
        _postgresOptions = postgresOptions.Value;
        _firebaseOptions = firebaseOptions.Value;
        _storageOptions = storageOptions.Value;
        _signatureProviderOptions = signatureProviderOptions.Value;
    }

    /// <inheritdoc />
    public IReadOnlyCollection<IntegrationStatusSnapshot> List()
    {
        return
        [
            BuildPostgresStatus(),
            BuildFirebaseRemoteConfigStatus(),
            BuildFirestoreStatus(),
            BuildStorageStatus(),
            BuildSignatureProviderStatus()
        ];
    }

    private IntegrationStatusSnapshot BuildPostgresStatus()
    {
        var configured = !string.IsNullOrWhiteSpace(_postgresOptions.MainDatabase);
        return new IntegrationStatusSnapshot(
            "POSTGRES",
            "PostgreSQL",
            "DATABASE",
            configured ? "READY" : "MISSING",
            configured
                ? "Fuente de verdad relacional configurada."
                : "Falta configurar la cadena principal de PostgreSQL.");
    }

    private IntegrationStatusSnapshot BuildFirebaseRemoteConfigStatus()
    {
        var configured = !string.IsNullOrWhiteSpace(_firebaseOptions.ProjectId);
        return new IntegrationStatusSnapshot(
            "FIREBASE_REMOTE_CONFIG",
            "Firebase Remote Config",
            "CONFIG",
            ResolveFirebaseStatus(configured),
            configured
                ? $"Proyecto {_firebaseOptions.ProjectId} con plantilla {_firebaseOptions.RemoteConfigTemplateName}."
                : "Falta configurar el proyecto Firebase.");
    }

    private IntegrationStatusSnapshot BuildFirestoreStatus()
    {
        var configured = !string.IsNullOrWhiteSpace(_firebaseOptions.ProjectId);
        return new IntegrationStatusSnapshot(
            "FIRESTORE",
            "Cloud Firestore",
            "CONFIG",
            ResolveFirebaseStatus(configured),
            configured
                ? "Persistencia no relacional preparada para preferencias y proyecciones."
                : "Falta configurar el proyecto Firebase para Firestore.");
    }

    private IntegrationStatusSnapshot BuildStorageStatus()
    {
        var configured = !string.IsNullOrWhiteSpace(_storageOptions.LocalRootPath);
        return new IntegrationStatusSnapshot(
            "DOCUMENT_STORAGE",
            "Document Storage",
            "STORAGE",
            configured ? "READY" : "MISSING",
            configured
                ? $"Ruta local configurada en {_storageOptions.LocalRootPath}."
                : "No se encontró configuración para almacenamiento documental.");
    }

    private IntegrationStatusSnapshot BuildSignatureProviderStatus()
    {
        var configured = !string.IsNullOrWhiteSpace(_signatureProviderOptions.ProviderCode);
        return new IntegrationStatusSnapshot(
            "SIGNATURE_PROVIDER",
            "Signature Provider",
            "SIGNATURE",
            configured ? _signatureProviderOptions.Mode.ToUpperInvariant() : "MISSING",
            configured
                ? $"Proveedor {_signatureProviderOptions.ProviderCode} en modo {_signatureProviderOptions.Mode}."
                : "No se configuró proveedor de firma.");
    }

    private string ResolveFirebaseStatus(bool configured)
    {
        if (!configured)
        {
            return "MISSING";
        }

        return _firebaseOptions.UseEmulator ? "EMULATOR" : "READY";
    }
}
