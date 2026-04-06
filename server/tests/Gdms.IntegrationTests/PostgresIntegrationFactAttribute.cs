namespace Gdms.IntegrationTests;

public sealed class PostgresIntegrationFactAttribute : FactAttribute
{
    public const string ConnectionStringVariableName = "GDMS_TEST_POSTGRES_CONNECTION";

    public PostgresIntegrationFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(ConnectionStringVariableName)))
        {
            Skip = $"Definir {ConnectionStringVariableName} para ejecutar integration tests contra PostgreSQL.";
        }
    }
}
