namespace WindowsTwain;

internal sealed partial class ScanSessionStore
{
    public SessionStoreStatusResponse CleanupStaleArtifacts()
    {
        var deletedCount = 0;
        var cutoffUtc = DateTimeOffset.UtcNow - DefaultCleanupMaxAge;

        foreach (var directory in Directory.EnumerateDirectories(rootPath))
        {
            var sessionId = Path.GetFileName(directory);
            if (string.IsNullOrWhiteSpace(sessionId) || sessions.ContainsKey(sessionId))
            {
                continue;
            }

            if (Directory.GetLastWriteTimeUtc(directory) > cutoffUtc.UtcDateTime)
            {
                continue;
            }

            try
            {
                Directory.Delete(directory, recursive: true);
                deletedCount++;
            }
            catch (IOException)
            {
            }
            catch (UnauthorizedAccessException)
            {
            }
        }

        lastCleanupAtUtc = DateTimeOffset.UtcNow;
        lastCleanupDeletedCount = deletedCount;
        return GetStatus();
    }

    public SessionStoreStatusResponse ClearActiveSessions() => ClearSessions(_ => true);

    public SessionStoreStatusResponse ClearStaleSessions()
    {
        var cutoffUtc = DateTimeOffset.UtcNow - TimeSpan.FromHours(2);
        return ClearSessions(session => session.LastTouchedAtUtc <= cutoffUtc);
    }

    public SessionStoreStatusResponse ClearRehydratedSessions() => ClearSessions(session => session.IsRehydrated);

    public ScanSessionResponse MergeSessions(string targetSessionId, string sourceSessionId, int? insertAfterPageNumber)
    {
        if (string.Equals(targetSessionId, sourceSessionId, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("No se puede fusionar una sesion consigo misma.");
        }

        var targetSession = GetState(targetSessionId);
        var sourceSession = GetState(sourceSessionId);
        var response = targetSession.InsertPages(sourceSession.CopyPages(), insertAfterPageNumber);

        sessions.TryRemove(sourceSessionId, out _);
        if (Directory.Exists(sourceSession.SessionPath))
        {
            Directory.Delete(sourceSession.SessionPath, recursive: true);
        }

        return response;
    }

    private SessionStoreStatusResponse ClearSessions(Func<ScanSessionState, bool> predicate)
    {
        foreach (var sessionId in sessions.Keys.ToArray())
        {
            if (!sessions.TryGetValue(sessionId, out var session) || !predicate(session))
            {
                continue;
            }

            if (!sessions.TryRemove(sessionId, out session) || !Directory.Exists(session.SessionPath))
            {
                continue;
            }

            try
            {
                Directory.Delete(session.SessionPath, recursive: true);
            }
            catch (IOException)
            {
            }
            catch (UnauthorizedAccessException)
            {
            }
        }

        return GetStatus();
    }
}
