using System.ComponentModel.DataAnnotations;

namespace Gdms.Api.Models.Documents;

/// <summary>
/// Represents the multipart payload required to upload and register a document.
/// </summary>
public sealed class UploadDocumentForm
{
    /// <summary>
    /// Gets or sets the document type code resolved against the tenant catalog.
    /// </summary>
    [Required]
    [MaxLength(64)]
    public string DocumentTypeCode { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the optional title overridden by users before upload.
    /// </summary>
    [MaxLength(200)]
    public string? Title { get; set; }

    /// <summary>
    /// Gets or sets the optional metadata payload serialized as JSON.
    /// </summary>
    public string? MetadataJson { get; set; }

    /// <summary>
    /// Gets or sets the binary file posted as multipart form-data.
    /// </summary>
    [Required]
    public IFormFile File { get; set; } = default!;
}
