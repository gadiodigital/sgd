using Microsoft.Extensions.Configuration;

namespace WindowsTwain;

internal static class Program
{
    private const string SingleInstanceMutexName = @"Local\windows-twain-single-instance";
    private const string SingleInstanceMutexEnvironmentVariableName = "WINDOWS_TWAIN_SINGLE_INSTANCE_MUTEX_NAME";

    [STAThread]
    private static void Main()
    {
        var runMode = RunMode.Parse(Environment.GetCommandLineArgs().Skip(1));
        StartupLog.Write($"Inicio de windows-twain en modo {runMode.Name}.");

        using var mutex = new Mutex(initiallyOwned: true, ResolveMutexName(), out var createdNew);
        if (!createdNew)
        {
            StartupLog.Write("Se detecto una segunda instancia y se cancelo el inicio.");
            if (!runMode.IsHeadless)
            {
                MessageBox.Show(
                    "windows-twain ya se encuentra en ejecucion.",
                    "windows-twain",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            return;
        }

        ApplicationConfiguration.Initialize();

        var apiOptions = LoadApiOptions();
        var appState = new AppState(apiOptions, runMode.Name, StartupLog.LogFilePath);
        IScannerService scannerService = new TwainScannerService();

        try
        {
            using var apiHost = new LocalApiHost(apiOptions, appState, scannerService);
            apiHost.StartAsync(CancellationToken.None).GetAwaiter().GetResult();
            StartupLog.Write($"API local iniciada en {apiOptions.BaseUrl}.");

            if (runMode.IsHeadless)
            {
                Application.Run(new HeadlessApplicationContext(apiHost));
            }
            else
            {
                Application.Run(new TrayApplicationContext(apiHost, appState, scannerService));
            }
        }
        catch (Exception ex)
        {
            StartupLog.Write("Error de inicio: " + ex);
            if (!runMode.IsHeadless)
            {
                MessageBox.Show(
                    $"No fue posible iniciar windows-twain.{Environment.NewLine}{Environment.NewLine}{ex.Message}",
                    "windows-twain",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }
    }

    private static ApiOptions LoadApiOptions()
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
            .AddEnvironmentVariables(prefix: "WINDOWS_TWAIN_")
            .Build();

        return configuration.GetSection(ApiOptions.SectionName).Get<ApiOptions>() ?? new ApiOptions();
    }

    private static string ResolveMutexName()
    {
        var configuredName = Environment.GetEnvironmentVariable(SingleInstanceMutexEnvironmentVariableName)?.Trim();
        return string.IsNullOrWhiteSpace(configuredName)
            ? SingleInstanceMutexName
            : configuredName;
    }
}
