namespace Gdms.E2eSmokeTests;

public sealed class ScanHostRequestAbortSmokeTests
{
    [Fact]
    public async Task WindowsTwain_Should_Abort_Scan_Request_Without_Leaving_Host_Unhealthy()
    {
        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(scanSessionId, 1)],
            new Dictionary<string, string>
            {
                ["WINDOWS_TWAIN_TEST_SCAN_DELAY_MS"] = "5000"
            });
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();
        using var requestCts = new CancellationTokenSource(TimeSpan.FromMilliseconds(150));

        await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            scanClient.PostAsJsonAsync(
                $"{scanHost.BaseUrl}/api/scans/adf/simplex",
                new
                {
                    scannerName = "Simulated Scanner",
                    timeoutSeconds = 90,
                    dpi = 300,
                    pixelType = "color",
                    discardBlankPages = "off"
                },
                requestCts.Token));

        using var healthResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/health");
        healthResponse.EnsureSuccessStatusCode();

        var sessions = await scanClient.GetFromJsonAsync<JsonElement>($"{scanHost.BaseUrl}/api/sessions");
        Assert.Equal(JsonValueKind.Array, sessions.ValueKind);
        var sessionList = sessions.EnumerateArray().ToArray();
        Assert.Single(sessionList);
        Assert.Equal(scanSessionId, sessionList[0].GetProperty("sessionId").GetString());
        Assert.True(sessionList[0].GetProperty("isRehydrated").GetBoolean());
    }
}
