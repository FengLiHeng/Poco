using System;
using System.Runtime.InteropServices;
using Avalonia.Threading;

namespace Poco.Platform;

/// <summary>
/// macOS 菜单栏托盘（经 libPocoNotify.dylib 建单槽位 NSStatusItem）。
/// 未运行显示番茄图标，运行/暂停切换为倒计时文本；双击唤窗、右键弹菜单。
/// NSStatusItem 不需要 bundle 身份，dotnet run 与 .app 下都可用；
/// dylib 缺失或非 macOS 时 TryInit 返回 false，调用方回退 Avalonia TrayIcon。
/// </summary>
internal static unsafe class MacTray
{
    [DllImport("PocoNotify", EntryPoint = "poco_tray_init")]
    private static extern void NativeInit(IntPtr menuCallback, IntPtr doubleClickCallback);

    [DllImport("PocoNotify", EntryPoint = "poco_tray_set_icon")]
    private static extern void NativeSetIcon([MarshalAs(UnmanagedType.LPUTF8Str)] string path);

    [DllImport("PocoNotify", EntryPoint = "poco_tray_set_text")]
    private static extern void NativeSetText([MarshalAs(UnmanagedType.LPUTF8Str)] string? text);

    [DllImport("PocoNotify", EntryPoint = "poco_tray_set_tooltip")]
    private static extern void NativeSetTooltip([MarshalAs(UnmanagedType.LPUTF8Str)] string? text);

    /// <summary>双击菜单栏项后的回调（已切到 UI 线程）。</summary>
    public static Action? DoubleClicked;

    /// <summary>菜单命令回调（已切到 UI 线程），id 与 PocoTray.swift 的 buildMenu 约定一致。</summary>
    public static Action<int>? MenuCommand;

    private static bool _available;

    public static bool TryInit()
    {
        if (!OperatingSystem.IsMacOS()) return false;
        try
        {
            NativeInit(
                (IntPtr)(delegate* unmanaged<int, void>)&OnMenuCommand,
                (IntPtr)(delegate* unmanaged<void>)&OnDoubleClicked);
            _available = true;
        }
        catch
        {
            _available = false; // dylib 不存在
        }
        return _available;
    }

    /// <summary>设置图标态用的番茄图（PNG 文件路径）。</summary>
    public static void SetIcon(string path) => Try(() => NativeSetIcon(path));

    /// <summary>设置倒计时文本；null/空串切回图标态。</summary>
    public static void SetText(string? text) => Try(() => NativeSetText(text));

    public static void SetTooltip(string? text) => Try(() => NativeSetTooltip(text));

    private static void Try(Action call)
    {
        if (!_available) return;
        try
        {
            call();
        }
        catch
        {
            // 托盘失败不应影响计时
        }
    }

    [UnmanagedCallersOnly]
    private static void OnDoubleClicked() => Dispatcher.UIThread.Post(() => DoubleClicked?.Invoke());

    [UnmanagedCallersOnly]
    private static void OnMenuCommand(int id) => Dispatcher.UIThread.Post(() => MenuCommand?.Invoke(id));
}
