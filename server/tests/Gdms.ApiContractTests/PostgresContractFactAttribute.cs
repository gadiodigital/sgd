namespace Gdms.ApiContractTests;

public sealed class PostgresContractFactAttribute : FactAttribute
{
    public const string ConnectionStringVariableName = "GDMS_TEST_POSTGRES_CONNECTION";

    public PostgresContractFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(ConnectionStringVariableName)))
        {
            Skip = $"Definir {ConnectionStringVariableName} para ejecutar contract tests contra PostgreSQL.";
        }
    }
}
