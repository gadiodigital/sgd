namespace WindowsTwain;

internal sealed class HeadlessApplicationContext : ApplicationContext
{
    private readonly LocalApiHost apiHost;

    public HeadlessApplicationContext(LocalApiHost apiHost)
    {
        this.apiHost = apiHost;
    }

    protected override void ExitThreadCore()
    {
        apiHost.StopAsync(CancellationToken.None).GetAwaiter().GetResult();
        base.ExitThreadCore();
    }
}
