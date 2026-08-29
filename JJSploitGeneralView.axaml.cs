using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;

namespace OrbitAvalonia;

public partial class JJSploitGeneralView : UserControl
{
    public event EventHandler<string>? QuickCommandRequested;
    public event EventHandler<string>? WalkSpeedExecuteRequested;
    public event EventHandler<string>? JumpPowerExecuteRequested;
    public event EventHandler<string>? TeleportExecuteRequested;
    public event EventHandler? LuaExecuteRequested;
    public event EventHandler? LuaOpenFileRequested;

    private TextBlock? _tabButtons;
    private TextBlock? _tabLua;
    private ScrollViewer? _buttonsTab;
    private Grid? _luaTab;
    private TextBox? _magnetizeInput;
    private TextBox? _tpX;
    private TextBox? _tpY;
    private TextBox? _tpZ;
    private ComboBox? _walkSpeedCombo;
    private ComboBox? _jumpPowerCombo;

    public JJSploitGeneralView()
    {
        AvaloniaXamlLoader.Load(this);
        _tabButtons = this.FindControl<TextBlock>("TabButtons");
        _tabLua = this.FindControl<TextBlock>("TabLua");
        _buttonsTab = this.FindControl<ScrollViewer>("ButtonsTab");
        _luaTab = this.FindControl<Grid>("LuaTab");
        _magnetizeInput = this.FindControl<TextBox>("MagnetizeInput");
        _walkSpeedCombo = this.FindControl<ComboBox>("WalkSpeedCombo");
        _jumpPowerCombo = this.FindControl<ComboBox>("JumpPowerCombo");
        _tpX = this.FindControl<TextBox>("TpX");
        _tpY = this.FindControl<TextBox>("TpY");
        _tpZ = this.FindControl<TextBox>("TpZ");

        // Open straight to the Lua tab (Monaco editor) so the WebView gets a
        // real size on first paint. The Buttons tab is still reachable via
        // the tab strip.
        SelectTab("Lua");
    }

    public void SelectTab(string name)
    {
        if (_buttonsTab is not null) _buttonsTab.IsVisible = name == "Buttons";
        if (_luaTab is not null) _luaTab.IsVisible = name == "Lua";
    }

    private void TabButtons_Click(object? sender, PointerPressedEventArgs e) => SelectTab("Buttons");
    private void TabLua_Click(object? sender, PointerPressedEventArgs e) => SelectTab("Lua");

    private void Cmd_Click(object? sender, RoutedEventArgs e)
    {
        if (sender is Control { Tag: string cmd })
        {
            QuickCommandRequested?.Invoke(this, cmd);
        }
    }

    private void Magnetize_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            QuickCommandRequested?.Invoke(this, "Magnetize to: " + (_magnetizeInput?.Text ?? ""));
        }
    }

    private void TpVector_Click(object? sender, RoutedEventArgs e)
    {
        var x = _tpX?.Text?.Trim() ?? "0";
        var y = _tpY?.Text?.Trim() ?? "0";
        var z = _tpZ?.Text?.Trim() ?? "0";
        TeleportExecuteRequested?.Invoke(this, $"{x}|{y}|{z}");
    }

    private void WalkSpeed_Changed(object? sender, SelectionChangedEventArgs e)
    {
        var v = SelectedComboValue(_walkSpeedCombo);
        if (v.Length > 0) WalkSpeedExecuteRequested?.Invoke(this, v);
    }

    private void JumpPower_Changed(object? sender, SelectionChangedEventArgs e)
    {
        var v = SelectedComboValue(_jumpPowerCombo);
        if (v.Length > 0) JumpPowerExecuteRequested?.Invoke(this, v);
    }

    private static string SelectedComboValue(ComboBox? combo)
    {
        if (combo is null) return string.Empty;
        if (combo.SelectedItem is ComboBoxItem item)
        {
            return item.Content?.ToString() ?? string.Empty;
        }
        return combo.SelectedValue?.ToString() ?? string.Empty;
    }

    private void LuaExecute_Click(object? sender, RoutedEventArgs e)
        => LuaExecuteRequested?.Invoke(this, EventArgs.Empty);

    private void LuaOpen_Click(object? sender, RoutedEventArgs e)
        => LuaOpenFileRequested?.Invoke(this, EventArgs.Empty);
}
