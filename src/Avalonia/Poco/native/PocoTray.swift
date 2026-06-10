// Poco 菜单栏托盘（macOS，单槽位）
// 与 PocoNotify.swift 一起编进 libPocoNotify.dylib。
// 未运行：显示番茄图标；运行/暂停：切换为倒计时文本（同一个 NSStatusItem）。
// 交互：双击 → 唤出主窗口；右键 → 弹菜单；单击不响应（避免误触）。
// NSStatusItem 不需要 bundle 身份，dotnet run 下即可用。
import AppKit

private final class PocoTrayController: NSObject {
    static let shared = PocoTrayController()
    private var item: NSStatusItem?
    private var menu: NSMenu?
    private var icon: NSImage?

    var onDoubleClick: (@convention(c) () -> Void)?
    var onMenuCommand: (@convention(c) (Int32) -> Void)?

    // 等宽数字字体：跳秒时宽度不抖（对应主窗口 +tnum 的同款处理）
    private let font = NSFont.monospacedDigitSystemFont(
        ofSize: NSFont.systemFontSize, weight: .regular)

    private func ensureItem() -> NSStatusItem {
        if let item { return item }
        let it = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = it.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        item = it
        return it
    }

    /// 图标态用的番茄图（路径由 .NET 侧解出的临时 PNG）。
    func setIcon(_ path: String) {
        guard let image = NSImage(contentsOfFile: path) else { return }
        image.size = NSSize(width: 18, height: 18) // 菜单栏高度 22pt，留边距
        icon = image
        let button = ensureItem().button
        // 当前是图标态（无文本）就立即生效
        if button?.title.isEmpty ?? true { button?.image = icon }
    }

    /// text 为 nil/空 → 图标态；否则 → 文本态（倒计时）。
    func setText(_ text: String?) {
        guard let button = ensureItem().button else { return }
        if let text, !text.isEmpty {
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: text, attributes: [.font: font])
        } else {
            button.attributedTitle = NSAttributedString()
            button.image = icon
        }
    }

    func setTooltip(_ text: String?) {
        ensureItem().button?.toolTip = text
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
            onDoubleClick?()
        }
    }

    // 菜单命令 id（与 .NET 侧 App.OnNativeTrayCommand 的约定一致）
    private func buildMenu() -> NSMenu {
        let m = NSMenu()
        func add(_ id: Int, _ title: String) {
            let mi = NSMenuItem(title: title, action: #selector(menuAction(_:)), keyEquivalent: "")
            mi.target = self
            mi.tag = id
            m.addItem(mi)
        }
        add(1, "显示主窗口")
        add(2, "设置…")
        m.addItem(.separator())
        add(3, "开始 / 暂停")
        add(4, "重置当前阶段")
        add(5, "跳过")
        m.addItem(.separator())
        add(6, "退出 Poco")
        return m
    }

    @objc private func menuAction(_ sender: NSMenuItem) {
        onMenuCommand?(Int32(sender.tag))
    }
}

@_cdecl("poco_tray_init")
public func poco_tray_init(_ menuCb: @escaping @convention(c) (Int32) -> Void,
                           _ doubleClickCb: @escaping @convention(c) () -> Void) {
    PocoTrayController.shared.onMenuCommand = menuCb
    PocoTrayController.shared.onDoubleClick = doubleClickCb
}

@_cdecl("poco_tray_set_icon")
public func poco_tray_set_icon(_ path: UnsafePointer<CChar>?) {
    guard let path else { return }
    let s = String(cString: path)
    DispatchQueue.main.async { PocoTrayController.shared.setIcon(s) }
}

@_cdecl("poco_tray_set_text")
public func poco_tray_set_text(_ text: UnsafePointer<CChar>?) {
    let s = text.map { String(cString: $0) }
    DispatchQueue.main.async { PocoTrayController.shared.setText(s) }
}

@_cdecl("poco_tray_set_tooltip")
public func poco_tray_set_tooltip(_ text: UnsafePointer<CChar>?) {
    let s = text.map { String(cString: $0) }
    DispatchQueue.main.async { PocoTrayController.shared.setTooltip(s) }
}
