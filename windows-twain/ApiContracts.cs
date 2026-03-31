namespace WindowsTwain;

internal sealed record HealthResponse(
    string Application,
    string Version,
    string Status,
    DateTimeOffset StartedAtUtc,
    string BaseUrl);

internal sealed record ApiStatusResponse(
    string Application,
    string Version,
    string BaseUrl,
    DateTimeOffset StartedAtUtc,
    string RunMode,
    string StartupLogPath,
    ScannerStatusResponse Scanner,
    SessionStoreStatusResponse Sessions,
    IReadOnlyList<ScanOperationDescriptor> Operations,
    string Notes);

internal sealed record SessionStoreStatusResponse(
    int ActiveSessions,
    string SessionsRootPath,
    DateTimeOffset? LastCleanupAtUtc,
    int LastCleanupDeletedCount);

internal sealed record ActiveScanSessionSummary(
    string SessionId,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset LastTouchedAtUtc,
    string ScannerName,
    string Mode,
    string Status,
    int PageCount,
    bool IsRehydrated);

internal sealed record ScannerStatusResponse(
    bool DriversReady,
    bool DeviceDiscoveryImplemented,
    bool ScanImplemented,
    string Message);

internal sealed record ScanOperationDescriptor(
    string Id,
    string Description,
    string Availability,
    string Output);

internal sealed record OperationInvocationResponse(
    string OperationId,
    string Result,
    string Message,
    DateTimeOffset TimestampUtc);

internal sealed record ScannerDiscoveryResponse(
    string Result,
    DateTimeOffset TimestampUtc,
    string Transport,
    string ProcessArchitecture,
    IReadOnlyList<ScannerDescriptor> Scanners,
    string Message);

internal sealed record ScannerDescriptor(
    int Id,
    string Name,
    string Manufacturer,
    string ProductFamily,
    string TwainVersion,
    bool IsOpen);

internal sealed record ScanAdfSimplexRequest(
    int? ScannerId,
    string? ScannerName,
    int TimeoutSeconds = 90,
    int? Dpi = null,
    string? PixelType = null,
    string? DiscardBlankPages = null);

internal sealed record ScanAdfDuplexRequest(
    int? ScannerId,
    string? ScannerName,
    int TimeoutSeconds = 90,
    int? Dpi = null,
    string? PixelType = null,
    string? DiscardBlankPages = null);

internal sealed record ScanFlatbedSingleRequest(
    int? ScannerId,
    string? ScannerName,
    int TimeoutSeconds = 90,
    int? Dpi = null,
    string? PixelType = null,
    string? DiscardBlankPages = null);

internal sealed record ScanSettingsResponse(
    double? Dpi,
    string PixelType,
    string DiscardBlankPages,
    string TransferFormat);

internal sealed record ScanSessionResponse(
    string Result,
    string SessionId,
    string Status,
    DateTimeOffset CreatedAtUtc,
    string ScannerName,
    string Mode,
    ScanSettingsResponse Settings,
    int PageCount,
    IReadOnlyList<ScanPageDescriptor> Pages,
    string SessionPath,
    string Message);

internal sealed record ScanPageDescriptor(
    int PageNumber,
    string FileName,
    string FilePath,
    string TransferType,
    string FileFormat,
    long Length);

internal sealed record RotatePageRequest(
    int Degrees = 90);

internal sealed record MovePageRequest(
    int TargetPageNumber);

internal sealed record AdjustPageRequest(
    int Brightness = 0,
    int Contrast = 0);

internal sealed record MergeSessionRequest(
    string SourceSessionId,
    int? InsertAfterPageNumber = null);

internal sealed record SessionPdfArtifact(
    string SessionId,
    string FilePath,
    string DownloadFileName,
    long Length);

internal sealed record PagePreviewArtifact(
    string SessionId,
    int PageNumber,
    string FilePath,
    string ContentType,
    string DownloadFileName,
    int Width,
    int Height,
    int Quality,
    long Length);
