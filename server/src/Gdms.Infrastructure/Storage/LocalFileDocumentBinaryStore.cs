using System.Security.Cryptography;
using Gdms.Application.Abstractions.Storage;
using Gdms.Infrastructure.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace Gdms.Infrastructure.Storage;

/// <summary>
/// Stores document binaries in the local filesystem for development and single-node deployments.
/// </summary>
public sealed class LocalFileDocumentBinaryStore : IDocumentBinaryStore
{
    private readonly string _rootPath;

    /// <summary>
    /// Initializes the adapter with filesystem storage settings.
    /// </summary>
    public LocalFileDocumentBinaryStore(IOptions<StorageOptions> optionsAccessor, IHostEnvironment hostEnvironment)
    {
        var options = optionsAccessor.Value;
        var configuredPath = string.IsNullOrWhiteSpace(options.LocalRootPath)
            ? "data/storage/documents"
            : options.LocalRootPath.Trim();

        _rootPath = Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.GetFullPath(Path.Combine(hostEnvironment.ContentRootPath, configuredPath));
    }

    /// <inheritdoc />
    public async Task<StoredBinaryObject> SaveAsync(
        Guid tenantId,
        string fileName,
        string mimeType,
        Stream content,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(fileName);
        ArgumentException.ThrowIfNullOrWhiteSpace(mimeType);

        var sanitizedFileName = SanitizeFileName(fileName);
        var objectKey = string.Join(
            '/',
            tenantId.ToString("N"),
            DateTime.UtcNow.ToString("yyyy"),
            DateTime.UtcNow.ToString("MM"),
            $"{Guid.NewGuid():N}-{sanitizedFileName}");

        var fullPath = Path.Combine(_rootPath, objectKey.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);

        long totalBytes = 0;
        var buffer = new byte[81920];

        await using var output = new FileStream(fullPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, buffer.Length, useAsync: true);
        using var sha256 = SHA256.Create();

        int bytesRead;
        while ((bytesRead = await content.ReadAsync(buffer.AsMemory(0, buffer.Length), cancellationToken)) > 0)
        {
            await output.WriteAsync(buffer.AsMemory(0, bytesRead), cancellationToken);
            sha256.TransformBlock(buffer, 0, bytesRead, null, 0);
            totalBytes += bytesRead;
        }

        sha256.TransformFinalBlock([], 0, 0);
        var hash = Convert.ToHexString(sha256.Hash!).ToLowerInvariant();

        return new StoredBinaryObject(objectKey, hash, totalBytes);
    }

    /// <inheritdoc />
    public Task<StoredBinaryContent?> OpenReadAsync(string objectKey, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var fullPath = Path.Combine(_rootPath, objectKey.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath))
        {
            return Task.FromResult<StoredBinaryContent?>(null);
        }

        var fileInfo = new FileInfo(fullPath);
        Stream stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, useAsync: true);
        return Task.FromResult<StoredBinaryContent?>(new StoredBinaryContent(stream, fileInfo.Length));
    }

    private static string SanitizeFileName(string fileName)
    {
        var invalidChars = Path.GetInvalidFileNameChars();
        var normalized = new string(fileName.Trim().Select(character => invalidChars.Contains(character) ? '_' : character).ToArray());
        return string.IsNullOrWhiteSpace(normalized) ? "document.bin" : normalized;
    }
}
