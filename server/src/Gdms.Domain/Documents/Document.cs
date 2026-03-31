using Gdms.Domain.Common;

namespace Gdms.Domain.Documents;

/// <summary>
/// Represents the root aggregate for a business document and its versions.
/// </summary>
public sealed class Document
{
    private readonly List<DocumentVersion> _versions = [];

    /// <summary>
    /// Initializes a new document aggregate.
    /// </summary>
    public Document(
        Guid id,
        Guid tenantId,
        string documentTypeCode,
        string title,
        DocumentStatus status,
        DateTimeOffset createdAtUtc)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("El documento debe tener identificador.") : id;
        TenantId = tenantId == Guid.Empty ? throw new DomainRuleException("El tenant del documento es obligatorio.") : tenantId;
        DocumentTypeCode = RequireText(documentTypeCode, "El código de tipo documental es obligatorio.", 64).ToUpperInvariant();
        Title = RequireText(title, "El título del documento es obligatorio.", 200);
        Status = status;
        CreatedAtUtc = createdAtUtc;
    }

    /// <summary>
    /// Gets the document identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the tenant identifier that owns the document.
    /// </summary>
    public Guid TenantId { get; }

    /// <summary>
    /// Gets the normalized document type code.
    /// </summary>
    public string DocumentTypeCode { get; }

    /// <summary>
    /// Gets the title assigned by business users.
    /// </summary>
    public string Title { get; }

    /// <summary>
    /// Gets the current lifecycle status.
    /// </summary>
    public DocumentStatus Status { get; private set; }

    /// <summary>
    /// Gets the document creation timestamp in UTC.
    /// </summary>
    public DateTimeOffset CreatedAtUtc { get; }

    /// <summary>
    /// Gets the immutable versions stored for the document.
    /// </summary>
    public IReadOnlyCollection<DocumentVersion> Versions => _versions.AsReadOnly();

    /// <summary>
    /// Creates a new active document aggregate.
    /// </summary>
    public static Document Create(Guid tenantId, string documentTypeCode, string title, DateTimeOffset createdAtUtc)
    {
        return new Document(Guid.NewGuid(), tenantId, documentTypeCode, title, DocumentStatus.Active, createdAtUtc);
    }

    /// <summary>
    /// Rehydrates a document aggregate and its immutable versions from persistence.
    /// </summary>
    public static Document Rehydrate(
        Guid id,
        Guid tenantId,
        string documentTypeCode,
        string title,
        DocumentStatus status,
        DateTimeOffset createdAtUtc,
        IEnumerable<DocumentVersion> versions)
    {
        var document = new Document(id, tenantId, documentTypeCode, title, status, createdAtUtc);
        document._versions.AddRange(versions.OrderBy(version => version.VersionNumber));
        return document;
    }

    /// <summary>
    /// Adds a new version to the aggregate.
    /// </summary>
    public DocumentVersion AddVersion(
        string storageObjectKey,
        string mimeType,
        string fileHashSha256,
        long fileSizeBytes,
        Guid uploadedByUserId,
        DateTimeOffset uploadedAtUtc)
    {
        var version = new DocumentVersion(
            Guid.NewGuid(),
            _versions.Count + 1,
            storageObjectKey,
            mimeType,
            fileHashSha256,
            fileSizeBytes,
            uploadedByUserId,
            uploadedAtUtc);

        _versions.Add(version);
        return version;
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
