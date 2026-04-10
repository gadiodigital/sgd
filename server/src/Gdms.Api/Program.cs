using Gdms.Application;
using Gdms.Api.Configuration;
using Gdms.Api.Infrastructure;
using Gdms.Infrastructure.Configuration;
using Gdms.Infrastructure;
using Gdms.Infrastructure.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi.Models;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);
var corsOptions = builder.Configuration.GetSection("Cors").Get<CorsOptions>() ?? new CorsOptions();
var apiRuntimeOptions = builder.Configuration.GetSection("ApiRuntime").Get<ApiRuntimeOptions>() ?? new ApiRuntimeOptions();

builder.Services.AddExceptionHandler<DomainExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer();
builder.Services.AddAuthorization();
builder.Services.AddCors(options =>
{
    options.AddPolicy(corsOptions.PolicyName, policyBuilder =>
    {
        if (builder.Environment.IsDevelopment() && corsOptions.AllowAnyOriginInDevelopment)
        {
            policyBuilder.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
            return;
        }

        if (corsOptions.AllowedOrigins.Length > 0)
        {
            policyBuilder
                .WithOrigins(corsOptions.AllowedOrigins)
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
    });
});
builder.Services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
    .Configure<JwtSigningKeyProvider, IOptions<JwtOptions>>((options, keyProvider, jwtOptionsAccessor) =>
    {
        var jwtOptions = jwtOptionsAccessor.Value;
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidAudience = jwtOptions.Audience,
            IssuerSigningKey = keyProvider.SecurityKey,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "GDMS API",
        Version = "v1",
        Description = "API base del sistema de gestión documental argentino con foco en tenants y documentos."
    });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Bearer token JWT emitido por /api/auth/token",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            []
        }
    });

    foreach (var xmlPath in Directory.GetFiles(AppContext.BaseDirectory, "*.xml"))
    {
        options.IncludeXmlComments(xmlPath, includeControllerXmlComments: true);
    }
});

var app = builder.Build();

app.UseExceptionHandler();
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.DocumentTitle = "GDMS API";
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "GDMS API v1");
});

if (apiRuntimeOptions.EnableHttpsRedirection)
{
    app.UseHttpsRedirection();
}
app.UseCors(corsOptions.PolicyName);
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => Results.Redirect("/swagger"))
    .ExcludeFromDescription();
app.MapControllers();

app.Run();

public partial class Program;
