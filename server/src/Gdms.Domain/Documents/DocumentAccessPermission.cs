namespace Gdms.Domain.Documents;

/// <summary>
/// Defines the supported per-document access permissions.
/// </summary>
public enum DocumentAccessPermission
{
    Read = 1,
    Download = 2,
    EditMetadata = 3,
    UploadVersion = 4
}
