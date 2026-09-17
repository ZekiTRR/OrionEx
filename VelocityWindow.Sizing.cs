using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Threading;

namespace OrbitAvalonia;

public sealed partial class VelocityWindow
{
    private void ToggleMaximize()
    {
        if (CanResize) WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;
    }

    private void InitializeWindowSizing()
    {
        var saveTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(400) };
        saveTimer.Tick += (_, _) => { saveTimer.Stop(); SaveOptions(); };
        SizeChanged += (_, _) =>
        {
            ApplyPanels();
            if (!IsVisible || WindowState != WindowState.Normal) return;
            _options.WindowWidth = Math.Clamp(ClientSize.Width, 560, 7680);
            _options.WindowHeight = Math.Clamp(ClientSize.Height, 360, 4320);
            saveTimer.Stop(); saveTimer.Start();
        };
        Closed += (_, _) => { saveTimer.Stop(); };
        Opened += (_, _) =>
        {
            if (Screens.ScreenFromWindow(this) is { } screen)
            {
                Width = Math.Min(Width, screen.WorkingArea.Width / screen.Scaling);
                Height = Math.Min(Height, screen.WorkingArea.Height / screen.Scaling);
            }
            ApplyPanels();
        };
        void Grip(WindowEdge edge, HorizontalAlignment horizontal, VerticalAlignment vertical, StandardCursorType cursor)
        {
            var grip = new Border { Background = Brushes.Transparent, HorizontalAlignment = horizontal, VerticalAlignment = vertical, Cursor = new(cursor) };
            if (horizontal != HorizontalAlignment.Stretch) grip.Width = vertical == VerticalAlignment.Stretch ? 5 : 10;
            if (vertical != VerticalAlignment.Stretch) grip.Height = horizontal == HorizontalAlignment.Stretch ? 5 : 10;
            grip.Bind(IsVisibleProperty, this.GetObservable(CanResizeProperty));
            grip.PointerPressed += (_, e) =>
            {
                if (!CanResize || WindowState != WindowState.Normal || !e.GetCurrentPoint(this).Properties.IsLeftButtonPressed) return;
                BeginResizeDrag(edge, e); e.Handled = true;
            };
            _root.Children.Add(grip);
        }
        Grip(WindowEdge.West, HorizontalAlignment.Left, VerticalAlignment.Stretch, StandardCursorType.SizeWestEast);
        Grip(WindowEdge.East, HorizontalAlignment.Right, VerticalAlignment.Stretch, StandardCursorType.SizeWestEast);
        Grip(WindowEdge.North, HorizontalAlignment.Stretch, VerticalAlignment.Top, StandardCursorType.SizeNorthSouth);
        Grip(WindowEdge.South, HorizontalAlignment.Stretch, VerticalAlignment.Bottom, StandardCursorType.SizeNorthSouth);
        Grip(WindowEdge.NorthWest, HorizontalAlignment.Left, VerticalAlignment.Top, StandardCursorType.TopLeftCorner);
        Grip(WindowEdge.NorthEast, HorizontalAlignment.Right, VerticalAlignment.Top, StandardCursorType.TopRightCorner);
        Grip(WindowEdge.SouthWest, HorizontalAlignment.Left, VerticalAlignment.Bottom, StandardCursorType.BottomLeftCorner);
        Grip(WindowEdge.SouthEast, HorizontalAlignment.Right, VerticalAlignment.Bottom, StandardCursorType.BottomRightCorner);
    }

    private void BuildWindowSizeSettings(StackPanel host)
    {
        host.Children.Add(Card("Allow window resizing", "Drag any window edge or corner. Panels adapt automatically; the normal window size is remembered.", Toggle(_options.AllowResize, enabled =>
        {
            if (!enabled && WindowState == WindowState.Maximized) WindowState = WindowState.Normal;
            CanResize = _options.AllowResize = enabled;
        })));
        var width = new NumericUpDown { Minimum = 560, Maximum = 7680, Value = (decimal)_options.WindowWidth, Increment = 20, Width = 130, FormatString = "0" };
        var height = new NumericUpDown { Minimum = 360, Maximum = 4320, Value = (decimal)_options.WindowHeight, Increment = 20, Width = 130, FormatString = "0" };
        host.Children.Add(Card("Window width", "Logical pixels; minimum 560.", width));
        host.Children.Add(Card("Window height", "Logical pixels; minimum 360.", height));
        var actions = new WrapPanel();
        actions.Children.Add(MakeButton("Apply size", () =>
        {
            WindowState = WindowState.Normal;
            Width = (double)(width.Value ?? 920); Height = (double)(height.Value ?? 620);
        }));
        actions.Children.Add(MakeButton("Reset size", () =>
        {
            WindowState = WindowState.Normal;
            Width = 920; Height = 620; width.Value = 920; height.Value = 620;
        }));
        host.Children.Add(actions);
    }
}
