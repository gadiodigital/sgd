namespace Gdms.E2eSmokeTests;

public sealed class ScanHostCleanupSmokeTests
{
    [Fact]
    public async Task Cleanup_Session_Artifacts_Should_Remove_Stale_Orphaned_Directories_And_Keep_Active_Ones()
    {
        var activeSessionId = $"scan{Guid.NewGuid():N}"[..24];
        var orphanSessionId = $"orphan{Guid.NewGuid():N}"[..24];

        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(activeSessionId, 1)]);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        var orphanPath = await scanHost.SeedOrphanedSessionArtifactAsync(
            orphanSessionId,
            pageCount: 2,
            lastWriteTimeUtc: DateTimeOffset.UtcNow.AddHours(-13));

        Assert.True(Directory.Exists(orphanPath));

        var cleanupResponse = await scanClient.PostAsync(
            $"{scanHost.BaseUrl}/api/sessions/cleanup",
            content: null);
        cleanupResponse.EnsureSuccessStatusCode();

        var statusPayload = await cleanupResponse.Content.ReadFromJsonAsync<JsonElement>();
        var sessionsStatus = statusPayload.GetProperty("sessions");

        Assert.Equal(1, sessionsStatus.GetProperty("activeSessions").GetInt32());
        Assert.Equal(1, sessionsStatus.GetProperty("lastCleanupDeletedCount").GetInt32());
        Assert.True(sessionsStatus.GetProperty("lastCleanupAtUtc").ValueKind is not JsonValueKind.Null);
        Assert.False(Directory.Exists(orphanPath));

        var activeSessionResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{activeSessionId}");
        activeSessionResponse.EnsureSuccessStatusCode();

        var orphanSessionResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{orphanSessionId}");
        Assert.Equal(HttpStatusCode.NotFound, orphanSessionResponse.StatusCode);
    }
}
