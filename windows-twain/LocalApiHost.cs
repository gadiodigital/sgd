using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http.Json;
using Microsoft.Extensions.DependencyInjection;

namespace WindowsTwain;

internal sealed partial class LocalApiHost : IDisposable
{
    private const string CorsPolicyName = "ConfiguredOrigins";
    private readonly ApiOptions apiOptions;
    private readonly AppState appState;
    private readonly IScannerService scannerService;
    private readonly WebApplication webApplication;

    public LocalApiHost(ApiOptions apiOptions, AppState appState, IScannerService scannerService)
    {
        this.apiOptions = apiOptions;
        this.appState = appState;
        this.scannerService = scannerService;

        var builder = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            ApplicationName = typeof(LocalApiHost).Assembly.FullName,
            ContentRootPath = AppContext.BaseDirectory
        });

        builder.WebHost.UseUrls(apiOptions.BaseUrl);
        builder.Services.Configure<JsonOptions>(options => options.SerializerOptions.WriteIndented = true);

        if (ShouldEnableCors())
        {
            builder.Services.AddCors(options =>
            {
                options.AddPolicy(CorsPolicyName, policy =>
                {
                    policy.SetIsOriginAllowed(IsOriginAllowed)
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                });
            });
        }

        webApplication = builder.Build();

        if (ShouldEnableCors())
        {
            webApplication.UseCors(CorsPolicyName);
        }

        MapEndpoints(webApplication);
    }

    public string BaseUrl => apiOptions.BaseUrl;
    public string HealthUrl => $"{BaseUrl}/health";
    public string StatusUrl => $"{BaseUrl}/api/status";

    public Task StartAsync(CancellationToken cancellationToken) => webApplication.StartAsync(cancellationToken);
    public Task StopAsync(CancellationToken cancellationToken) => webApplication.StopAsync(cancellationToken);

    public void Dispose()
    {
        webApplication.DisposeAsync().AsTask().GetAwaiter().GetResult();
    }

    private bool ShouldEnableCors()
    {
        return apiOptions.AllowedOrigins.Length > 0 || apiOptions.AllowLoopbackOrigins;
    }

    private bool IsOriginAllowed(string? origin)
    {
        if (string.IsNullOrWhiteSpace(origin))
        {
            return false;
        }

        if (apiOptions.AllowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase))
        {
            return true;
        }

        return apiOptions.AllowLoopbackOrigins &&
            Uri.TryCreate(origin, UriKind.Absolute, out var uri) &&
            uri.IsLoopback;
    }
}
