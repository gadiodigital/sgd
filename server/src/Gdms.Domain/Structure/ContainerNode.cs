using Gdms.Domain.Common;

namespace Gdms.Domain.Structure;

/// <summary>
/// Concrete node inside a configurable document tree.
/// </summary>
public sealed class ContainerNode
{
    private ContainerNode(
        Guid id,
        Guid tenantId,
        Guid projectId,
        Guid containerTypeId,
        Guid? parentContainerId,
        string code,
        string name,
        string metadataJson,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        ProjectId = projectId;
        ContainerTypeId = containerTypeId;
        ParentContainerId = parentContainerId;
        Code = code;
        Name = name;
        MetadataJson = metadataJson;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public Guid ProjectId { get; }
    public Guid ContainerTypeId { get; }
    public Guid? ParentContainerId { get; }
    public string Code { get; }
    public string Name { get; }
    public string MetadataJson { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    public static ContainerNode Create(
        Guid tenantId,
        Guid projectId,
        Guid containerTypeId,
        Guid? parentContainerId,
        string code,
        string name,
        string metadataJson,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty || projectId == Guid.Empty || containerTypeId == Guid.Empty)
        {
            throw new DomainRuleException("Tenant, proyecto y tipo son obligatorios para crear un nodo.");
        }

        return new ContainerNode(
            Guid.NewGuid(),
            tenantId,
            projectId,
            containerTypeId,
            parentContainerId,
            StructureProject.NormalizeCode(code, "El código del nodo es obligatorio.", 80),
            StructureProject.RequireText(name, "El nombre del nodo es obligatorio.", 180),
            string.IsNullOrWhiteSpace(metadataJson) ? "{}" : metadataJson,
            createdByUserId,
            createdAtUtc);
    }

    public static ContainerNode Rehydrate(
        Guid id,
        Guid tenantId,
        Guid projectId,
        Guid containerTypeId,
        Guid? parentContainerId,
        string code,
        string name,
        string metadataJson,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new ContainerNode(
            id,
            tenantId,
            projectId,
            containerTypeId,
            parentContainerId,
            code,
            name,
            metadataJson,
            createdByUserId,
            createdAtUtc);
    }
}
