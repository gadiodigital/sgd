namespace Gdms.E2eSmokeTests;

public sealed class ScanHostInFlightAbortSmokeTests
{
    [Fact]
    public async Task WindowsTwain_Should_Keep_Canceled_Session_When_Request_Is_Aborted_MidFlight()
    {
        await using var scanHost = new WindowsTwainHostHarness(
            [],
            new Dictionary<string, string>
            {
                ["WINDOWS_TWAIN_TEST_INFLIGHT_SCAN_DELAY_MS"] = "5000"
            });
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();
        using var requestCts = new CancellationTokenSource(TimeSpan.FromMilliseconds(150));

        await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            scanClient.PostAsJsonAsync(
                $"{scanHost.BaseUrl}/api/scans/adf/duplex",
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
        var sessionList = sessions.EnumerateArray().ToArray();
        Assert.Single(sessionList);
        Assert.Equal("canceled", sessionList[0].GetProperty("status").GetString(), ignoreCase: true);
        Assert.Equal(0, sessionList[0].GetProperty("pageCount").GetInt32());
        Assert.False(sessionList[0].GetProperty("isRehydrated").GetBoolean());
    }
}
