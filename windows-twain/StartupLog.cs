namespace WindowsTwain;

internal static class StartupLog
{
    private static readonly object Sync = new();

    public static string LogFilePath { get; } = Path.Combine(AppContext.BaseDirectory, "windows-twain.log");

    public static void Write(string message)
    {
        try
        {
            lock (Sync)
            {
                File.AppendAllText(
                    LogFilePath,
                    $"[{DateTimeOffset.Now:O}] {message}{Environment.NewLine}");
            }
        }
        catch
        {
            // El logging nunca debe impedir el arranque.
        }
    }
}
