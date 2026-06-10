using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Avalonia.Platform;
using System;
using System.ComponentModel;
using System.Diagnostics;
using Poco.Models;
using Poco.Platform;
using Poco.ViewModels;
using Poco.Views;

namespace Poco;

public partial class App : Application
{
    /// <summary>是否正在真正退出（由菜单栏「退出 Poco」触发）。</summary>
    public static bool IsExiting { get; private set; }

    private TrayIcon? _trayIcon;
    private MainWindowViewModel? _viewModel;
    private Window? _mainWindow;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            // 关闭主窗口只隐藏，应用由菜单栏控制生命周期
            desktop.ShutdownMode = ShutdownMode.OnExplicitShutdown;

            // Dock 右键「退出」/ ⌘Q / Quit 菜单 / 系统注销关机都会触发这里，
            // 标记为真正退出，让 MainWindow.OnClosing 放行（否则会被隐藏逻辑拦下）。
            desktop.ShutdownRequested += OnShutdownRequested;

            _viewModel = new MainWindowViewModel();
            _viewModel.ApplyTheme(); // 按持久化设置应用主题（默认浅色）
            _viewModel.PhaseFinished += OnPhaseFinished; // 阶段自然结束 → 系统通知（跳过不触发）
            _mainWindow = new MainWindow { DataContext = _viewModel };
            desktop.MainWindow = _mainWindow;

            // 原生通知（仅 .app 运行时可用）：点击通知 → 唤出主窗口
            MacNotifier.Clicked = ShowMainWindow;
            MacNotifier.TryInit();

            SetupTray();
        }

        base.OnFrameworkInitializationCompleted();
    }

    // ============================================================
    // 菜单栏「甜点」形态：托盘图标 + 倒计时提示 + 下拉菜单
    // macOS 上 TrayIcon 必须挂 NativeMenu 才有响应（点击状态栏图标弹菜单；
    // Clicked 事件在 macOS 不触发）。所以把「显示主窗口」放在菜单第一项作为
    // 打开窗口的入口；Clicked 仍保留，在 Windows/Linux 上支持单击直接开窗口。
    // 注：动态倒计时文本用 ToolTipText 承载（NSStatusItem 标题暂不直接支持）。
    // ============================================================
    private void SetupTray()
    {
        if (_viewModel is null) return;

        var open = new NativeMenuItem { Header = "显示主窗口" };
        open.Click += (_, _) => ShowMainWindow();
        var settings = new NativeMenuItem { Header = "设置…" };
        settings.Click += (_, _) => { _viewModel.IsSettingsOpen = true; ShowMainWindow(); };
        var primary = new NativeMenuItem { Header = "开始 / 暂停", Command = _viewModel.PrimaryActionCommand };
        var reset = new NativeMenuItem { Header = "重置当前阶段", Command = _viewModel.ResetCommand };
        var skip = new NativeMenuItem { Header = "跳过", Command = _viewModel.SkipCommand };
        var quit = new NativeMenuItem { Header = "退出 Poco" };
        quit.Click += (_, _) => ExitApp();

        var menu = new NativeMenu();
        menu.Add(open);
        menu.Add(settings);
        menu.Add(new NativeMenuItemSeparator());
        menu.Add(primary);
        menu.Add(reset);
        menu.Add(skip);
        menu.Add(new NativeMenuItemSeparator());
        menu.Add(quit);

        _trayIcon = new TrayIcon
        {
            Icon = new WindowIcon(AssetLoader.Open(new Uri("avares://Poco/Assets/tomato.png"))),
            ToolTipText = _viewModel.TrayTooltip,
            Menu = menu,
        };
        _trayIcon.Clicked += (_, _) => ShowMainWindow();

        // 倒计时实时同步到托盘提示
        _viewModel.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(MainWindowViewModel.TrayTooltip) && _trayIcon is not null)
                _trayIcon.ToolTipText = _viewModel.TrayTooltip;
        };
    }

    // 平台发起的退出请求（Dock 右键退出 / ⌘Q / 系统关机）：放行而非拦截
    private void OnShutdownRequested(object? sender, ShutdownRequestedEventArgs e)
    {
        IsExiting = true;
        _trayIcon?.Dispose();
    }

    private void ShowMainWindow()
    {
        if (_mainWindow is null) return;
        _mainWindow.Show();
        _mainWindow.WindowState = WindowState.Normal;
        _mainWindow.Activate();
    }

    // ============================================================
    // 阶段自然结束 → 系统通知（Dock 跳动/原生通知中心需打包成签名 .app 才完整，
    // 这里用 osascript 调系统通知，dotnet run 下即可用）
    // ============================================================
    private void OnPhaseFinished(PocoPhase finished)
    {
        var body = finished == PocoPhase.Focus
            ? "专注结束，该休息一下"
            : "休息结束，开始下一个专注";
        const string title = "Poco · 番茄钟";

        // 优先用原生通知（.app 运行时：Poco 图标 + 点击唤窗）；否则回退 osascript（开发期）
        if (!MacNotifier.Post(title, body))
            ShowOsascriptNotification(title, body);
    }

    private static void ShowOsascriptNotification(string title, string body)
    {
        try
        {
            if (OperatingSystem.IsMacOS())
            {
                var script = $"display notification \"{Escape(body)}\" with title \"{Escape(title)}\"";
                var psi = new ProcessStartInfo("osascript") { UseShellExecute = false, CreateNoWindow = true };
                psi.ArgumentList.Add("-e");
                psi.ArgumentList.Add(script);
                Process.Start(psi);
            }
            // TODO: Windows / Linux 原生通知（如需跨平台可接入 DesktopNotifications）
        }
        catch
        {
            // 通知失败不应影响计时
        }
    }

    private static string Escape(string s) => s.Replace("\\", "\\\\").Replace("\"", "\\\"");

    /// <summary>真正退出应用（由设置面板的「退出」触发）。</summary>
    public static void ExitApp()
    {
        IsExiting = true;
        if (Current is App app)
            app._trayIcon?.Dispose();
        if (Current?.ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
            desktop.Shutdown();
    }
}
