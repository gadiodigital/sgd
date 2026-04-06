namespace Gdms.E2eSmokeTests;

internal sealed class WindowsTwainHostHarness : IAsyncDisposable
{
    private static readonly byte[] SeedPngBytes = Convert.FromBase64String(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn4nWQAAAAASUVORK5CYII=");

    private readonly IReadOnlyList<SeededSession> seededSessions;
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
    {
        this.seededSessions = seededSessions;
        host = "127.0.0.1";
        port = Random.Shared.Next(44000, 44999);
        mutexName = $@"Local\windows-twain-e2e-{Guid.NewGuid():N}";
        outputDirectory = ResolveOutputDirectory();
        sessionsRootPath = Path.Combine(outputDirectory, "sessions");
        BaseUrl = $"http://{host}:{port}";
    }

    public string BaseUrl { get; }
    public string SessionsRootPath => sessionsRootPath;

    public async Task StartAsync()
    {
        if (process is not null && !process.HasExited)
        {
            return;
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
        process.Start();

        await WaitUntilReadyAsync();
    }

    public async Task RestartAsync()
    {
        await StopHostAsync();
        await StartAsync();
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

        foreach (var session in seededSessions)
        {
            var sessionPath = Path.Combine(sessionsRootPath, session.SessionId);
            if (Directory.Exists(sessionPath))
            {
                Directory.Delete(sessionPath, recursive: true);
            }
        }
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
