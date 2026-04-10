using System.Text.Json;

namespace Gdms.E2eSmokeTests;

internal sealed class WindowsTwainHostHarness : IAsyncDisposable
{
    private static readonly byte[] SeedPngBytes = Convert.FromBase64String(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn4nWQAAAAASUVORK5CYII=");

    private readonly IReadOnlyList<SeededSession> seededSessions;
    private readonly IReadOnlyDictionary<string, string> environmentOverrides;
    private readonly string host;
    private readonly int port;
    private readonly string mutexName;
    private readonly string outputDirectory;
    private readonly string sessionsRootPath;
    private Process? process;

    public WindowsTwainHostHarness(string sessionId)
        : this([new SeededSession(sessionId, 1)])
    {
    }

    public WindowsTwainHostHarness(IReadOnlyList<SeededSession> seededSessions)
        : this(seededSessions, new Dictionary<string, string>())
    {
    }

    public WindowsTwainHostHarness(
        IReadOnlyList<SeededSession> seededSessions,
        IReadOnlyDictionary<string, string> environmentOverrides)
    {
        this.seededSessions = seededSessions;
        this.environmentOverrides = environmentOverrides;
        host = "127.0.0.1";
        port = Random.Shared.Next(44000, 44999);
        mutexName = $@"Local\windows-twain-e2e-{Guid.NewGuid():N}";
        outputDirectory = ResolveOutputDirectory();
        sessionsRootPath = Path.Combine(outputDirectory, "sessions");
        BaseUrl = $"http://{host}:{port}";
    }

    public string BaseUrl { get; }
    public string SessionsRootPath => sessionsRootPath;

    public async Task StartAsync(bool resetSessionsRoot = true)
    {
        if (process is not null && !process.HasExited)
        {
            return;
        }

        if (resetSessionsRoot)
        {
            ResetSessionsRoot();
        }
        foreach (var session in seededSessions)
        {
            await SeedSessionAsync(session);
        }

        process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "dotnet",
                Arguments = $"run --project \"{ResolveProjectPath()}\" -- --headless",
                WorkingDirectory = ResolveRepositoryRoot(),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            }
        };
        process.StartInfo.Environment["WINDOWS_TWAIN_API__HOST"] = host;
        process.StartInfo.Environment["WINDOWS_TWAIN_API__PORT"] = port.ToString();
        process.StartInfo.Environment["WINDOWS_TWAIN_SINGLE_INSTANCE_MUTEX_NAME"] = mutexName;
        foreach (var (key, value) in environmentOverrides)
        {
            process.StartInfo.Environment[key] = value;
        }
        process.Start();

