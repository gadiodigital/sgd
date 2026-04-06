using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Workflow;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists workflow tasks in PostgreSQL.
/// </summary>
public sealed class PostgresWorkflowTaskRepository : IWorkflowTaskRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresWorkflowTaskRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<WorkflowTask>> ListByTenantAsync(
        Guid tenantId,
        Guid? assignedToUserId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                workflow_task_id,
                tenant_id,
                document_id,
                title,
                notes,
                assigned_to_user_id,
                status,
                created_by_user_id,
                created_at_utc,
                due_at_utc,
                completed_by_user_id,
                completed_at_utc
            FROM workflow.workflow_tasks
            WHERE tenant_id = @tenant_id
              AND (CAST(@assigned_to_user_id AS uuid) IS NULL OR assigned_to_user_id = @assigned_to_user_id)
            ORDER BY
                CASE status WHEN 'OPEN' THEN 0 ELSE 1 END,
                COALESCE(due_at_utc, created_at_utc),
                created_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("assigned_to_user_id", (object?)assignedToUserId ?? DBNull.Value);
        return await ReadTasksAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<WorkflowTask?> GetByIdAsync(Guid taskId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                workflow_task_id,
                tenant_id,
                document_id,
                title,
                notes,
                assigned_to_user_id,
                status,
                created_by_user_id,
                created_at_utc,
                due_at_utc,
                completed_by_user_id,
                completed_at_utc
            FROM workflow.workflow_tasks
            WHERE workflow_task_id = @task_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("task_id", taskId);
        return (await ReadTasksAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<WorkflowTask> AddAsync(WorkflowTask task, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO workflow.workflow_tasks
                (workflow_task_id, tenant_id, document_id, title, notes, assigned_to_user_id, status, created_by_user_id, created_at_utc, due_at_utc)
            VALUES
                (@task_id, @tenant_id, @document_id, @title, @notes, @assigned_to_user_id, @status, @created_by_user_id, @created_at_utc, @due_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("task_id", task.Id);
        command.Parameters.AddWithValue("tenant_id", task.TenantId);
        command.Parameters.AddWithValue("document_id", task.DocumentId);
        command.Parameters.AddWithValue("title", task.Title);
        command.Parameters.AddWithValue("notes", (object?)task.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("assigned_to_user_id", (object?)task.AssignedToUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("status", task.Status.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("created_by_user_id", (object?)task.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", task.CreatedAtUtc);
        command.Parameters.AddWithValue("due_at_utc", (object?)task.DueAtUtc ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return task;
    }

    /// <inheritdoc />
    public async Task CompleteAsync(
        Guid tenantId,
        Guid taskId,
        Guid completedByUserId,
        DateTimeOffset completedAtUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE workflow.workflow_tasks
            SET status = 'COMPLETED',
                completed_by_user_id = @completed_by_user_id,
                completed_at_utc = @completed_at_utc
            WHERE tenant_id = @tenant_id
              AND workflow_task_id = @task_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("task_id", taskId);
        command.Parameters.AddWithValue("completed_by_user_id", completedByUserId);
        command.Parameters.AddWithValue("completed_at_utc", completedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<WorkflowTask>> ReadTasksAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<WorkflowTask>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(WorkflowTask.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetString(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetGuid(5),
                Enum.Parse<WorkflowTaskStatus>(reader.GetString(6), ignoreCase: true),
                reader.IsDBNull(7) ? null : reader.GetGuid(7),
                reader.GetFieldValue<DateTimeOffset>(8),
                reader.IsDBNull(9) ? null : reader.GetFieldValue<DateTimeOffset>(9),
                reader.IsDBNull(10) ? null : reader.GetGuid(10),
                reader.IsDBNull(11) ? null : reader.GetFieldValue<DateTimeOffset>(11)));
        }

        return result;
    }
}
