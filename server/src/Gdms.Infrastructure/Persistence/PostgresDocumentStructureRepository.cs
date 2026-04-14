using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Structure;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists configurable document structures in PostgreSQL.
/// </summary>
public sealed class PostgresDocumentStructureRepository : IDocumentStructureRepository
{
    private readonly NpgsqlDataSource _dataSource;

    public PostgresDocumentStructureRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    public async Task<IReadOnlyCollection<StructureProject>> ListProjectsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT project_id, tenant_id, code, name, description, status, created_by_user_id, created_at_utc
            FROM documents.projects
            WHERE tenant_id = @tenant_id
            ORDER BY created_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadProjectsAsync(command, cancellationToken);
    }

    public async Task<StructureProject?> GetProjectByIdAsync(Guid tenantId, Guid projectId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT project_id, tenant_id, code, name, description, status, created_by_user_id, created_at_utc
            FROM documents.projects
            WHERE tenant_id = @tenant_id
              AND project_id = @project_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        return (await ReadProjectsAsync(command, cancellationToken)).SingleOrDefault();
    }

    public async Task<StructureProject> AddProjectAsync(StructureProject project, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.projects
                (project_id, tenant_id, code, name, description, status, created_by_user_id, created_at_utc)
            VALUES
                (@project_id, @tenant_id, @code, @name, @description, @status, @created_by_user_id, @created_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("project_id", project.Id);
        command.Parameters.AddWithValue("tenant_id", project.TenantId);
        command.Parameters.AddWithValue("code", project.Code);
        command.Parameters.AddWithValue("name", project.Name);
        command.Parameters.AddWithValue("description", (object?)project.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("status", project.Status.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("created_by_user_id", (object?)project.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", project.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return project;
    }

    public async Task<IReadOnlyCollection<ContainerTypeDefinition>> ListContainerTypesAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT container_type_id, tenant_id, project_id, code, name, icon_key, is_root_allowed,
                   accepts_documents, metadata_schema::text, created_by_user_id, created_at_utc
            FROM configuration.container_types
            WHERE tenant_id = @tenant_id
              AND project_id = @project_id
            ORDER BY code;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        return await ReadContainerTypesAsync(command, cancellationToken);
    }

    public async Task<ContainerTypeDefinition?> GetContainerTypeByIdAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerTypeId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT container_type_id, tenant_id, project_id, code, name, icon_key, is_root_allowed,
                   accepts_documents, metadata_schema::text, created_by_user_id, created_at_utc
            FROM configuration.container_types
            WHERE tenant_id = @tenant_id
              AND project_id = @project_id
              AND container_type_id = @container_type_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        command.Parameters.AddWithValue("container_type_id", containerTypeId);
        return (await ReadContainerTypesAsync(command, cancellationToken)).SingleOrDefault();
    }

    public async Task<ContainerTypeDefinition> AddContainerTypeAsync(
        ContainerTypeDefinition containerType,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO configuration.container_types
                (container_type_id, tenant_id, project_id, code, name, icon_key, is_root_allowed,
                 accepts_documents, metadata_schema, created_by_user_id, created_at_utc)
            VALUES
                (@container_type_id, @tenant_id, @project_id, @code, @name, @icon_key, @is_root_allowed,
                 @accepts_documents, CAST(@metadata_schema AS jsonb), @created_by_user_id, @created_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("container_type_id", containerType.Id);
        command.Parameters.AddWithValue("tenant_id", containerType.TenantId);
        command.Parameters.AddWithValue("project_id", containerType.ProjectId);
        command.Parameters.AddWithValue("code", containerType.Code);
        command.Parameters.AddWithValue("name", containerType.Name);
        command.Parameters.AddWithValue("icon_key", containerType.IconKey);
        command.Parameters.AddWithValue("is_root_allowed", containerType.IsRootAllowed);
        command.Parameters.AddWithValue("accepts_documents", containerType.AcceptsDocuments);
        command.Parameters.AddWithValue("metadata_schema", containerType.MetadataSchemaJson);
        command.Parameters.AddWithValue("created_by_user_id", (object?)containerType.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", containerType.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return containerType;
    }

    public async Task<IReadOnlyCollection<ContainerTypeRule>> ListContainerTypeRulesAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT container_type_rule_id, tenant_id, project_id, parent_container_type_id,
                   child_container_type_id, created_by_user_id, created_at_utc
            FROM configuration.container_type_rules
            WHERE tenant_id = @tenant_id
              AND project_id = @project_id
            ORDER BY created_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        return await ReadContainerTypeRulesAsync(command, cancellationToken);
    }

    public async Task<bool> ContainerTypeRuleExistsAsync(
        Guid tenantId,
        Guid projectId,
        Guid parentContainerTypeId,
        Guid childContainerTypeId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT EXISTS (
                SELECT 1
                FROM configuration.container_type_rules
                WHERE tenant_id = @tenant_id
                  AND project_id = @project_id
                  AND parent_container_type_id = @parent_container_type_id
                  AND child_container_type_id = @child_container_type_id);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        command.Parameters.AddWithValue("parent_container_type_id", parentContainerTypeId);
        command.Parameters.AddWithValue("child_container_type_id", childContainerTypeId);
        return (bool)(await command.ExecuteScalarAsync(cancellationToken) ?? false);
    }

    public async Task<ContainerTypeRule> AddContainerTypeRuleAsync(
        ContainerTypeRule rule,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO configuration.container_type_rules
                (container_type_rule_id, tenant_id, project_id, parent_container_type_id,
                 child_container_type_id, created_by_user_id, created_at_utc)
            VALUES
                (@container_type_rule_id, @tenant_id, @project_id, @parent_container_type_id,
                 @child_container_type_id, @created_by_user_id, @created_at_utc)
            ON CONFLICT (project_id, parent_container_type_id, child_container_type_id) DO NOTHING;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("container_type_rule_id", rule.Id);
        command.Parameters.AddWithValue("tenant_id", rule.TenantId);
        command.Parameters.AddWithValue("project_id", rule.ProjectId);
        command.Parameters.AddWithValue("parent_container_type_id", rule.ParentContainerTypeId);
        command.Parameters.AddWithValue("child_container_type_id", rule.ChildContainerTypeId);
        command.Parameters.AddWithValue("created_by_user_id", (object?)rule.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", rule.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return rule;
    }

    public async Task<IReadOnlyCollection<ContainerNode>> ListContainersAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT container_id, tenant_id, project_id, container_type_id, parent_container_id,
                   code, name, metadata::text, created_by_user_id, created_at_utc
            FROM documents.containers
            WHERE tenant_id = @tenant_id
              AND project_id = @project_id
            ORDER BY parent_container_id NULLS FIRST, code;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        return await ReadContainersAsync(command, cancellationToken);
    }

    public async Task<ContainerNode?> GetContainerByIdAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT container_id, tenant_id, project_id, container_type_id, parent_container_id,
                   code, name, metadata::text, created_by_user_id, created_at_utc
            FROM documents.containers
            WHERE tenant_id = @tenant_id
              AND project_id = @project_id
              AND container_id = @container_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        command.Parameters.AddWithValue("container_id", containerId);
        return (await ReadContainersAsync(command, cancellationToken)).SingleOrDefault();
    }

    public async Task<ContainerNode> AddContainerAsync(ContainerNode container, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.containers
                (container_id, tenant_id, project_id, container_type_id, parent_container_id,
                 code, name, metadata, created_by_user_id, created_at_utc)
            VALUES
                (@container_id, @tenant_id, @project_id, @container_type_id, @parent_container_id,
                 @code, @name, CAST(@metadata AS jsonb), @created_by_user_id, @created_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("container_id", container.Id);
        command.Parameters.AddWithValue("tenant_id", container.TenantId);
        command.Parameters.AddWithValue("project_id", container.ProjectId);
        command.Parameters.AddWithValue("container_type_id", container.ContainerTypeId);
        command.Parameters.AddWithValue("parent_container_id", (object?)container.ParentContainerId ?? DBNull.Value);
        command.Parameters.AddWithValue("code", container.Code);
        command.Parameters.AddWithValue("name", container.Name);
        command.Parameters.AddWithValue("metadata", container.MetadataJson);
        command.Parameters.AddWithValue("created_by_user_id", (object?)container.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", container.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return container;
    }

    public async Task<IReadOnlyCollection<ContainerDocumentLink>> ListContainerDocumentsAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                cd.container_id,
                cd.document_id,
                d.tenant_id,
                d.title,
                dt.code,
                d.status,
                cd.linked_at_utc,
                cd.linked_by_user_id
            FROM documents.container_documents cd
            INNER JOIN documents.documents d ON d.document_id = cd.document_id
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            WHERE cd.tenant_id = @tenant_id
              AND cd.project_id = @project_id
              AND cd.container_id = @container_id
            ORDER BY cd.linked_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        command.Parameters.AddWithValue("container_id", containerId);
        return await ReadContainerDocumentsAsync(command, cancellationToken);
    }

    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.container_documents
                (container_document_id, tenant_id, project_id, container_id, document_id, linked_by_user_id, linked_at_utc)
            VALUES
                (@container_document_id, @tenant_id, @project_id, @container_id, @document_id, @linked_by_user_id, @linked_at_utc)
            ON CONFLICT (container_id, document_id) DO NOTHING;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("container_document_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("project_id", projectId);
        command.Parameters.AddWithValue("container_id", containerId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("linked_by_user_id", (object?)linkedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("linked_at_utc", linkedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<StructureProject>> ReadProjectsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<StructureProject>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(StructureProject.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                Enum.Parse<StructureProjectStatus>(reader.GetString(5), ignoreCase: true),
                reader.IsDBNull(6) ? null : reader.GetGuid(6),
                reader.GetFieldValue<DateTimeOffset>(7)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<ContainerTypeDefinition>> ReadContainerTypesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<ContainerTypeDefinition>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(ContainerTypeDefinition.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                reader.GetBoolean(6),
                reader.GetBoolean(7),
                reader.GetString(8),
                reader.IsDBNull(9) ? null : reader.GetGuid(9),
                reader.GetFieldValue<DateTimeOffset>(10)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<ContainerTypeRule>> ReadContainerTypeRulesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<ContainerTypeRule>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(ContainerTypeRule.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetGuid(3),
                reader.GetGuid(4),
                reader.IsDBNull(5) ? null : reader.GetGuid(5),
                reader.GetFieldValue<DateTimeOffset>(6)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<ContainerNode>> ReadContainersAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<ContainerNode>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(ContainerNode.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetGuid(3),
                reader.IsDBNull(4) ? null : reader.GetGuid(4),
                reader.GetString(5),
                reader.GetString(6),
                reader.GetString(7),
                reader.IsDBNull(8) ? null : reader.GetGuid(8),
                reader.GetFieldValue<DateTimeOffset>(9)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<ContainerDocumentLink>> ReadContainerDocumentsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<ContainerDocumentLink>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(ContainerDocumentLink.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                reader.GetFieldValue<DateTimeOffset>(6),
                reader.IsDBNull(7) ? null : reader.GetGuid(7)));
        }

        return result;
    }
}
