using Gdms.Domain.Common;

namespace Gdms.Domain.RealEstate;

/// <summary>
/// Represents a document linked to a property file.
/// </summary>
public sealed class PropertyFileDocumentLink
{
    private PropertyFileDocumentLink(
        Guid propertyFileId,
        Guid documentId,
        Guid tenantId,
        string documentTitle,
        string documentTypeCode,
        string documentStatus,
        DateTimeOffset linkedAtUtc,
        Guid? linkedByUserId)
    {
        PropertyFileId = propertyFileId == Guid.Empty
            ? throw new DomainRuleException("El legajo inmobiliario vinculado es obligatorio.")
            : propertyFileId;
        DocumentId = documentId == Guid.Empty
            ? throw new DomainRuleException("El documento vinculado es obligatorio.")
            : documentId;
        TenantId = tenantId == Guid.Empty
            ? throw new DomainRuleException("El tenant del vínculo legajo-documento es obligatorio.")
            : tenantId;
        DocumentTitle = RequireText(documentTitle, "El título del documento vinculado es obligatorio.", 200);
        DocumentTypeCode = RequireText(documentTypeCode, "El tipo documental vinculado es obligatorio.", 64).ToUpperInvariant();
        DocumentStatus = RequireText(documentStatus, "El estado documental vinculado es obligatorio.", 24).ToUpperInvariant();
        LinkedAtUtc = linkedAtUtc;
        LinkedByUserId = linkedByUserId;
    }

    public Guid PropertyFileId { get; }
    public Guid DocumentId { get; }
    public Guid TenantId { get; }
    public string DocumentTitle { get; }
    public string DocumentTypeCode { get; }
    public string DocumentStatus { get; }
    public DateTimeOffset LinkedAtUtc { get; }
    public Guid? LinkedByUserId { get; }

    /// <summary>
    /// Rehydrates a persisted property-file document link.
    /// </summary>
    public static PropertyFileDocumentLink Rehydrate(
        Guid propertyFileId,
        Guid documentId,
        Guid tenantId,
        string documentTitle,
        string documentTypeCode,
        string documentStatus,
        DateTimeOffset linkedAtUtc,
        Guid? linkedByUserId)
    {
        return new PropertyFileDocumentLink(
            propertyFileId,
            documentId,
            tenantId,
            documentTitle,
            documentTypeCode,
            documentStatus,
            linkedAtUtc,
            linkedByUserId);
    }

    private static string RequireText(string value, string message, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new DomainRuleException(message);
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new DomainRuleException($"El valor '{normalized}' excede la longitud máxima permitida de {maxLength}.");
        }

        return normalized;
    }
}
