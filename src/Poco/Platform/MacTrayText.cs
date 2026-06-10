using System;
using System.Runtime.InteropServices;
using Avalonia.Threading;

namespace Poco.Platform;

/// <summary>
/// macOS 菜单栏倒计时文本（经 libPocoNotify.dylib 建纯文本 NSStatusItem，方案 A 双槽位）。
/// NSStatusItem 不需要 bundle 身份，dotnet run 与 .app 下都可用；
/// dylib 缺失或非 macOS 时所有调用静默 no-op（退化为仅 ToolTip）。
/// </summary>
internal static unsafe class MacTrayText
{
    [DllImport("PocoNotify", EntryPoint = "poco_tray_init")]
    private static extern void NativeInit(IntPtr clickCallback);

    [DllImport("PocoNotify", EntryPoint = "poco_tray_set_text")]
    private static extern void NativeSetText([MarshalAs(UnmanagedType.LPUTF8Str)] string? text);

    /// <summary>用户点击菜单栏文字后的回调（已切到 UI 线程）。</summary>
    public static Action? Clicked;

    private static bool _available;

    public static bool TryInit()
    {
        if (!OperatingSystem.IsMacOS()) return false;
        try
        {
            NativeInit((IntPtr)(delegate* unmanaged<void>)&OnClicked);
            _available = true;
        }
        catch
        {
            _available = false; // dylib 不存在
        }
        return _available;
    }

    /// <summary>设置菜单栏文本；null/空串隐藏文字项。</summary>
    public static void SetText(string? text)
    {
        if (!_available) return;
        try
        {
            NativeSetText(text);
        }
        catch
        {
            // 菜单栏文本失败不应影响计时
        }
    }

    [UnmanagedCallersOnly]
    private static void OnClicked() => Dispatcher.UIThread.Post(() => Clicked?.Invoke());
}
