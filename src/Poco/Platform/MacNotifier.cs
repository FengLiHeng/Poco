using System;
using System.Runtime.InteropServices;
using Avalonia.Threading;

namespace Poco.Platform;

/// <summary>
/// macOS 原生通知（经 libPocoNotify.dylib 调 UNUserNotificationCenter）。
/// 仅在打包成 .app 运行时可用；dotnet run 下找不到 dylib，TryInit 返回 false，
/// 调用方回退到 osascript。
/// </summary>
internal static unsafe class MacNotifier
{
    [DllImport("PocoNotify", EntryPoint = "poco_notify_init")]
    private static extern void NativeInit(IntPtr clickCallback);

    [DllImport("PocoNotify", EntryPoint = "poco_notify_post")]
    private static extern void NativePost(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string title,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string body);

    /// <summary>用户点击通知后的回调（已切到 UI 线程）。</summary>
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
            _available = false; // 非 .app 运行：dylib 不存在
        }
        return _available;
    }

    public static bool Post(string title, string body)
    {
        if (!_available) return false;
        try
        {
            NativePost(title, body);
            return true;
        }
        catch
        {
            return false;
        }
    }

    [UnmanagedCallersOnly]
    private static void OnClicked() => Dispatcher.UIThread.Post(() => Clicked?.Invoke());
}
