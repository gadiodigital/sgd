using System.Collections.Concurrent;

namespace WindowsTwain;

internal sealed partial class ScanSessionStore
{
    private static readonly TimeSpan DefaultCleanupMaxAge = TimeSpan.FromHours(12);
    private const string MetadataFileName = "session.json";
    private readonly string rootPath;
    private readonly ConcurrentDictionary<string, ScanSessionState> sessions = new(StringComparer.OrdinalIgnoreCase);
    private DateTimeOffset? lastCleanupAtUtc;
    private int lastCleanupDeletedCount;

    public ScanSessionStore()
    {
        rootPath = Path.Combine(AppContext.BaseDirectory, "sessions");
        Directory.CreateDirectory(rootPath);
        RehydrateSessions();
        CleanupStaleArtifacts();
    }

    public ScanSessionState Create(string scannerName, string mode, ScanSettingsResponse settings)
    {
        var sessionId = Guid.NewGuid().ToString("N");
        var sessionPath = Path.Combine(rootPath, sessionId);
        Directory.CreateDirectory(sessionPath);

        var session = new ScanSessionState(sessionId, DateTimeOffset.UtcNow, scannerName, mode, settings, sessionPath);
        sessions[sessionId] = session;
        return session;
    }

    public ScanSessionResponse? Get(string sessionId)
    {
        return sessions.TryGetValue(sessionId, out var session)
            ? session.ToResponse()
            : null;
    }

    public ScanSessionState GetState(string sessionId)
    {
        if (!sessions.TryGetValue(sessionId, out var session))
        {
            throw new KeyNotFoundException($"No existe una sesion con id {sessionId}.");
        }

        return session;
    }

    public void DeleteSession(string sessionId)
    {
        if (!sessions.TryRemove(sessionId, out var session))
        {
            throw new KeyNotFoundException($"No existe una sesion con id {sessionId}.");
        }

        if (!Directory.Exists(session.SessionPath))
        {
            return;
        }

        try
        {
            Directory.Delete(session.SessionPath, recursive: true);
        }
        catch (IOException ex)
        {
            throw new InvalidOperationException("No se pudo eliminar la carpeta fisica de la sesion.", ex);
        }
        catch (UnauthorizedAccessException ex)
        {
            throw new InvalidOperationException("No se pudo eliminar la carpeta fisica de la sesion.", ex);
        }
    }

    public SessionStoreStatusResponse GetStatus()
    {
        return new SessionStoreStatusResponse(
            ActiveSessions: sessions.Count,
            SessionsRootPath: rootPath,
            LastCleanupAtUtc: lastCleanupAtUtc,
            LastCleanupDeletedCount: lastCleanupDeletedCount);
    }

    public IReadOnlyList<ActiveScanSessionSummary> ListActiveSessions()
    {
        return sessions.Values
            .OrderByDescending(session => session.CreatedAtUtc)
            .Select(session => session.ToSummary())
            .ToArray();
    }

    private void RehydrateSessions()
    {
        foreach (var directory in Directory.EnumerateDirectories(rootPath))
        {
            try
            {
                var session = ScanSessionState.TryLoad(directory);
                if (session is not null)
                {
                    sessions[session.SessionId] = session;
                }
            }
            catch (Exception ex)
            {
                StartupLog.Write($"No se pudo rehidratar la sesion desde {directory}: " + ex);
            }
        }
    }
}
