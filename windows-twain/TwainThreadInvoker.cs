namespace WindowsTwain;

internal sealed class TwainThreadInvoker : IDisposable
{
    private readonly ManualResetEventSlim ready = new(false);
    private readonly Thread thread;
    private Control? control;

    public TwainThreadInvoker()
    {
        thread = new Thread(ThreadMain)
        {
            IsBackground = true,
            Name = "windows-twain-twain-thread"
        };
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        ready.Wait();
    }

    public T Invoke<T>(Func<T> action)
    {
        if (control is null)
        {
            throw new InvalidOperationException("El hilo TWAIN no esta inicializado.");
        }

        var completion = new TaskCompletionSource<T>(TaskCreationOptions.RunContinuationsAsynchronously);
        control.BeginInvoke(new MethodInvoker(() =>
        {
            try
            {
                completion.SetResult(action());
            }
            catch (Exception ex)
            {
                completion.SetException(ex);
            }
        }));

        return completion.Task.GetAwaiter().GetResult();
    }

    public void Dispose()
    {
        if (control?.IsHandleCreated == true)
        {
            control.BeginInvoke(new MethodInvoker(Application.ExitThread));
        }

        thread.Join(TimeSpan.FromSeconds(5));
        control?.Dispose();
        ready.Dispose();
    }

    private void ThreadMain()
    {
        control = new Control();
        control.CreateControl();
        ready.Set();
        Application.Run();
    }
}
