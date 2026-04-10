namespace Gdms.E2eSmokeTests;

public sealed class ScanHostPdfRangeSmokeTests
{
    [Fact]
    public async Task WindowsTwain_Should_Serve_Pdf_With_Range_Support_For_Browser_Viewers()
    {
        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(scanSessionId, 2)]);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        using var fullResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{scanSessionId}/pdf");
        fullResponse.EnsureSuccessStatusCode();

        using var rangeRequest = new HttpRequestMessage(
            HttpMethod.Get,
            $"{scanHost.BaseUrl}/api/scans/{scanSessionId}/pdf");
        rangeRequest.Headers.Range = new RangeHeaderValue(0, 127);

        using var partialResponse = await WaitForSuccessfulRangeResponseAsync(scanClient, rangeRequest);
        Assert.Equal(HttpStatusCode.PartialContent, partialResponse.StatusCode);
        Assert.Equal("application/pdf", partialResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("bytes", partialResponse.Content.Headers.ContentRange?.Unit);
        Assert.Equal(0, partialResponse.Content.Headers.ContentRange?.From);
        Assert.Equal(127, partialResponse.Content.Headers.ContentRange?.To);
        Assert.True((partialResponse.Content.Headers.ContentRange?.Length ?? 0) >= 128);

        var partialBytes = await partialResponse.Content.ReadAsByteArrayAsync();
        Assert.Equal(128, partialBytes.Length);
        Assert.Equal("%PDF-", Encoding.ASCII.GetString(partialBytes.Take(5).ToArray()));
    }

    private static async Task<HttpResponseMessage> WaitForSuccessfulRangeResponseAsync(
        HttpClient client,
        HttpRequestMessage templateRequest)
    {
        var startedAt = DateTimeOffset.UtcNow;

        while (DateTimeOffset.UtcNow - startedAt < TimeSpan.FromSeconds(10))
        {
            using var request = new HttpRequestMessage(templateRequest.Method, templateRequest.RequestUri);
            request.Headers.Range = templateRequest.Headers.Range;

            var response = await client.SendAsync(request);
            if (response.StatusCode == HttpStatusCode.PartialContent)
            {
                return response;
            }

            response.Dispose();
            await Task.Delay(250);
        }

        throw new Xunit.Sdk.XunitException("El host local no devolvio 206 Partial Content para el PDF en el tiempo esperado.");
    }
}
