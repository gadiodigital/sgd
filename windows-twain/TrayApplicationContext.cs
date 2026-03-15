using System.Diagnostics;
using System.Drawing;

namespace WindowsTwain;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private readonly LocalApiHost apiHost;
    private readonly AppState appState;
    private readonly IScannerService scannerService;
    private readonly NotifyIcon notifyIcon;

    public TrayApplicationContext(LocalApiHost apiHost, AppState appState, IScannerService scannerService)
    {
        this.apiHost = apiHost;
        this.appState = appState;
        this.scannerService = scannerService;

        notifyIcon = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "windows-twain",
            Visible = true,
            ContextMenuStrip = BuildMenu()
        };

        notifyIcon.DoubleClick += (_, _) => OpenUrl(apiHost.StatusUrl);
        notifyIcon.ShowBalloonTip(
            timeout: 2500,
            tipTitle: "windows-twain",
            tipText: $"API local iniciada en {apiHost.BaseUrl}",
            tipIcon: ToolTipIcon.Info);
    }

    protected override void ExitThreadCore()
    {
        notifyIcon.Visible = false;
        notifyIcon.Dispose();
        apiHost.StopAsync(CancellationToken.None).GetAwaiter().GetResult();
        base.ExitThreadCore();
    }

    private ContextMenuStrip BuildMenu()
    {
        var menu = new ContextMenuStrip();
        menu.Items.Add("Estado", null, (_, _) => ShowStatus());
        menu.Items.Add("Abrir health", null, (_, _) => OpenUrl(apiHost.HealthUrl));
        menu.Items.Add("Abrir status", null, (_, _) => OpenUrl(apiHost.StatusUrl));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Salir", null, (_, _) => ExitThread());
        return menu;
    }

    private void ShowStatus()
    {
        var scannerStatus = scannerService.GetStatus();
        var allowedOrigins = appState.ApiOptions.AllowedOrigins.Length == 0
            ? "(sin origenes explicitos configurados)"
            : string.Join(", ", appState.ApiOptions.AllowedOrigins);
        var loopbackOrigins = appState.ApiOptions.AllowLoopbackOrigins ? "habilitado" : "deshabilitado";

        var message = string.Join(
            Environment.NewLine,
            $"API: {apiHost.BaseUrl}",
            $"Inicio UTC: {appState.StartedAtUtc:O}",
            $"Version: {appState.Version}",
            $"Escaner: {scannerStatus.Message}",
            $"CORS explicito: {allowedOrigins}",
            $"CORS loopback: {loopbackOrigins}");

        MessageBox.Show(
            message,
            "windows-twain",
            MessageBoxButtons.OK,
            MessageBoxIcon.Information);
    }

    private static void OpenUrl(string url)
    {
        Process.Start(new ProcessStartInfo
        {
            FileName = url,
            UseShellExecute = true
        });
    }
}
