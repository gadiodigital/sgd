using System.Reflection;

namespace Gdms.IntegrationTests;

public sealed class PostgresIntegrationDatabaseFixture : IAsyncLifetime
{
    private NpgsqlDataSource? _dataSource;

    public NpgsqlDataSource DataSource => _dataSource
        ?? throw new InvalidOperationException("La base efimera de integration tests no fue inicializada.");

    public string DatabaseName { get; private set; } = string.Empty;

    public async Task InitializeAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable(PostgresIntegrationFactAttribute.ConnectionStringVariableName);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return;
        }

        var adminBuilder = new NpgsqlConnectionStringBuilder(connectionString)
        {
            Database = "postgres"
        };

        DatabaseName = $"gdms_it_{Guid.NewGuid():N}";
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

        _dataSource = NpgsqlDataSource.Create(testBuilder.ConnectionString);
        await ApplyDatabaseScriptsAsync();
    }

    public async Task DisposeAsync()
    {
        if (_dataSource is not null)
        {
            await _dataSource.DisposeAsync();
        }

        if (string.IsNullOrWhiteSpace(DatabaseName))
        {
            return;
        }

        var connectionString = Environment.GetEnvironmentVariable(PostgresIntegrationFactAttribute.ConnectionStringVariableName);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return;
        }

        var adminBuilder = new NpgsqlConnectionStringBuilder(connectionString)
        {
            Database = "postgres"
        };

        await using var adminConnection = new NpgsqlConnection(adminBuilder.ConnectionString);
        await adminConnection.OpenAsync();

        var terminateSql = """
            SELECT pg_terminate_backend(pid)
            FROM pg_stat_activity
            WHERE datname = @database_name
              AND pid <> pg_backend_pid();
            """;

        await using (var terminateCommand = new NpgsqlCommand(terminateSql, adminConnection))
        {
            terminateCommand.Parameters.AddWithValue("database_name", DatabaseName);
            await terminateCommand.ExecuteNonQueryAsync();
        }

        await using var dropCommand = new NpgsqlCommand($"DROP DATABASE IF EXISTS \"{DatabaseName}\";", adminConnection);
        await dropCommand.ExecuteNonQueryAsync();
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
