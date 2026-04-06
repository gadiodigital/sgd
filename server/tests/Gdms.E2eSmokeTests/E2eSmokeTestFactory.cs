namespace Gdms.E2eSmokeTests;

public sealed class E2eSmokeTestFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private NpgsqlDataSource? _dataSource;
    private string _databaseConnectionString = string.Empty;
    private string _storageRootPath = string.Empty;

    public NpgsqlDataSource DataSource => _dataSource
        ?? throw new InvalidOperationException("La base efimera de e2e smoke tests no fue inicializada.");

    public string DatabaseName { get; private set; } = string.Empty;

    public async Task InitializeAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable(PostgresE2eFactAttribute.ConnectionStringVariableName);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return;
        }

        var adminBuilder = new NpgsqlConnectionStringBuilder(connectionString)
        {
            Database = "postgres"
        };

        DatabaseName = $"gdms_e2e_{Guid.NewGuid():N}";
        await using (var adminConnection = new NpgsqlConnection(adminBuilder.ConnectionString))
        {
            await adminConnection.OpenAsync();
            await using var createCommand = new NpgsqlCommand($"CREATE DATABASE \"{DatabaseName}\";", adminConnection);
            await createCommand.ExecuteNonQueryAsync();
        }

        var testBuilder = new NpgsqlConnectionStringBuilder(connectionString)
        {
            Database = DatabaseName
        };

        _databaseConnectionString = testBuilder.ConnectionString;
        _dataSource = NpgsqlDataSource.Create(_databaseConnectionString);
        _storageRootPath = Path.Combine(Path.GetTempPath(), DatabaseName, "storage");
        Directory.CreateDirectory(_storageRootPath);
        await ApplyDatabaseScriptsAsync();
    }

    public new async Task DisposeAsync()
    {
        if (_dataSource is not null)
        {
            await _dataSource.DisposeAsync();
        }

        if (Directory.Exists(_storageRootPath))
        {
            Directory.Delete(_storageRootPath, recursive: true);
        }

        if (!string.IsNullOrWhiteSpace(DatabaseName))
        {
            var connectionString = Environment.GetEnvironmentVariable(PostgresE2eFactAttribute.ConnectionStringVariableName);
            if (!string.IsNullOrWhiteSpace(connectionString))
            {
                var adminBuilder = new NpgsqlConnectionStringBuilder(connectionString)
                {
                    Database = "postgres"
                };

                await using var adminConnection = new NpgsqlConnection(adminBuilder.ConnectionString);
                await adminConnection.OpenAsync();

                await using (var terminateCommand = new NpgsqlCommand(
                    """
                    SELECT pg_terminate_backend(pid)
                    FROM pg_stat_activity
                    WHERE datname = @database_name
                      AND pid <> pg_backend_pid();
                    """,
                    adminConnection))
                {
                    terminateCommand.Parameters.AddWithValue("database_name", DatabaseName);
                    await terminateCommand.ExecuteNonQueryAsync();
                }

                await using var dropCommand = new NpgsqlCommand($"DROP DATABASE IF EXISTS \"{DatabaseName}\";", adminConnection);
                await dropCommand.ExecuteNonQueryAsync();
            }
        }

        await base.DisposeAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.ConfigureAppConfiguration((_, configurationBuilder) =>
        {
            configurationBuilder.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Postgres:MainDatabase"] = BuildDatabaseConnectionString(),
                ["Jwt:Issuer"] = "gdms-e2e-tests",
                ["Jwt:Audience"] = "gdms-e2e-clients",
                ["Jwt:SigningKey"] = "abcdefghijklmnopqrstuvwxyz1234567890",
                ["Storage:LocalRootPath"] = _storageRootPath,
                ["SignatureProvider:Mode"] = "INTERNAL",
                ["SignatureProvider:ProviderCode"] = "INTERNAL",
                ["SignatureProvider:GenerateReferences"] = "true"
            });
        });
    }

    private string BuildDatabaseConnectionString()
    {
        if (string.IsNullOrWhiteSpace(_databaseConnectionString))
        {
            throw new InvalidOperationException("La base efimera todavía no fue creada.");
        }

        return _databaseConnectionString;
    }

    private async Task ApplyDatabaseScriptsAsync()
    {
        var scriptsPath = ResolveDatabaseScriptsPath();
        foreach (var scriptPath in Directory.GetFiles(scriptsPath, "*.sql").OrderBy(path => path, StringComparer.OrdinalIgnoreCase))
        {
            var sql = await File.ReadAllTextAsync(scriptPath);
            await using var command = DataSource.CreateCommand(sql);
            await command.ExecuteNonQueryAsync();
        }
    }

    private static string ResolveDatabaseScriptsPath()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            var candidate = Path.Combine(current.FullName, "database", "scripts");
            if (Directory.Exists(candidate))
            {
                return candidate;
            }

            current = current.Parent;
        }

        throw new DirectoryNotFoundException(
            $"No se pudo resolver la carpeta database/scripts desde {Assembly.GetExecutingAssembly().Location}.");
    }
}
