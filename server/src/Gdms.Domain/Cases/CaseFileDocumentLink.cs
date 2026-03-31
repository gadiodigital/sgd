using Gdms.Domain.Common;

namespace Gdms.Domain.Cases;

/// <summary>
/// Represents a document linked to a case file.
/// </summary>
public sealed class CaseFileDocumentLink
{
    private CaseFileDocumentLink(
        Guid caseFileId,
        Guid documentId,
        Guid tenantId,
        string documentTitle,
        string documentTypeCode,
        string documentStatus,
        DateTimeOffset linkedAtUtc,
        Guid? linkedByUserId)
    {
        CaseFileId = caseFileId == Guid.Empty
            ? throw new DomainRuleException("El expediente vinculado es obligatorio.")
            : caseFileId;
        DocumentId = documentId == Guid.Empty
            ? throw new DomainRuleException("El documento vinculado es obligatorio.")
            : documentId;
        TenantId = tenantId == Guid.Empty
            ? throw new DomainRuleException("El tenant del vínculo expediente-documento es obligatorio.")
            : tenantId;
        DocumentTitle = RequireText(documentTitle, "El título del documento vinculado es obligatorio.", 200);
        DocumentTypeCode = RequireText(documentTypeCode, "El tipo documental vinculado es obligatorio.", 64).ToUpperInvariant();
        DocumentStatus = RequireText(documentStatus, "El estado documental vinculado es obligatorio.", 24).ToUpperInvariant();
        LinkedAtUtc = linkedAtUtc;
        LinkedByUserId = linkedByUserId;
    }

    public Guid CaseFileId { get; }
    public Guid DocumentId { get; }
    public Guid TenantId { get; }
    public string DocumentTitle { get; }
    public string DocumentTypeCode { get; }
    public string DocumentStatus { get; }
    public DateTimeOffset LinkedAtUtc { get; }
    public Guid? LinkedByUserId { get; }

    /// <summary>
    /// Rehydrates a persisted case-file document link.
    /// </summary>
    public static CaseFileDocumentLink Rehydrate(
        Guid caseFileId,
        Guid documentId,
        Guid tenantId,
        string documentTitle,
        string documentTypeCode,
        string documentStatus,
        DateTimeOffset linkedAtUtc,
        Guid? linkedByUserId)
    {
        return new CaseFileDocumentLink(
            caseFileId,
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
