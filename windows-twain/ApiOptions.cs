namespace WindowsTwain;

internal sealed class ApiOptions
{
    public const string SectionName = "Api";

    public string Host { get; init; } = "127.0.0.1";

    public int Port { get; init; } = 43127;

    public string[] AllowedOrigins { get; init; } = [];

    public bool AllowLoopbackOrigins { get; init; } = true;

    public string BaseUrl => $"http://{Host}:{Port}";
}
