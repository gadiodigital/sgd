namespace WindowsTwain;

internal sealed class RunMode
{
    private RunMode(bool isHeadless, string name)
    {
        IsHeadless = isHeadless;
        Name = name;
    }

    public bool IsHeadless { get; }

    public string Name { get; }

    public static RunMode Parse(IEnumerable<string> args)
    {
        var normalized = args.Select(arg => arg.Trim().ToLowerInvariant()).ToHashSet();
        if (normalized.Contains("--headless") || normalized.Contains("--headeless"))
        {
            return new RunMode(isHeadless: true, name: "headless");
        }

        return new RunMode(isHeadless: false, name: "tray");
    }
}
