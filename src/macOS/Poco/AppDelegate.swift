// 应用生命周期：主窗口（关窗只隐藏）、菜单栏托盘、系统通知、主菜单。
// 退出走托盘菜单「退出 Poco」、设置面板「退出」或 ⌘Q。
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let engine = PomodoroEngine()
    private var window: NSWindow?
    private var tray: StatusItemController?
    private var notifier: NotificationManager?

    /// 单元测试以本 app 为宿主运行时，不挂托盘/不请求通知授权
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        engine.applyTheme() // 按持久化设置应用主题（默认浅色）
        setupMainMenu()
        setupWindow()
        guard !isRunningTests else { return }

        tray = StatusItemController(engine: engine) { [weak self] in self?.showMainWindow() }
        notifier = NotificationManager { [weak self] in self?.showMainWindow() }
        // 阶段自然结束 → 系统通知（跳过不触发）
        engine.onPhaseFinished = { [weak self] finished in
            self?.notifier?.postPhaseFinished(finished)
        }
        showMainWindow()
    }

    private func setupWindow() {
        let w = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        w.title = "Poco"
        w.isReleasedWhenClosed = false // 关闭只隐藏，窗口对象常驻
        // 隐藏标题栏让内容整张铺满（交通灯保留），可拖拽窗口背景移动
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        let hosting = NSHostingView(rootView: MainView().environmentObject(engine))
        hosting.safeAreaRegions = [] // 内容铺满到隐藏标题栏之下，由视图自己给交通灯留位
        w.contentView = hosting
        w.setContentSize(NSSize(width: 324, height: 416))
        w.center()
        w.delegate = self
        window = w
    }

    // 最小主菜单：让 ⌘Q / ⌘W / ⌘M 可用
    private func setupMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "关于 Poco", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "隐藏 Poco", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "退出 Poco", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let windowMenu = NSMenu(title: "窗口")
        windowMenu.addItem(NSMenuItem(title: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        windowMenu.addItem(NSMenuItem(title: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))

        let main = NSMenu()
        let appItem = NSMenuItem(); appItem.submenu = appMenu; main.addItem(appItem)
        let winItem = NSMenuItem(); winItem.submenu = windowMenu; main.addItem(winItem)
        NSApp.mainMenu = main
        NSApp.windowsMenu = windowMenu
    }

    // 关闭按钮 / ⌘W → 隐藏窗口（不销毁），托盘双击/通知点击可再唤出
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    // macOS 14+ 要求显式声明，否则每次启动在控制台告警
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    // Dock 图标点击（窗口已隐藏时）→ 唤出主窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    func showMainWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
