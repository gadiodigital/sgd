namespace Gdms.Domain.Structure;

/// <summary>
/// Read model for a document linked to a configurable container.
/// </summary>
public sealed class ContainerDocumentLink
{
    private ContainerDocumentLink(
        Guid containerId,
        Guid documentId,
        Guid tenantId,
        string documentTitle,
        string documentTypeCode,
        string documentStatus,
        DateTimeOffset linkedAtUtc,
        Guid? linkedByUserId)
    {
        ContainerId = containerId;
        DocumentId = documentId;
        TenantId = tenantId;
        DocumentTitle = documentTitle;
        DocumentTypeCode = documentTypeCode;
        DocumentStatus = documentStatus;
        LinkedAtUtc = linkedAtUtc;
        LinkedByUserId = linkedByUserId;
    }

    public Guid ContainerId { get; }
    public Guid DocumentId { get; }
    public Guid TenantId { get; }
    public string DocumentTitle { get; }
    public string DocumentTypeCode { get; }
    public string DocumentStatus { get; }
    public DateTimeOffset LinkedAtUtc { get; }
    public Guid? LinkedByUserId { get; }

    public static ContainerDocumentLink Rehydrate(
        Guid containerId,
        Guid documentId,
        Guid tenantId,
        string documentTitle,
        string documentTypeCode,
        string documentStatus,
        DateTimeOffset linkedAtUtc,
        Guid? linkedByUserId)
    {
        return new ContainerDocumentLink(
            containerId,
            documentId,
            tenantId,
            documentTitle,
            documentTypeCode,
            documentStatus,
            linkedAtUtc,
            linkedByUserId);
    }
}
