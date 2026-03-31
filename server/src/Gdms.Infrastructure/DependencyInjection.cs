using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Abstractions.Security;
using Gdms.Application.Abstractions.Integrations;
using Gdms.Application.Abstractions.Storage;
using Gdms.Infrastructure.Configuration;
using Gdms.Infrastructure.Integrations;
using Gdms.Infrastructure.Persistence;
using Gdms.Infrastructure.Security;
using Gdms.Infrastructure.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Npgsql;

namespace Gdms.Infrastructure;

/// <summary>
/// Registers infrastructure services and adapters.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds infrastructure adapters to the service collection.
    /// </summary>
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<PostgresOptions>(configuration.GetSection("Postgres"));
        services.Configure<FirebaseOptions>(configuration.GetSection("Firebase"));
        services.Configure<JwtOptions>(configuration.GetSection("Jwt"));
        services.Configure<SignatureProviderOptions>(configuration.GetSection("SignatureProvider"));
        services.Configure<StorageOptions>(configuration.GetSection("Storage"));

        services.AddSingleton(static serviceProvider =>
        {
            var options = serviceProvider.GetRequiredService<IOptions<PostgresOptions>>().Value;
            if (string.IsNullOrWhiteSpace(options.MainDatabase))
            {
                throw new InvalidOperationException("La cadena de conexión principal de PostgreSQL es obligatoria.");
            }

            var builder = new NpgsqlDataSourceBuilder(options.MainDatabase);
            return builder.Build();
        });

        services.AddScoped<ITenantRepository, PostgresTenantRepository>();
        services.AddScoped<ICaseFileRepository, PostgresCaseFileRepository>();
        services.AddScoped<ICorporateRecordFileRepository, PostgresCorporateRecordFileRepository>();
        services.AddScoped<IDocumentRepository, PostgresDocumentRepository>();
        services.AddScoped<IDocumentAccessRepository, PostgresDocumentAccessRepository>();
        services.AddScoped<IPropertyFileRepository, PostgresPropertyFileRepository>();
        services.AddScoped<IDocumentSearchRepository, PostgresDocumentSearchRepository>();
        services.AddScoped<IDocumentTypeRepository, PostgresDocumentTypeRepository>();
        services.AddScoped<IDocumentMetadataRepository, PostgresDocumentMetadataRepository>();
        services.AddScoped<IDocumentDispositionRepository, PostgresDocumentDispositionRepository>();
        services.AddScoped<IAuditEventRepository, PostgresAuditEventRepository>();
        services.AddScoped<IRetentionPolicyRepository, PostgresRetentionPolicyRepository>();
        services.AddScoped<ILegalHoldRepository, PostgresLegalHoldRepository>();
        services.AddScoped<ISignatureEnvelopeRepository, PostgresSignatureEnvelopeRepository>();
        services.AddScoped<IWorkflowTaskRepository, PostgresWorkflowTaskRepository>();
        services.AddScoped<IRoleRepository, PostgresRoleRepository>();
        services.AddScoped<IUserRepository, PostgresUserRepository>();
        services.AddScoped<IUserCredentialRepository, PostgresUserCredentialRepository>();
        services.AddSingleton<IIntegrationStatusCatalogProvider, ConfiguredIntegrationStatusCatalogProvider>();
        services.AddSingleton<ISignatureProviderGateway, InternalSignatureProviderGateway>();
        services.AddSingleton<IDocumentBinaryStore, LocalFileDocumentBinaryStore>();
        services.AddSingleton<JwtSigningKeyProvider>();
        services.AddSingleton<IPasswordHashingService, LocalPasswordHashingService>();
        services.AddSingleton<IAccessTokenIssuer, JwtAccessTokenIssuer>();

        return services;
    }
}
