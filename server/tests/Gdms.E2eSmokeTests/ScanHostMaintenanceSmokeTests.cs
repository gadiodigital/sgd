namespace Gdms.E2eSmokeTests;

public sealed class ScanHostMaintenanceSmokeTests
{
    [Fact]
    public async Task Clear_Rehydrated_Sessions_Should_Remove_Seeded_Scan_State_From_Local_Host()
    {
        var firstSessionId = $"scan{Guid.NewGuid():N}"[..24];
        var secondSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [
                new WindowsTwainHostHarness.SeededSession(firstSessionId, 1),
                new WindowsTwainHostHarness.SeededSession(secondSessionId, 2)
            ]);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        var sessionsBeforeClear = await scanClient.GetFromJsonAsync<JsonElement>($"{scanHost.BaseUrl}/api/sessions");
        Assert.Contains(sessionsBeforeClear.EnumerateArray(), session =>
            string.Equals(session.GetProperty("sessionId").GetString(), firstSessionId, StringComparison.Ordinal));
        Assert.Contains(sessionsBeforeClear.EnumerateArray(), session =>
            string.Equals(session.GetProperty("sessionId").GetString(), secondSessionId, StringComparison.Ordinal));

        var clearResponse = await scanClient.DeleteAsync($"{scanHost.BaseUrl}/api/sessions/rehydrated");
        clearResponse.EnsureSuccessStatusCode();

        var statusPayload = await clearResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(0, statusPayload.GetProperty("sessions").GetProperty("activeSessions").GetInt32());

        var sessionsAfterClear = await scanClient.GetFromJsonAsync<JsonElement>($"{scanHost.BaseUrl}/api/sessions");
        Assert.DoesNotContain(sessionsAfterClear.EnumerateArray(), session =>
            string.Equals(session.GetProperty("sessionId").GetString(), firstSessionId, StringComparison.Ordinal));
        Assert.DoesNotContain(sessionsAfterClear.EnumerateArray(), session =>
            string.Equals(session.GetProperty("sessionId").GetString(), secondSessionId, StringComparison.Ordinal));

        var firstSessionResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{firstSessionId}");
        var secondSessionResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{secondSessionId}");

        Assert.Equal(HttpStatusCode.NotFound, firstSessionResponse.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, secondSessionResponse.StatusCode);
    }
}
