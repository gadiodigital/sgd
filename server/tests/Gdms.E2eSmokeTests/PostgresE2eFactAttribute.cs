namespace Gdms.E2eSmokeTests;

public sealed class PostgresE2eFactAttribute : FactAttribute
{
    public const string ConnectionStringVariableName = "GDMS_TEST_POSTGRES_CONNECTION";

    public PostgresE2eFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(ConnectionStringVariableName)))
        {
            Skip = $"Set {ConnectionStringVariableName} para ejecutar los e2e smoke tests con PostgreSQL.";
        }
    }
}
