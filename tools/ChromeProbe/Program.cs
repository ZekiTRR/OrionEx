using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Threading;
using System.Runtime.InteropServices;

internal static class Program
{
    public static int Result = 1;
    [STAThread]
    public static int Main(string[] args)
    {
        AppBuilder.Configure<ChromeApp>().UsePlatformDetect().StartWithClassicDesktopLifetime([]);
        return Result;
    }
    [StructLayout(LayoutKind.Sequential)] internal struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] internal struct POINT { public int X, Y; }
    [DllImport("user32.dll")] internal static extern bool GetWindowRect(IntPtr window, out RECT rect);
    [DllImport("user32.dll")] internal static extern int MapWindowPoints(IntPtr from, IntPtr to, ref POINT point, uint count);

    internal static double TopInset(Window window)
    {
        var handle = window.TryGetPlatformHandle()?.Handle ?? IntPtr.Zero;
        GetWindowRect(handle, out RECT frame);
        var client = new POINT { X = 0, Y = 0 };
        MapWindowPoints(handle, IntPtr.Zero, ref client, 1);
        return client.Y - frame.T;
    }
}
internal sealed class ChromeApp : Application
{
    public override async void OnFrameworkInitializationCompleted()
    {
        var desktop = (IClassicDesktopStyleApplicationLifetime)ApplicationLifetime!;
        var withoutHint = new Window { Width = 400, Height = 300, WindowDecorations = WindowDecorations.BorderOnly, Title = "nohint" };
        var withHint = new Window { Width = 400, Height = 300, WindowDecorations = WindowDecorations.BorderOnly, ExtendClientAreaToDecorationsHint = true, Title = "hint" };
        desktop.MainWindow = withoutHint;
        withoutHint.Show();
        withHint.Show();
        await Dispatcher.UIThread.InvokeAsync(() => { });
        await Task.Delay(500);
        var noHint = Program.TopInset(withoutHint);
        var hint = Program.TopInset(withHint);
        Console.WriteLine($"CHROME noHintTopInset={noHint} withHintTopInset={hint}");
        withoutHint.Close(); withHint.Close();
        if (noHint < 15) { Console.Error.WriteLine("CHROME_FAIL expected a native caption on the plain BorderOnly window"); }
        else if (hint > 10) { Console.Error.WriteLine("CHROME_FAIL ExtendClientAreaToDecorationsHint did not remove the native caption band"); }
        else { Console.WriteLine("CHROME_PASS ExtendClientAreaToDecorationsHint removes the native title bar band"); Program.Result = 0; }
        desktop.Shutdown(Program.Result);
    }
}
