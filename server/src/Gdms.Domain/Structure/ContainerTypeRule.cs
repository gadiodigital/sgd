using Gdms.Domain.Common;

namespace Gdms.Domain.Structure;

/// <summary>
/// Allowed parent-child relation between two container types.
/// </summary>
public sealed class ContainerTypeRule
{
    private ContainerTypeRule(
        Guid id,
        Guid tenantId,
        Guid projectId,
        Guid parentContainerTypeId,
        Guid childContainerTypeId,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        ProjectId = projectId;
        ParentContainerTypeId = parentContainerTypeId;
        ChildContainerTypeId = childContainerTypeId;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public Guid ProjectId { get; }
    public Guid ParentContainerTypeId { get; }
    public Guid ChildContainerTypeId { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    public static ContainerTypeRule Create(
        Guid tenantId,
        Guid projectId,
        Guid parentContainerTypeId,
        Guid childContainerTypeId,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty || projectId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant y el proyecto son obligatorios para crear una regla.");
        }

        if (parentContainerTypeId == Guid.Empty || childContainerTypeId == Guid.Empty)
        {
            throw new DomainRuleException("Los tipos padre e hijo son obligatorios para crear una regla.");
        }

        if (parentContainerTypeId == childContainerTypeId)
        {
            throw new DomainRuleException("Una regla de contenedor no puede apuntar al mismo tipo como padre e hijo.");
        }

        return new ContainerTypeRule(
            Guid.NewGuid(),
            tenantId,
            projectId,
            parentContainerTypeId,
            childContainerTypeId,
            createdByUserId,
            createdAtUtc);
    }

    public static ContainerTypeRule Rehydrate(
        Guid id,
        Guid tenantId,
        Guid projectId,
        Guid parentContainerTypeId,
        Guid childContainerTypeId,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new ContainerTypeRule(
            id,
            tenantId,
            projectId,
            parentContainerTypeId,
            childContainerTypeId,
            createdByUserId,
            createdAtUtc);
    }
}
