using Avalonia.Controls;
using Avalonia.Platform.Storage;
using System.Diagnostics;
using System.Text.Json.Nodes;

namespace OrbitAvalonia;

public sealed partial class SynapseV3AltWindow
{
    private static readonly string[] ScriptExtensions = [".lua", ".luau", ".txt", ".json"];

    // Absolute paths are accepted only inside Scripts or for an exact file selected
    // in a native dialog. Workspace metadata never grants filesystem permission.
    private string ResolveScript(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) throw new ArgumentException("A script path is required.");
        var normalized = input.Replace('/', '\\');
        if (normalized.StartsWith("\\\\", StringComparison.Ordinal) || normalized.Split('\\').Any(p => p is "." or ".."))
            throw new UnauthorizedAccessException("Network paths and path traversal are not permitted.");
        var path = Path.GetFullPath(Path.IsPathFullyQualified(input) ? input : Path.Combine(_scriptsDirectory, input));
        if (path[Path.GetPathRoot(path)!.Length..].Contains(':'))
            throw new UnauthorizedAccessException("Alternate data streams are not permitted.");
        if (!path.StartsWith(_scriptsDirectory + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) && !_dialogFiles.Contains(path))
            throw new UnauthorizedAccessException("Access is limited to Scripts and explicitly selected files.");
        EnsureNoLinks(path);
        return path;
    }

    private static void EnsureNoLinks(string path)
    {
        for (string? current = Path.GetFullPath(path); current is not null; current = Path.GetDirectoryName(current))
        {
            try
            {
                if ((File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
                    throw new UnauthorizedAccessException("Symbolic links and reparse points are not permitted.");
            }
            catch (FileNotFoundException) { }
            catch (DirectoryNotFoundException) { }
        }
    }

    private JsonArray ListScripts()
    {
        EnsureNoLinks(_scriptsDirectory);
        int count = 0;
        return ListDirectory(_scriptsDirectory, 0, ref count);
    }

    private JsonArray ListDirectory(string directory, int depth, ref int count)
    {
        if (depth > 32) throw new IOException("The scripts folder is nested too deeply.");
        var children = new JsonArray();
        foreach (var entry in new DirectoryInfo(directory).EnumerateFileSystemInfos()
                     .OrderByDescending(e => e is DirectoryInfo)
                     .ThenBy(e => e.Name, StringComparer.OrdinalIgnoreCase))
        {
            if (++count > 10000) throw new IOException("The scripts folder contains too many entries.");
            if (entry.Name.StartsWith('.') || (entry.Attributes & FileAttributes.ReparsePoint) != 0) continue;
            if (entry is DirectoryInfo folder)
                children.Add(new JsonObject { ["name"] = entry.Name, ["path"] = entry.FullName, ["isDirectory"] = true, ["children"] = ListDirectory(folder.FullName, depth + 1, ref count) });
            else if (ScriptExtensions.Contains(Path.GetExtension(entry.Name).ToLowerInvariant()))
                children.Add(new JsonObject { ["name"] = entry.Name, ["path"] = entry.FullName, ["isDirectory"] = false, ["children"] = new JsonArray() });
        }
        return children;
    }

    private string ReadText(string path)
    {
        EnsureNoLinks(path);
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (stream.Length > 8_000_000) throw new InvalidOperationException("The file is too large for the local editor.");
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    private async Task WriteScriptAsync(string path, string content)
    {
        if (content.Length > 8_000_000) throw new ArgumentException("The script is too large.");
        EnsureNoLinks(path);
        var overwrite = File.Exists(path);
        if (overwrite && !await ConfirmAsync("Overwrite file", $"“{Path.GetFileName(path)}” already exists. Overwrite it?"))
            throw new OperationCanceledException("The overwrite was cancelled.");
        if (_disposed || _finishingClose) throw new OperationCanceledException("The editor is closing.");
        EnsureNoLinks(path); // Recheck after the user has finished the dialog.
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        var temporary = Path.Combine(Path.GetDirectoryName(path)!, $".orion-{Guid.NewGuid():N}.tmp");
        try
        {
            using (var stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
            using (var writer = new StreamWriter(stream)) writer.Write(content);
            EnsureNoLinks(path);
            File.Move(temporary, path, overwrite); // A new destination is never overwritten without approval.
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
        Log("info", $"Saved “{Path.GetFileName(path)}”.");
        Emit("scriptsChanged", new { });
    }

    private async Task<object?> OpenFileAsync()
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            Title = "Open script", AllowMultiple = false,
            FileTypeFilter = [new FilePickerFileType("Script files") { Patterns = ["*.lua", "*.luau", "*.txt", "*.json"] }, new FilePickerFileType("All files") { Patterns = ["*"] }]
        });
        if (files.Count == 0) return null;
        using var file = files[0];
        var path = file.TryGetLocalPath() ?? throw new InvalidOperationException("Select a local file.");
        path = Path.GetFullPath(path);
        EnsureNoLinks(path);
        if (_disposed || _finishingClose) throw new OperationCanceledException("The editor is closing.");
        var content = ReadText(path);
        _dialogFiles.Add(path);
        return new { path, filePath = path, name = Path.GetFileName(path), content };
    }

    private async Task<object?> SaveFileAsync(string content, string existingPath)
    {
        string target;
        if (!string.IsNullOrWhiteSpace(existingPath)) target = ResolveScript(existingPath);
        else
        {
            using var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
            {
                Title = "Save script", DefaultExtension = "lua",
                FileTypeChoices = [new FilePickerFileType("Lua script") { Patterns = ["*.lua"] }, new FilePickerFileType("Text file") { Patterns = ["*.txt"] }]
            });
            if (file is null) return null;
            target = Path.GetFullPath(file.TryGetLocalPath() ?? throw new InvalidOperationException("Select a local file."));
            EnsureNoLinks(target);
            _dialogFiles.Add(target);
        }
        await WriteScriptAsync(target, content);
        return new { filePath = target, name = Path.GetFileName(target) };
    }

    private async Task<bool> DeleteScriptAsync(string input)
    {
        var path = ResolveScript(input);
        if (!File.Exists(path) && !Directory.Exists(path)) throw new FileNotFoundException("Script not found.");
        if (!await ConfirmAsync("Delete script", $"Delete “{Path.GetFileName(path)}” permanently? This cannot be undone.")) return false;
        if (_disposed || _finishingClose) throw new OperationCanceledException("The editor is closing.");
        EnsureNoLinks(path);
        // Empty directories only: never recursively follow a newly introduced junction.
        if (Directory.Exists(path)) Directory.Delete(path, false);
        else File.Delete(path);
        Log("info", $"Deleted “{Path.GetFileName(path)}”.");
        Emit("scriptsChanged", new { });
        return true;
    }

    private async Task<bool> ConfirmAsync(string title, string message)
    {
        var dialog = new Window { Title = title, SizeToContent = SizeToContent.WidthAndHeight, CanResize = false,
            WindowStartupLocation = WindowStartupLocation.CenterOwner, ShowInTaskbar = false, MinWidth = 320 };
        var panel = new StackPanel { Margin = new Avalonia.Thickness(18) };
        panel.Children.Add(new TextBlock { Text = message, TextWrapping = Avalonia.Media.TextWrapping.Wrap, MaxWidth = 380 });
        var buttons = new StackPanel { Orientation = Avalonia.Layout.Orientation.Horizontal, HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Right, Margin = new Avalonia.Thickness(0, 16, 0, 0) };
        var cancel = new Button { Content = "Cancel", IsDefault = true, IsCancel = true };
        var confirm = new Button { Content = "Confirm", Margin = new Avalonia.Thickness(6, 0, 0, 0) };
        cancel.Click += (_, _) => dialog.Close(false);
        confirm.Click += (_, _) => dialog.Close(true);
        buttons.Children.Add(cancel); buttons.Children.Add(confirm); panel.Children.Add(buttons); dialog.Content = panel;
        return await dialog.ShowDialog<bool>(this);
    }

    private JsonArray ReadThemes()
    {
        var manifest = Path.Combine(_uiRoot, "themes", "manifest.json");
        EnsureNoLinks(manifest);
        return JsonNode.Parse(File.ReadAllText(manifest)) as JsonArray ?? throw new InvalidDataException("The bundled theme manifest is invalid.");
    }

    private void OpenThemeFolder()
    {
        var folder = Path.Combine(_uiRoot, "themes");
        EnsureNoLinks(folder);
        if (!Directory.Exists(folder)) throw new DirectoryNotFoundException("The bundled themes folder is missing.");
        using var process = Process.Start(new ProcessStartInfo(folder) { UseShellExecute = true });
    }

    private void ShowItemInFolder(string input)
    {
        var path = ResolveScript(input);
        if (!File.Exists(path) && !Directory.Exists(path)) throw new FileNotFoundException("The selected item no longer exists.");
        // Launch Explorer, never the selected file itself.
        using var process = Process.Start(new ProcessStartInfo("explorer.exe", $"/select,\"{path}\"") { UseShellExecute = true });
    }

    private async Task ShowErrorAsync(string message)
    {
        Log("error", message);
        if (_disposed) return;
        var dialog = new Window { Title = "Synapse V3 Alt", SizeToContent = SizeToContent.WidthAndHeight, CanResize = false, WindowStartupLocation = WindowStartupLocation.CenterOwner };
        var panel = new StackPanel { Margin = new Avalonia.Thickness(18) };
        panel.Children.Add(new TextBlock { Text = message, TextWrapping = Avalonia.Media.TextWrapping.Wrap, MaxWidth = 420 });
        var button = new Button { Content = "Close", IsDefault = true, Margin = new Avalonia.Thickness(0, 14, 0, 0), HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Right };
        button.Click += (_, _) => dialog.Close(); panel.Children.Add(button); dialog.Content = panel;
        try { await dialog.ShowDialog(this); } catch (InvalidOperationException) { /* Owner closed. */ }
    }
}
