using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Threading;
using Avalonia.VisualTree;
using System.Diagnostics;

namespace OrbitAvalonia;

// Universal companion console: a standalone window that mirrors the Orion
// bridge log. It opens alongside any menu instead of replacing it.
public sealed partial class OrionConsoleWindow : Window
{
    private const int MaxConsoleLines = 500;

    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;

    private readonly Border _chrome;
    private readonly ScrollViewer _consoleScroll;
    private readonly StackPanel _consoleOutput;
    private readonly TextBlock _lineCountText;
    private readonly Button _topMostButton;

    private bool _consoleDisposed;
    private CancellationTokenSource? _fx;

    public OrionConsoleWindow()
    {
        AvaloniaXamlLoader.Load(this);

        _chrome = Required<Border>("CnChrome");
        _consoleScroll = Required<ScrollViewer>("ConsoleScroll");
        _consoleOutput = Required<StackPanel>("ConsoleOutput");
        _lineCountText = Required<TextBlock>("LineCountText");
        _topMostButton = Required<Button>("TopMostButton");

        foreach (var entry in _bridge.GetLogSnapshot())
        {
            AppendConsoleLine(entry.Level, entry.Message);
        }

        _bridge.LogReceived += Bridge_LogReceived;

        Opened += OrionConsoleWindow_Opened;
        Closed += OrionConsoleWindow_Closed;
    }

    private T Required<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException($"Console control '{name}' was not created.");

    // ─────────────────────────── lifecycle ───────────────────────────

    private async void OrionConsoleWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= OrionConsoleWindow_Opened;

        _chrome.Opacity = 0;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(200),
                progress => _chrome.Opacity = progress,
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _chrome.Opacity = 1;
    }

    private void OrionConsoleWindow_Closed(object? sender, EventArgs e)
    {
        _consoleDisposed = true;
        _bridge.LogReceived -= Bridge_LogReceived;
    }

    private void Bridge_LogReceived(string level, string message) =>
        Dispatcher.UIThread.Post(() => AppendConsoleLine(level, message));

    // ─────────────────────────── title bar ───────────────────────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed)
        {
            return;
        }

        if (e.Source is Avalonia.Visual visual &&
            (visual is Button || visual.GetVisualAncestors().OfType<Button>().Any()))
        {
            return;
        }

        if (e.ClickCount == 2 && CanResize)
        {
            WindowState = WindowState == WindowState.Maximized
                ? WindowState.Normal
                : WindowState.Maximized;
            return;
        }

        if (WindowState != WindowState.Maximized)
        {
            BeginMoveDrag(e);
        }
    }

    private void Minimize_Click(object? sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void Maximize_Click(object? sender, RoutedEventArgs e)
    {
        WindowState = WindowState == WindowState.Maximized
            ? WindowState.Normal
            : WindowState.Maximized;
    }

    private void Close_Click(object? sender, RoutedEventArgs e) => Close();

    // ─────────────────────────── console ───────────────────────────

    private void AppendConsoleLine(string level, string message)
    {
        if (_consoleDisposed || _consoleOutput is null)
        {
            return;
        }

        var normalized = string.IsNullOrWhiteSpace(level) ? "info" : level.ToLowerInvariant();
        var prefix = normalized switch
        {
            "warn" or "warning" => "[warn]   ",
            "error" => "[error]  ",
            "print" or "output" => "[print]  ",
            _ => "[info]   "
        };
        var color = normalized switch
        {
            "warn" or "warning" => "#C8A25A",
            "error" => "#D06B6B",
            "print" or "output" => "#9CCB6B",
            _ => "#B8B8BA"
        };

        var line = new TextBlock
        {
            Text = prefix + message,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 11.5,
            Foreground = new SolidColorBrush(Color.Parse(color)),
            TextWrapping = TextWrapping.Wrap
        };
        _consoleOutput.Children.Add(line);
        while (_consoleOutput.Children.Count > MaxConsoleLines)
        {
            _consoleOutput.Children.RemoveAt(0);
        }

        _lineCountText.Text = $"{_consoleOutput.Children.Count} lines";
        Dispatcher.UIThread.Post(line.BringIntoView, DispatcherPriority.Background);
    }

    private void Clear_Click(object? sender, RoutedEventArgs e)
    {
        _consoleOutput.Children.Clear();
        _lineCountText.Text = "0 lines";
    }

    private void TopMost_Click(object? sender, RoutedEventArgs e)
    {
        Topmost = !Topmost;
        SetClass(_topMostButton.Classes, "checked", Topmost);
    }

    // ─────────────────────────── helpers ───────────────────────────

    private static void SetClass(Classes classes, string className, bool enabled)
    {
        if (enabled)
        {
            classes.Add(className);
        }
        else
        {
            classes.Remove(className);
        }
    }

    private CancellationToken RestartFx()
    {
        _fx?.Cancel();
        _fx?.Dispose();
        _fx = new CancellationTokenSource();
        return _fx.Token;
    }

    private static async Task AnimateAsync(
        TimeSpan duration,
        Action<double> update,
        Func<double, double> easing,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        while (stopwatch.Elapsed < duration)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var progress = Math.Clamp(
                stopwatch.Elapsed.TotalMilliseconds / duration.TotalMilliseconds,
                0d,
                1d);
            update(easing(progress));
            await Task.Delay(8, cancellationToken);
        }

        update(1d);
    }

    private static double CubicEaseOut(double progress) => 1d - Math.Pow(1d - progress, 3d);
}
