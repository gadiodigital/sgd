using System.ComponentModel.DataAnnotations;

namespace Gdms.Api.Models.Documents;

/// <summary>
/// Represents the multipart payload required to upload a new version for an existing document.
/// </summary>
public sealed class UploadDocumentVersionForm
{
    /// <summary>
    /// Gets or sets the binary file posted as multipart form-data.
    /// </summary>
    [Required]
    public IFormFile File { get; set; } = default!;
}
