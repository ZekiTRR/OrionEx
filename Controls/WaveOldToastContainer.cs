using Avalonia;
using Avalonia.Animation;
using Avalonia.Animation.Easings;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Threading;
using System;
using System.Threading.Tasks;

namespace OrbitAvalonia.Controls;

public sealed class WaveOldToastContainer : StackPanel
{
    public static readonly StyledProperty<double> IntervalProperty =
        AvaloniaProperty.Register<WaveOldToastContainer, double>(nameof(Interval), 3.0);

    public static readonly StyledProperty<bool> ReverseProperty =
        AvaloniaProperty.Register<WaveOldToastContainer, bool>(nameof(Reverse), true);

    public double Interval
    {
        get => GetValue(IntervalProperty);
        set => SetValue(IntervalProperty, value);
    }

    public bool Reverse
    {
        get => GetValue(ReverseProperty);
        set => SetValue(ReverseProperty, value);
    }

    public WaveOldToastContainer()
    {
        HorizontalAlignment = HorizontalAlignment.Right;
        VerticalAlignment = VerticalAlignment.Bottom;
        Orientation = Orientation.Vertical;
        Margin = new Thickness(4, 25, 4, 0);
    }

    private void AddNotification(WaveOldToastNotification toast)
    {
        if (Reverse)
        {
            Children.Insert(0, toast);
        }
        else
        {
            Children.Add(toast);
        }

        RunScaleAnimation(toast, 1.5, 1.0, 17.5);
        RunOpacityAnimation(toast, 0.5, 1.0, async () =>
        {
            if (!toast.Dismissed)
            {
                await Task.Delay(TimeSpan.FromSeconds(Interval));
                RemoveNotification(toast);
            }
        });
    }

    private void RemoveNotification(WaveOldToastNotification toast)
    {
        if (toast.Dismissed) return;
        toast.Dismissed = true;
        RunScaleAnimation(toast, 1.5, 0.95, 17.5);
        RunOpacityAnimation(toast, 0.2, 0.0, () =>
        {
            if (Children.Contains(toast)) Children.Remove(toast);
        });
    }

    private static void RunScaleAnimation(WaveOldToastNotification toast, double from, double to, double springiness)
    {
        var transform = new ScaleTransform(0.95, 0.95);
        toast.RenderTransformOrigin = new RelativePoint(0.5, 0.5, RelativeUnit.Relative);
        toast.RenderTransform = transform;
        transform.ScaleX = from;
        transform.ScaleY = from;

        Dispatcher.UIThread.Post(async () =>
        {
            var startTime = DateTime.UtcNow;
            var duration = TimeSpan.FromMilliseconds(450);
            while (!toast.Dismissed || to == 0.95)
            {
                var elapsed = DateTime.UtcNow - startTime;
                if (elapsed >= duration) break;
                var t = elapsed.TotalMilliseconds / duration.TotalMilliseconds;
                // Use elastic-like easing approximation
                var eased = ElasticEase(t, from, to - from, springiness);
                transform.ScaleX = eased;
                transform.ScaleY = eased;
                await Task.Delay(16);
            }
            transform.ScaleX = to;
            transform.ScaleY = to;
        });
    }

    private static void RunOpacityAnimation(WaveOldToastNotification toast, double from, double to, Action? onComplete)
    {
        toast.Opacity = from;
        Dispatcher.UIThread.Post(async () =>
        {
            var startTime = DateTime.UtcNow;
            var duration = TimeSpan.FromMilliseconds(250);
            while (true)
            {
                var elapsed = DateTime.UtcNow - startTime;
                if (elapsed >= duration) break;
                var t = elapsed.TotalMilliseconds / duration.TotalMilliseconds;
                // QuarticEaseInOut approximation
                var eased = from + (to - from) * (t < 0.5 ? 8 * t * t * t * t : 1 - Math.Pow(-2 * t + 2, 4) / 2);
                toast.Opacity = eased;
                await Task.Delay(16);
            }
            toast.Opacity = to;
            onComplete?.Invoke();
        });
    }

    private static double ElasticEase(double t, double from, double to, double springiness)
    {
        // Simplified elastic ease-out
        if (t == 0 || t == 1) return from + to * t;
        var p = 0.3;
        var s = p / springiness;
        return from + to * Math.Pow(2, -10 * t) * Math.Sin((t - s) * (2 * Math.PI) / p) + to * t;
    }

    private void RegisterNotification(string title, string description, string footer, Action? action, ToastStyle style)
    {
        var toast = new WaveOldToastNotification
        {
            Title = title,
            Description = description,
            Footer = footer,
            Opacity = 0.0,
        };
        ApplyStyle(toast, style);
        toast.PointerPressed += (_, _) =>
        {
            RemoveNotification(toast);
            action?.Invoke();
        };
        AddNotification(toast);
    }

    private static void ApplyStyle(WaveOldToastNotification toast, ToastStyle style)
    {
        switch (style)
        {
            case ToastStyle.Success:
                toast.PrimaryColor = new SolidColorBrush(Color.FromRgb(0x3D, 0xA9, 0x5C));
                toast.SecondaryColor = new SolidColorBrush(Color.FromRgb(0x64, 0xCE, 0x83));
                toast.Icon = SuccessIcon;
                break;
            case ToastStyle.Error:
                toast.PrimaryColor = new SolidColorBrush(Color.FromRgb(0xBA, 0x2C, 0x1D));
                toast.SecondaryColor = new SolidColorBrush(Color.FromRgb(0xE7, 0x4C, 0x3C));
                toast.Icon = ErrorIcon;
                break;
            case ToastStyle.Info:
                toast.PrimaryColor = new SolidColorBrush(Color.FromRgb(0x06, 0x7C, 0xEA));
                toast.SecondaryColor = new SolidColorBrush(Color.FromRgb(0x3E, 0xA2, 0xFF));
                toast.Icon = InfoIcon;
                break;
            case ToastStyle.Warning:
                toast.PrimaryColor = new SolidColorBrush(Color.FromRgb(0xF4, 0x4E, 0x06));
                toast.SecondaryColor = new SolidColorBrush(Color.FromRgb(0xFF, 0x7F, 0x48));
                toast.Icon = WarningIcon;
                break;
        }
    }

    public void Success(string title, string description = "", string footer = "", Action? action = null)
        => RegisterNotification(title, description, footer, action, ToastStyle.Success);

    public void Error(string title, string description = "", string footer = "", Action? action = null)
        => RegisterNotification(title, description, footer, action, ToastStyle.Error);

    public void Info(string title, string description = "", string footer = "", Action? action = null)
        => RegisterNotification(title, description, footer, action, ToastStyle.Info);

    public void Warning(string title, string description = "", string footer = "", Action? action = null)
        => RegisterNotification(title, description, footer, action, ToastStyle.Warning);

    private enum ToastStyle { Success, Error, Info, Warning }

    private static readonly StreamGeometry SuccessIcon = Parse("M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17Z");
    private static readonly StreamGeometry ErrorIcon = Parse("M19 6.41 17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41Z");
    private static readonly StreamGeometry InfoIcon = Parse("M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z");
    private static readonly StreamGeometry WarningIcon = Parse("M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z");

    private static StreamGeometry Parse(string path) => StreamGeometry.Parse(path);
}
