using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.VisualTree;
using System.Diagnostics;
using System.Threading.Tasks;
using System;

namespace OrbitAvalonia;

public sealed partial class SentinelSettingsWindow : Window
{
    private readonly SentinelWindow? _owner;
    private readonly SentinelOptions _options;
    private bool _loading;

    public event Action? OptionsChanged;

    public SentinelSettingsWindow() : this(null, new SentinelOptions())
    {
    }

    internal SentinelSettingsWindow(SentinelWindow? owner, SentinelOptions options)
    {
        _owner = owner;
        _options = options;
        AvaloniaXamlLoader.Load(this);

        _loading = true;
        SetCheck("OptUnlockFps", options.UnlockFps);
        SetCheck("OptAutoLaunch", options.AutoLaunch);
        SetCheck("OptAutoAttach", options.AutoAttach);
        SetCheck("OptInternalUi", options.InternalUi);
        SetCheck("OptLegacyUi", options.LegacyUi);
        SetCheck("OptTopMost", options.TopMost);
        _loading = false;

        if (owner is not null)
        {
            Position = new PixelPoint(
                Math.Max(0, owner.Position.X - (int)Width - 12),
                owner.Position.Y);
        }
    }

    private void SetCheck(string name, bool value)
    {
        if (this.FindControl<CheckBox>(name) is { } box)
        {
            box.IsChecked = value;
        }
    }

    private void Opt_Changed(object? sender, RoutedEventArgs e)
    {
        if (_loading) return;
        if (sender is not CheckBox { Name: { } name } box) return;

        var value = box.IsChecked == true;
        switch (name)
        {
            case "OptUnlockFps": _options.UnlockFps = value; break;
            case "OptAutoLaunch": _options.AutoLaunch = value; break;
            case "OptAutoAttach": _options.AutoAttach = value; break;
            case "OptInternalUi": _options.InternalUi = value; break;
            case "OptLegacyUi": _options.LegacyUi = value; break;
            case "OptTopMost": _options.TopMost = value; break;
        }

        SentinelOptionsStore.Save(_options);
        OptionsChanged?.Invoke();
    }

    private void KillRoblox_Click(object? sender, RoutedEventArgs e)
    {
        try
        {
            foreach (var process in Process.GetProcessesByName("RobloxPlayerBeta"))
            {
                try { process.Kill(true); }
                finally { process.Dispose(); }
            }
        }
        catch { }
    }

    private void Close_Click(object? sender, RoutedEventArgs e)
    {
        if (_owner != null)
        {
            _ = _owner.RequestReturnToOrionAsync();
        }
        else
        {
            Close();
        }
    }

    private void ReturnToOrion_Click(object? sender, RoutedEventArgs e)
    {
        if (_owner != null)
        {
            _ = _owner.RequestReturnToOrionAsync();
        }
        else
        {
            Close();
        }
    }

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Avalonia.Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
        BeginMoveDrag(e);
    }
}