// 菜单栏托盘（单槽位 NSStatusItem，逻辑沿用 Avalonia 版 native/PocoTray.swift）。
// 未运行（Ready/Finished）：显示番茄图标；运行/暂停：切换为倒计时文本（同一槽位）。
// 交互：双击 → 唤出主窗口；右键 → 弹菜单；单击不响应（避免误触）。
import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject {
    private let engine: PomodoroEngine
    private let showWindow: () -> Void
    private var item: NSStatusItem?
    private var menu: NSMenu?
    private var subscriptions = Set<AnyCancellable>()

    // 等宽数字字体：跳秒时宽度不抖（对应主窗口 monospacedDigit 的同款处理）
    private let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    private lazy var icon: NSImage? = {
        let image = NSImage(named: "TrayTomato")
        image?.size = NSSize(width: 18, height: 18) // 菜单栏高度 22pt，留边距
        return image
    }()

    init(engine: PomodoroEngine, showWindow: @escaping () -> Void) {
        self.engine = engine
        self.showWindow = showWindow
        super.init()

        let it = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = it.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.image = icon
        }
        item = it

        // 引擎任何状态变化后刷新（objectWillChange 发生在变更前，转下一轮主循环再读）
        engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &subscriptions)
        refresh()
    }

    // 上次写入的文本/提示：引擎每 250ms 广播一次，值没变就不动 NSStatusItem。
    // lastText 为 nil 代表「图标态」——init() 已把按钮置为图标，故初值 nil 即与当前一致。
    private var lastText: String?
    private var lastTooltip: String?

    /// text 为 nil → 图标态；否则 → 文本态（倒计时）。
    private func refresh() {
        guard let button = item?.button else { return }
        let text = engine.trayText
        if text != lastText {
            lastText = text
            if let text {
                button.image = nil
                button.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
            } else {
                button.attributedTitle = NSAttributedString()
                button.image = icon
            }
        }
        let tooltip = engine.trayTooltip
        if tooltip != lastTooltip {
            lastTooltip = tooltip
            button.toolTip = tooltip
        }
    }

    @objc private func clicked() {
        guard let event = NSApp.currentEvent, let it = item else { return }
        if event.type == .rightMouseUp {
            // 右键弹菜单：临时挂上 menu 让 performClick 走系统菜单弹出，弹完摘掉，
            // 否则左键也会弹菜单（NSStatusItem 挂了 menu 后任何点击都弹）。
            if menu == nil { menu = buildMenu() }
            it.menu = menu
            it.button?.performClick(nil)
            it.menu = nil
        } else if event.clickCount == 2 {
            showWindow()
        }
    }

    private func buildMenu() -> NSMenu {
        let m = NSMenu()
        func add(_ title: String, _ action: Selector) {
            let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
            mi.target = self
            m.addItem(mi)
        }
        add("显示主窗口", #selector(menuShowWindow))
        add("设置…", #selector(menuOpenSettings))
        m.addItem(.separator())
        add("开始 / 暂停", #selector(menuPrimaryAction))
        add("重置当前阶段", #selector(menuReset))
        add("跳过", #selector(menuSkip))
        m.addItem(.separator())
        add("退出 Poco", #selector(menuQuit))
        return m
    }

    @objc private func menuShowWindow() { showWindow() }
    @objc private func menuOpenSettings() {
        engine.isSettingsOpen = true
        showWindow()
    }
    @objc private func menuPrimaryAction() { engine.primaryAction() }
    @objc private func menuReset() { engine.reset() }
    @objc private func menuSkip() { engine.skip() }
    @objc private func menuQuit() { NSApp.terminate(nil) }
}
