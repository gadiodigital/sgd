using Gdms.Domain.Common;

namespace Gdms.Domain.Structure;

/// <summary>
/// Configurable type for nodes inside a document structure project.
/// </summary>
public sealed class ContainerTypeDefinition
{
    private ContainerTypeDefinition(
        Guid id,
        Guid tenantId,
        Guid projectId,
        string code,
        string name,
        string iconKey,
        bool isRootAllowed,
        bool acceptsDocuments,
        string metadataSchemaJson,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        ProjectId = projectId;
        Code = code;
        Name = name;
        IconKey = iconKey;
        IsRootAllowed = isRootAllowed;
        AcceptsDocuments = acceptsDocuments;
        MetadataSchemaJson = metadataSchemaJson;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public Guid ProjectId { get; }
    public string Code { get; }
    public string Name { get; }
    public string IconKey { get; }
    public bool IsRootAllowed { get; }
    public bool AcceptsDocuments { get; }
    public string MetadataSchemaJson { get; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }

    public static ContainerTypeDefinition Create(
        Guid tenantId,
        Guid projectId,
        string code,
        string name,
        string? iconKey,
        bool isRootAllowed,
        bool acceptsDocuments,
        string metadataSchemaJson,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        if (tenantId == Guid.Empty || projectId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant y el proyecto son obligatorios para crear un tipo de contenedor.");
        }

        return new ContainerTypeDefinition(
            Guid.NewGuid(),
            tenantId,
            projectId,
            StructureProject.NormalizeCode(code, "El código del tipo de contenedor es obligatorio.", 64),
            StructureProject.RequireText(name, "El nombre del tipo de contenedor es obligatorio.", 120),
            NormalizeIconKey(iconKey),
            isRootAllowed,
            acceptsDocuments,
            string.IsNullOrWhiteSpace(metadataSchemaJson) ? "{}" : metadataSchemaJson,
            createdByUserId,
            createdAtUtc);
    }

    public static ContainerTypeDefinition Rehydrate(
        Guid id,
        Guid tenantId,
        Guid projectId,
        string code,
        string name,
        string iconKey,
        bool isRootAllowed,
        bool acceptsDocuments,
        string metadataSchemaJson,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc)
    {
        return new ContainerTypeDefinition(
            id,
            tenantId,
            projectId,
            code,
            name,
            iconKey,
            isRootAllowed,
            acceptsDocuments,
            metadataSchemaJson,
            createdByUserId,
            createdAtUtc);
    }

    private static string NormalizeIconKey(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return "folder";
        }

        return StructureProject.RequireText(value, "El icono del tipo de contenedor es obligatorio.", 80);
    }
}
