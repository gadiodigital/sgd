using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents the payload used to register a new document and its first version.
/// </summary>
public sealed class CreateDocumentRequest
{
    /// <summary>
    /// Gets or sets the business document type code.
    /// </summary>
    [Required]
    [MaxLength(64)]
    public string DocumentTypeCode { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the business title.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Title { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the storage object key of the uploaded file.
    /// </summary>
    [Required]
    [MaxLength(260)]
    public string StorageObjectKey { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the MIME type of the uploaded file.
    /// </summary>
    [Required]
    [MaxLength(120)]
    public string MimeType { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the SHA-256 hash of the uploaded file.
    /// </summary>
    [Required]
    [StringLength(64, MinimumLength = 64)]
    public string FileHashSha256 { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the size in bytes.
    /// </summary>
    [Range(1, long.MaxValue)]
    public long FileSizeBytes { get; init; }

    /// <summary>
    /// Gets or sets the optional metadata payload serialized as JSON.
    /// </summary>
    public string? MetadataJson { get; init; }
}
