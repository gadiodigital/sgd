using Gdms.Domain.Structure;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Persists configurable document structure projects, types, hierarchy nodes and document links.
/// </summary>
public interface IDocumentStructureRepository
{
    Task<IReadOnlyCollection<StructureProject>> ListProjectsAsync(Guid tenantId, CancellationToken cancellationToken);
    Task<StructureProject?> GetProjectByIdAsync(Guid tenantId, Guid projectId, CancellationToken cancellationToken);
    Task<StructureProject> AddProjectAsync(StructureProject project, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ContainerTypeDefinition>> ListContainerTypesAsync(Guid tenantId, Guid projectId, CancellationToken cancellationToken);
    Task<ContainerTypeDefinition?> GetContainerTypeByIdAsync(Guid tenantId, Guid projectId, Guid containerTypeId, CancellationToken cancellationToken);
    Task<ContainerTypeDefinition> AddContainerTypeAsync(ContainerTypeDefinition containerType, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ContainerTypeRule>> ListContainerTypeRulesAsync(Guid tenantId, Guid projectId, CancellationToken cancellationToken);
    Task<bool> ContainerTypeRuleExistsAsync(Guid tenantId, Guid projectId, Guid parentContainerTypeId, Guid childContainerTypeId, CancellationToken cancellationToken);
    Task<ContainerTypeRule> AddContainerTypeRuleAsync(ContainerTypeRule rule, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ContainerNode>> ListContainersAsync(Guid tenantId, Guid projectId, CancellationToken cancellationToken);
    Task<ContainerNode?> GetContainerByIdAsync(Guid tenantId, Guid projectId, Guid containerId, CancellationToken cancellationToken);
    Task<ContainerNode> AddContainerAsync(ContainerNode container, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ContainerDocumentLink>> ListContainerDocumentsAsync(Guid tenantId, Guid projectId, Guid containerId, CancellationToken cancellationToken);
    Task AttachDocumentAsync(Guid tenantId, Guid projectId, Guid containerId, Guid documentId, Guid? linkedByUserId, DateTimeOffset linkedAtUtc, CancellationToken cancellationToken);
}