        await WaitUntilReadyAsync();
        await WaitUntilSeededSessionsAreVisibleAsync();
    }

    public async Task RestartAsync()
    {
        await StopHostAsync();
        await StartAsync(resetSessionsRoot: false);
    }

    public async Task StopHostAsync()
    {
        if (process is null || process.HasExited)
        {
            process = null;
            return;
        }

        process.Kill(entireProcessTree: true);
        await process.WaitForExitAsync();
        process.Dispose();
        process = null;
    }

    public async ValueTask DisposeAsync()
    {
        await StopHostAsync();
        ResetSessionsRoot();
    }

    private async Task SeedSessionAsync(SeededSession session)
    {
        var sessionPath = Path.Combine(sessionsRootPath, session.SessionId);
        if (Directory.Exists(sessionPath))
        {
            return;
        }

        Directory.CreateDirectory(sessionPath);

        for (var pageNumber = 1; pageNumber <= session.PageCount; pageNumber++)
        {
            var filePath = Path.Combine(sessionPath, $"page-{pageNumber:000}.png");
            await File.WriteAllBytesAsync(filePath, SeedPngBytes);
        }

        var timestampUtc = DateTimeOffset.UtcNow;
        var metadata = new
        {
            CreatedAtUtc = timestampUtc,
            LastTouchedAtUtc = timestampUtc,
            ScannerName = "Sesion recuperada",
            Mode = session.PageCount <= 1 ? "flatbed-single" : "adf-simplex",
            Settings = new
            {
                Dpi = 300,
                PixelType = "color",
                DiscardBlankPages = "off",
                TransferFormat = "png"
            },
            Status = "completed",
            Message = "Sesion rehidratada desde disco.",
            ArtifactRevision = 1,
            IsRehydrated = true
        };
        var metadataPath = Path.Combine(sessionPath, "session.json");
        await File.WriteAllTextAsync(metadataPath, JsonSerializer.Serialize(metadata));
    }

    public async Task<string> SeedOrphanedSessionArtifactAsync(string sessionId, int pageCount, DateTimeOffset lastWriteTimeUtc)
    {
        var sessionPath = Path.Combine(sessionsRootPath, sessionId);
        Directory.CreateDirectory(sessionPath);

        for (var pageNumber = 1; pageNumber <= pageCount; pageNumber++)
        {
            var filePath = Path.Combine(sessionPath, $"page-{pageNumber:000}.png");
            await File.WriteAllBytesAsync(filePath, SeedPngBytes);
        }

        Directory.SetLastWriteTimeUtc(sessionPath, lastWriteTimeUtc.UtcDateTime);
        foreach (var filePath in Directory.EnumerateFiles(sessionPath))
        {
            File.SetLastWriteTimeUtc(filePath, lastWriteTimeUtc.UtcDateTime);
        }

        return sessionPath;
    }

    private void ResetSessionsRoot()
    {
        Directory.CreateDirectory(sessionsRootPath);
        foreach (var sessionPath in Directory.EnumerateDirectories(sessionsRootPath))
        {
            Directory.Delete(sessionPath, recursive: true);
        }
    }

    private async Task WaitUntilReadyAsync()
    {
        using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(2) };
        var startedAt = DateTimeOffset.UtcNow;

        while (DateTimeOffset.UtcNow - startedAt < TimeSpan.FromSeconds(30))
        {
            if (process is not null && process.HasExited)
            {
                var error = await process.StandardError.ReadToEndAsync();
                var output = await process.StandardOutput.ReadToEndAsync();
                throw new InvalidOperationException(
                    $"windows-twain finalizo antes de exponer la API. stdout={output} stderr={error}");
            }

            try
            {
                using var response = await client.GetAsync($"{BaseUrl}/health");
                if (response.IsSuccessStatusCode)
                {
                    return;
                }
            }
            catch (HttpRequestException)
            {
            }
            catch (TaskCanceledException)
            {
            }

            await Task.Delay(250);
        }

        throw new TimeoutException("windows-twain no expuso /health dentro del tiempo esperado.");
    }

    private async Task WaitUntilSeededSessionsAreVisibleAsync()
    {
        if (seededSessions.Count == 0)
        {
            return;
        }

        using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(2) };
        var startedAt = DateTimeOffset.UtcNow;

        while (DateTimeOffset.UtcNow - startedAt < TimeSpan.FromSeconds(15))
        {
            try
            {
                var sessions = await client.GetFromJsonAsync<JsonElement>($"{BaseUrl}/api/sessions");
                if (sessions.ValueKind == JsonValueKind.Array &&
                    seededSessions.All(seed =>
                        sessions.EnumerateArray().Any(session =>
                            string.Equals(session.GetProperty("sessionId").GetString(), seed.SessionId, StringComparison.Ordinal))))
                {
                    return;
                }
            }
            catch (HttpRequestException)
            {
            }
            catch (TaskCanceledException)
            {
            }

            await Task.Delay(250);
        }

        throw new TimeoutException("windows-twain no expuso las sesiones seed dentro del tiempo esperado.");
    }

    private static string ResolveRepositoryRoot()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "windows-twain")) &&
                Directory.Exists(Path.Combine(current.FullName, "server")))
            {
                return current.FullName;
            }

            current = current.Parent;
        }

        throw new DirectoryNotFoundException("No se pudo resolver la raiz del repositorio para windows-twain.");
    }

    private static string ResolveProjectPath()
    {
        return Path.Combine(ResolveRepositoryRoot(), "windows-twain", "windows-twain.csproj");
    }

    private static string ResolveOutputDirectory()
    {
        return Path.Combine(ResolveRepositoryRoot(), "windows-twain", "bin", "Debug", "net10.0-windows");
    }

    internal sealed record SeededSession(string SessionId, int PageCount);
}
