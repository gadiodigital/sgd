namespace Gdms.E2eSmokeTests;

public sealed class ScanHostCorsSmokeTests
{
    [Fact]
    public async Task WindowsTwain_Should_Allow_Loopback_Origins_And_Reject_External_Ones()
    {
        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(scanSessionId);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        using var allowedRequest = new HttpRequestMessage(HttpMethod.Get, $"{scanHost.BaseUrl}/api/status");
        allowedRequest.Headers.Add("Origin", "http://localhost:8087");

        using var allowedResponse = await scanClient.SendAsync(allowedRequest);
        allowedResponse.EnsureSuccessStatusCode();
        Assert.Equal(
            "http://localhost:8087",
            allowedResponse.Headers.GetValues("Access-Control-Allow-Origin").Single());

        using var deniedRequest = new HttpRequestMessage(HttpMethod.Get, $"{scanHost.BaseUrl}/api/status");
        deniedRequest.Headers.Add("Origin", "http://example.com");

        using var deniedResponse = await scanClient.SendAsync(deniedRequest);
        deniedResponse.EnsureSuccessStatusCode();
        Assert.False(
            deniedResponse.Headers.TryGetValues("Access-Control-Allow-Origin", out _),
            "No deberia exponerse CORS para origenes externos no loopback.");
    }

    [Fact]
    public async Task WindowsTwain_Should_Answer_Browser_Preflight_For_Loopback_Origins()
    {
        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(scanSessionId);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        using var preflightRequest = new HttpRequestMessage(
            HttpMethod.Options,
            $"{scanHost.BaseUrl}/api/scans/adf/duplex");
        preflightRequest.Headers.Add("Origin", "http://127.0.0.1:8087");
        preflightRequest.Headers.Add("Access-Control-Request-Method", "POST");
        preflightRequest.Headers.Add("Access-Control-Request-Headers", "content-type");

        using var preflightResponse = await scanClient.SendAsync(preflightRequest);
        Assert.Equal(HttpStatusCode.NoContent, preflightResponse.StatusCode);
        Assert.Equal(
            "http://127.0.0.1:8087",
            preflightResponse.Headers.GetValues("Access-Control-Allow-Origin").Single());
        Assert.Contains(
            "POST",
            preflightResponse.Headers.GetValues("Access-Control-Allow-Methods").Single(),
            StringComparison.OrdinalIgnoreCase);
        Assert.Contains(
            "content-type",
            preflightResponse.Headers.GetValues("Access-Control-Allow-Headers").Single(),
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task WindowsTwain_Should_Allow_Explicit_Configured_Origin_When_Loopback_Is_Disabled()
    {
        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(scanSessionId, 1)],
            new Dictionary<string, string>
            {
                ["WINDOWS_TWAIN_API__ALLOWLOOPBACKORIGINS"] = "false",
                ["WINDOWS_TWAIN_API__ALLOWEDORIGINS__0"] = "https://scan.example.test"
            });
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        using var allowedRequest = new HttpRequestMessage(HttpMethod.Get, $"{scanHost.BaseUrl}/api/status");
        allowedRequest.Headers.Add("Origin", "https://scan.example.test");

        using var allowedResponse = await scanClient.SendAsync(allowedRequest);
        allowedResponse.EnsureSuccessStatusCode();
        Assert.Equal(
            "https://scan.example.test",
            allowedResponse.Headers.GetValues("Access-Control-Allow-Origin").Single());

        using var deniedLoopbackRequest = new HttpRequestMessage(HttpMethod.Get, $"{scanHost.BaseUrl}/api/status");
        deniedLoopbackRequest.Headers.Add("Origin", "http://localhost:8087");

        using var deniedLoopbackResponse = await scanClient.SendAsync(deniedLoopbackRequest);
        deniedLoopbackResponse.EnsureSuccessStatusCode();
        Assert.False(
            deniedLoopbackResponse.Headers.TryGetValues("Access-Control-Allow-Origin", out _),
            "No deberia exponerse CORS loopback cuando AllowLoopbackOrigins=false.");
    }

    [Fact]
    public async Task WindowsTwain_Should_Answer_Preflight_For_Explicit_Configured_Origin_When_Loopback_Is_Disabled()
    {
        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(scanSessionId, 1)],
            new Dictionary<string, string>
            {
                ["WINDOWS_TWAIN_API__ALLOWLOOPBACKORIGINS"] = "false",
                ["WINDOWS_TWAIN_API__ALLOWEDORIGINS__0"] = "https://scan.example.test"
            });
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        using var preflightRequest = new HttpRequestMessage(
            HttpMethod.Options,
            $"{scanHost.BaseUrl}/api/scans/adf/simplex");
        preflightRequest.Headers.Add("Origin", "https://scan.example.test");
        preflightRequest.Headers.Add("Access-Control-Request-Method", "POST");
        preflightRequest.Headers.Add("Access-Control-Request-Headers", "content-type");

        using var preflightResponse = await scanClient.SendAsync(preflightRequest);
        Assert.Equal(HttpStatusCode.NoContent, preflightResponse.StatusCode);
        Assert.Equal(
            "https://scan.example.test",
            preflightResponse.Headers.GetValues("Access-Control-Allow-Origin").Single());
        Assert.Contains(
            "POST",
            preflightResponse.Headers.GetValues("Access-Control-Allow-Methods").Single(),
            StringComparison.OrdinalIgnoreCase);
        Assert.Contains(
            "content-type",
            preflightResponse.Headers.GetValues("Access-Control-Allow-Headers").Single(),
            StringComparison.OrdinalIgnoreCase);
    }
}
