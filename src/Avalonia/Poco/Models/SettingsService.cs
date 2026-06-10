using System;
using System.IO;
using System.Text.Json;

namespace Poco.Models;

/// <summary>用户设置：只持久化三个自定义时长（分钟）。</summary>
public sealed class PocoSettings
{
    public int FocusMinutes { get; set; } = 25;
    public int ShortMinutes { get; set; } = 5;
    public int LongMinutes { get; set; } = 15;
    /// <summary>主题：默认浅色（false）。</summary>
    public bool IsDark { get; set; } = false;
}

/// <summary>把设置读写到本地配置文件（不持久化计时进度）。</summary>
public static class SettingsService
{
    private static readonly string Path = System.IO.Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "Poco", "settings.json");

    public static PocoSettings Load()
    {
        try
        {
            if (File.Exists(Path))
            {
                var json = File.ReadAllText(Path);
                return JsonSerializer.Deserialize<PocoSettings>(json) ?? new PocoSettings();
            }
        }
        catch
        {
            // 配置损坏时回退到默认值
        }
        return new PocoSettings();
    }

    public static void Save(PocoSettings settings)
    {
        try
        {
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(Path)!);
            File.WriteAllText(Path, JsonSerializer.Serialize(settings));
        }
        catch
        {
            // 忽略写入失败
        }
    }
}
