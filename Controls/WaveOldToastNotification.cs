using Avalonia;
using Avalonia.Animation;
using Avalonia.Animation.Easings;
using Avalonia.Controls;
using Avalonia.Controls.Primitives;
using Avalonia.Controls.Shapes;
using Avalonia.Data;
using Avalonia.Input;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Threading;
using System;
using System.Threading.Tasks;

namespace OrbitAvalonia.Controls;

public sealed class WaveOldToastNotification : ContentControl
{
    public static readonly StyledProperty<string> TitleProperty =
        AvaloniaProperty.Register<WaveOldToastNotification, string>(nameof(Title), string.Empty);

    public static readonly StyledProperty<string> DescriptionProperty =
        AvaloniaProperty.Register<WaveOldToastNotification, string>(nameof(Description), string.Empty);

    public static readonly StyledProperty<string> FooterProperty =
        AvaloniaProperty.Register<WaveOldToastNotification, string>(nameof(Footer), string.Empty);

    public static readonly StyledProperty<Geometry> IconProperty =
        AvaloniaProperty.Register<WaveOldToastNotification, Geometry>(nameof(Icon));

    public static readonly StyledProperty<IBrush> PrimaryColorProperty =
        AvaloniaProperty.Register<WaveOldToastNotification, IBrush>(nameof(PrimaryColor), Brushes.Transparent);

    public static readonly StyledProperty<IBrush> SecondaryColorProperty =
        AvaloniaProperty.Register<WaveOldToastNotification, IBrush>(nameof(SecondaryColor), Brushes.Transparent);

    public string Title
    {
        get => GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public string Description
    {
        get => GetValue(DescriptionProperty);
        set => SetValue(DescriptionProperty, value);
    }

    public string Footer
    {
        get => GetValue(FooterProperty);
        set => SetValue(FooterProperty, value);
    }

    public Geometry Icon
    {
        get => GetValue(IconProperty);
        set => SetValue(IconProperty, value);
    }

    public IBrush PrimaryColor
    {
        get => GetValue(PrimaryColorProperty);
        set => SetValue(PrimaryColorProperty, value);
    }

    public IBrush SecondaryColor
    {
        get => GetValue(SecondaryColorProperty);
        set => SetValue(SecondaryColorProperty, value);
    }

    public bool Dismissed { get; set; }

    public WaveOldToastNotification()
    {
        BuildVisual();
    }

    private Border? _rootBorder;
    private TextBlock? _titleText;
    private TextBlock? _descriptionText;
    private Border? _footerBorder;

    private void BuildVisual()
    {
        var root = new Border
        {
            MinHeight = 36,
            MinWidth = 240,
            MaxWidth = 480,
            CornerRadius = new CornerRadius(5),
            Margin = new Thickness(25, 0, 25, 10),
            Padding = new Thickness(0),
        };
        root.Bind(Border.BackgroundProperty, new Binding(nameof(SecondaryColor)) { Source = this });

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition(30, GridUnitType.Pixel));
        grid.ColumnDefinitions.Add(new ColumnDefinition(1, GridUnitType.Star));

        // Left colored bar with icon
        var iconBar = new Border
        {
            Width = 30,
            CornerRadius = new CornerRadius(5, 0, 0, 5),
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        iconBar.Bind(Border.BackgroundProperty, new Binding(nameof(PrimaryColor)) { Source = this });
        Grid.SetColumn(iconBar, 0);

        var iconPath = new Avalonia.Controls.Shapes.Path
        {
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Center,
            Width = 16,
            Height = 16,
            Margin = new Thickness(0, 10, 0, 0),
            Stretch = Stretch.Uniform,
            Fill = Brushes.White,
        };
        iconPath.Bind(Avalonia.Controls.Shapes.Path.DataProperty, new Binding(nameof(Icon)) { Source = this });
        iconBar.Child = iconPath;

        grid.Children.Add(iconBar);

        // Content panel
        var content = new StackPanel
        {
            Margin = new Thickness(10, 10, 10, 0),
        };
        Grid.SetColumn(content, 1);

        _titleText = new TextBlock
        {
            Foreground = Brushes.White,
            FontSize = 14,
            FontWeight = FontWeight.SemiBold,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            TextAlignment = TextAlignment.Left,
            TextWrapping = TextWrapping.Wrap,
            HorizontalAlignment = HorizontalAlignment.Left,
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, -2, 0, 10),
        };
        _titleText.Bind(TextBlock.TextProperty, new Binding(nameof(Title)) { Source = this });
        content.Children.Add(_titleText);

        _descriptionText = new TextBlock
        {
            Foreground = Brushes.White,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            TextAlignment = TextAlignment.Left,
            TextWrapping = TextWrapping.Wrap,
            HorizontalAlignment = HorizontalAlignment.Left,
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 0, 10),
        };
        _descriptionText.Bind(TextBlock.TextProperty, new Binding(nameof(Description)) { Source = this });
        content.Children.Add(_descriptionText);

        _footerBorder = new Border
        {
            CornerRadius = new CornerRadius(5),
            HorizontalAlignment = HorizontalAlignment.Left,
            Margin = new Thickness(0, 0, 0, 10),
            Padding = new Thickness(5, 3, 5, 5),
        };
        _footerBorder.Bind(Border.BackgroundProperty, new Binding(nameof(PrimaryColor)) { Source = this });
        var footerText = new TextBlock
        {
            Foreground = Brushes.White,
            FontSize = 10,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            TextAlignment = TextAlignment.Left,
            TextWrapping = TextWrapping.Wrap,
            HorizontalAlignment = HorizontalAlignment.Left,
            VerticalAlignment = VerticalAlignment.Top,
        };
        footerText.Bind(TextBlock.TextProperty, new Binding(nameof(Footer)) { Source = this });
        _footerBorder.Child = footerText;
        content.Children.Add(_footerBorder);

        grid.Children.Add(content);
        root.Child = grid;
        _rootBorder = root;
        Content = root;

        PropertyChanged += (_, e) =>
        {
            if (e.Property == TitleProperty) UpdateTitleVisibility();
            else if (e.Property == DescriptionProperty) UpdateDescriptionVisibility();
            else if (e.Property == FooterProperty) UpdateFooterVisibility();
        };
    }

    private void UpdateTitleVisibility()
    {
        if (_titleText != null) _titleText.IsVisible = !string.IsNullOrEmpty(Title);
    }

    private void UpdateDescriptionVisibility()
    {
        if (_descriptionText != null) _descriptionText.IsVisible = !string.IsNullOrEmpty(Description);
    }

    private void UpdateFooterVisibility()
    {
        if (_footerBorder != null) _footerBorder.IsVisible = !string.IsNullOrEmpty(Footer);
    }
}
