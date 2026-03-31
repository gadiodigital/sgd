using Gdms.Domain.Common;

namespace Gdms.Domain.Documents;

/// <summary>
/// Represents an immutable stored version of a document.
/// </summary>
public sealed class DocumentVersion
{
    /// <summary>
    /// Initializes a new version instance.
    /// </summary>
    public DocumentVersion(
        Guid id,
        int versionNumber,
        string storageObjectKey,
        string mimeType,
        string fileHashSha256,
        long fileSizeBytes,
        Guid? uploadedByUserId,
        DateTimeOffset uploadedAtUtc)
    {
        Id = id == Guid.Empty ? throw new DomainRuleException("La versión debe tener identificador.") : id;
        VersionNumber = versionNumber > 0 ? versionNumber : throw new DomainRuleException("El número de versión debe ser mayor a cero.");
        StorageObjectKey = RequireText(storageObjectKey, "La clave de almacenamiento es obligatoria.", 260);
        MimeType = RequireText(mimeType, "El mime type es obligatorio.", 120);
        FileHashSha256 = NormalizeHash(fileHashSha256);
        FileSizeBytes = fileSizeBytes > 0 ? fileSizeBytes : throw new DomainRuleException("El tamaño del archivo debe ser mayor a cero.");
        UploadedByUserId = uploadedByUserId is { } value && value != Guid.Empty ? value : null;
        UploadedAtUtc = uploadedAtUtc;
    }

    /// <summary>
    /// Gets the version identifier.
    /// </summary>
    public Guid Id { get; }

    /// <summary>
    /// Gets the sequential version number.
    /// </summary>
    public int VersionNumber { get; }

    /// <summary>
    /// Gets the storage object key used to locate the binary.
    /// </summary>
    public string StorageObjectKey { get; }

    /// <summary>
    /// Gets the MIME type associated with the binary file.
    /// </summary>
    public string MimeType { get; }

    /// <summary>
    /// Gets the SHA-256 hex encoded hash used for integrity checks.
    /// </summary>
    public string FileHashSha256 { get; }

    /// <summary>
    /// Gets the file size in bytes.
    /// </summary>
    public long FileSizeBytes { get; }

    /// <summary>
    /// Gets the user that uploaded the version.
    /// </summary>
    public Guid? UploadedByUserId { get; }

    /// <summary>
    /// Gets the upload timestamp in UTC.
    /// </summary>
    public DateTimeOffset UploadedAtUtc { get; }

    private static string NormalizeHash(string value)
    {
        var normalized = RequireText(value, "El hash SHA-256 es obligatorio.", 64).ToLowerInvariant();
        if (normalized.Length != 64 || !normalized.All(Uri.IsHexDigit))
        {
            throw new DomainRuleException("El hash SHA-256 debe ser hexadecimal de 64 caracteres.");
        }

        return normalized;
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
