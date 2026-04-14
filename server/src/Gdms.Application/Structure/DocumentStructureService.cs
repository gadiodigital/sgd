using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Structure;

namespace Gdms.Application.Structure;

/// <summary>
/// Coordinates configurable document structure use cases.
/// </summary>
public sealed class DocumentStructureService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly IDocumentStructureRepository _structureRepository;
    private readonly StructureMetadataSchemaValidator _metadataSchemaValidator;
    private readonly ITenantRepository _tenantRepository;

    public DocumentStructureService(
        IDocumentStructureRepository structureRepository,
        IDocumentRepository documentRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository,
        StructureMetadataSchemaValidator metadataSchemaValidator)
    {
        _structureRepository = structureRepository;
        _documentRepository = documentRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
        _metadataSchemaValidator = metadataSchemaValidator;
    }

    public async Task<IReadOnlyCollection<StructureProject>> ListProjectsAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _structureRepository.ListProjectsAsync(tenantId, cancellationToken);
    }

    public async Task<StructureProject> CreateProjectAsync(
        Guid tenantId,
        string code,
        string name,
        string? description,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var project = StructureProject.Create(
            tenantId,
            code,
            name,
            description,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persisted = await _structureRepository.AddProjectAsync(project, cancellationToken);

        await WriteAuditAsync(tenantId, actorUserId, "STRUCTURE_PROJECT_CREATED", new
        {
            persisted.Id,
            persisted.Code,
            persisted.Name
        }, cancellationToken);

        return persisted;
    }

    public async Task<IReadOnlyCollection<ContainerTypeDefinition>> ListContainerTypesAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        return await _structureRepository.ListContainerTypesAsync(tenantId, projectId, cancellationToken);
    }

    public async Task<ContainerTypeDefinition> CreateContainerTypeAsync(
        Guid tenantId,
        Guid projectId,
        string code,
        string name,
        string? iconKey,
        bool isRootAllowed,
        bool acceptsDocuments,
        string? metadataSchemaJson,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        var normalizedSchema = _metadataSchemaValidator.NormalizeSchema(metadataSchemaJson);
        var containerType = ContainerTypeDefinition.Create(
            tenantId,
            projectId,
            code,
            name,
            iconKey,
            isRootAllowed,
            acceptsDocuments,
            normalizedSchema,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persisted = await _structureRepository.AddContainerTypeAsync(containerType, cancellationToken);

        await WriteAuditAsync(tenantId, actorUserId, "STRUCTURE_CONTAINER_TYPE_CREATED", new
        {
            ProjectId = projectId,
            persisted.Id,
            persisted.Code,
            persisted.Name,
            persisted.IsRootAllowed,
            persisted.AcceptsDocuments
        }, cancellationToken);

        return persisted;
    }

    public async Task<IReadOnlyCollection<ContainerTypeRule>> ListContainerTypeRulesAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        return await _structureRepository.ListContainerTypeRulesAsync(tenantId, projectId, cancellationToken);
    }

    public async Task<ContainerTypeRule> CreateContainerTypeRuleAsync(
        Guid tenantId,
        Guid projectId,
        Guid parentContainerTypeId,
        Guid childContainerTypeId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        await EnsureContainerTypeExistsAsync(tenantId, projectId, parentContainerTypeId, cancellationToken);
        await EnsureContainerTypeExistsAsync(tenantId, projectId, childContainerTypeId, cancellationToken);

        var rule = ContainerTypeRule.Create(
            tenantId,
            projectId,
            parentContainerTypeId,
            childContainerTypeId,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persisted = await _structureRepository.AddContainerTypeRuleAsync(rule, cancellationToken);

        await WriteAuditAsync(tenantId, actorUserId, "STRUCTURE_CONTAINER_TYPE_RULE_CREATED", new
        {
            ProjectId = projectId,
            persisted.ParentContainerTypeId,
            persisted.ChildContainerTypeId
        }, cancellationToken);

        return persisted;
    }

    public async Task<IReadOnlyCollection<ContainerNode>> ListContainersAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        return await _structureRepository.ListContainersAsync(tenantId, projectId, cancellationToken);
    }

    public async Task<ContainerNode> CreateContainerAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerTypeId,
        Guid? parentContainerId,
        string code,
        string name,
        string? metadataJson,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        var containerType = await EnsureContainerTypeExistsAsync(tenantId, projectId, containerTypeId, cancellationToken);
        if (parentContainerId is null)
        {
            if (!containerType.IsRootAllowed)
            {
                throw new DomainRuleException("El tipo de contenedor no puede crearse como raíz.");
            }
        }
        else
        {
            var parent = await EnsureContainerExistsAsync(tenantId, projectId, parentContainerId.Value, cancellationToken);
            var ruleExists = await _structureRepository.ContainerTypeRuleExistsAsync(
                tenantId,
                projectId,
                parent.ContainerTypeId,
                containerTypeId,
                cancellationToken);
            if (!ruleExists)
            {
                throw new DomainRuleException("La relación padre-hijo no está permitida por el proyecto.");
            }
        }

        var normalizedMetadata = _metadataSchemaValidator.NormalizeMetadata(
            metadataJson,
            new ContainerTypeDefinitionView(containerType.Code, containerType.MetadataSchemaJson));
        var container = ContainerNode.Create(
            tenantId,
            projectId,
            containerTypeId,
            parentContainerId,
            code,
            name,
            normalizedMetadata,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persisted = await _structureRepository.AddContainerAsync(container, cancellationToken);

        await WriteAuditAsync(tenantId, actorUserId, "STRUCTURE_CONTAINER_CREATED", new
        {
            ProjectId = projectId,
            persisted.Id,
            persisted.Code,
            persisted.Name,
            persisted.ParentContainerId
        }, cancellationToken);

        return persisted;
    }

    public async Task<IReadOnlyCollection<ContainerDocumentLink>> ListContainerDocumentsAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        CancellationToken cancellationToken)
    {
        await EnsureContainerExistsAsync(tenantId, projectId, containerId, cancellationToken);
        return await _structureRepository.ListContainerDocumentsAsync(tenantId, projectId, containerId, cancellationToken);
    }

    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        Guid documentId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var container = await EnsureContainerExistsAsync(tenantId, projectId, containerId, cancellationToken);
        var containerType = await EnsureContainerTypeExistsAsync(tenantId, projectId, container.ContainerTypeId, cancellationToken);
        if (!containerType.AcceptsDocuments)
        {
            throw new DomainRuleException("El contenedor informado no acepta documentos.");
        }

        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant.");
        }

        await _structureRepository.AttachDocumentAsync(
            tenantId,
            projectId,
            containerId,
            documentId,
            actorUserId,
            DateTimeOffset.UtcNow,
            cancellationToken);

        await WriteAuditAsync(tenantId, actorUserId, "STRUCTURE_CONTAINER_DOCUMENT_ATTACHED", new
        {
            ProjectId = projectId,
            ContainerId = containerId,
            DocumentId = documentId,
            document.Title
        }, cancellationToken);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para estructura documental.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para estructura documental.");
        }
    }

    private async Task<StructureProject> EnsureProjectExistsAsync(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        if (projectId == Guid.Empty)
        {
            throw new DomainRuleException("El proyecto documental informado es obligatorio.");
        }

        var project = await _structureRepository.GetProjectByIdAsync(tenantId, projectId, cancellationToken);
        if (project is null)
        {
            throw new DomainRuleException("No existe el proyecto documental informado para el tenant.");
        }

        return project;
    }

    private async Task<ContainerTypeDefinition> EnsureContainerTypeExistsAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerTypeId,
        CancellationToken cancellationToken)
    {
        if (containerTypeId == Guid.Empty)
        {
            throw new DomainRuleException("El tipo de contenedor informado es obligatorio.");
        }

        var containerType = await _structureRepository.GetContainerTypeByIdAsync(
            tenantId,
            projectId,
            containerTypeId,
            cancellationToken);
        if (containerType is null)
        {
            throw new DomainRuleException("No existe el tipo de contenedor informado para el proyecto.");
        }

        return containerType;
    }

    private async Task<ContainerNode> EnsureContainerExistsAsync(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        CancellationToken cancellationToken)
    {
        await EnsureProjectExistsAsync(tenantId, projectId, cancellationToken);
        if (containerId == Guid.Empty)
        {
            throw new DomainRuleException("El contenedor informado es obligatorio.");
        }

        var container = await _structureRepository.GetContainerByIdAsync(tenantId, projectId, containerId, cancellationToken);
        if (container is null)
        {
            throw new DomainRuleException("No existe el contenedor informado para el proyecto.");
        }

        return container;
    }

    private Task WriteAuditAsync(
        Guid tenantId,
        Guid actorUserId,
        string eventType,
        object payload,
        CancellationToken cancellationToken)
    {
        return _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            eventType,
            "INFO",
            JsonSerializer.Serialize(payload),
            cancellationToken);
    }
}
