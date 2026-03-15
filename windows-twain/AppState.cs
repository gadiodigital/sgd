namespace WindowsTwain;

internal sealed class AppState
{
    public AppState(ApiOptions apiOptions, string runMode, string startupLogPath)
    {
        ApiOptions = apiOptions;
        StartedAtUtc = DateTimeOffset.UtcNow;
        RunMode = runMode;
        StartupLogPath = startupLogPath;
    }

    public ApiOptions ApiOptions { get; }

    public DateTimeOffset StartedAtUtc { get; }

    public string ApplicationName => "windows-twain";

    public string Version => typeof(AppState).Assembly.GetName().Version?.ToString() ?? "1.0.0";

    public string RunMode { get; }

    public string StartupLogPath { get; }
}
