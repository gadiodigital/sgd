using Gdms.Application.Documents;
using Gdms.Application.Evidence;
using Gdms.Application.Identity;
using Gdms.Application.Records;
using Gdms.Application.Tenants;
using Gdms.Application.Audit;
using Gdms.Application.Cases;
using Gdms.Application.Integrations;
using Gdms.Application.Notifications;
using Gdms.Application.Reports;
using Gdms.Application.RealEstate;
using Gdms.Application.Signatures;
using Gdms.Application.Corporate;
using Gdms.Application.Workflow;
using Microsoft.Extensions.DependencyInjection;

namespace Gdms.Application;

/// <summary>
/// Registers application use cases and coordinators.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds application services to the service collection.
    /// </summary>
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<AuditEventService>();
        services.AddScoped<CaseFileService>();
        services.AddScoped<TenantService>();
        services.AddScoped<DocumentService>();
        services.AddScoped<DocumentContentService>();
        services.AddScoped<DocumentAccessService>();
        services.AddScoped<DocumentEvidencePackageService>();
        services.AddScoped<DocumentTypeCatalogService>();
        services.AddScoped<DocumentMetadataService>();
        services.AddScoped<DocumentMetadataSchemaValidator>();
        services.AddScoped<IntegrationsService>();
        services.AddScoped<RoleService>();
        services.AddScoped<UserService>();
        services.AddScoped<AuthService>();
        services.AddScoped<RecordsService>();
        services.AddScoped<NotificationsService>();
        services.AddScoped<ReportsService>();
        services.AddScoped<PropertyFileService>();
        services.AddScoped<CorporateRecordFileService>();
        services.AddScoped<SignatureService>();
        services.AddScoped<WorkflowService>();
        return services;
    }
}
