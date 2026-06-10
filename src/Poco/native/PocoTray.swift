// Poco 菜单栏倒计时文本（macOS）
// 与 PocoNotify.swift 一起编进 libPocoNotify.dylib。
// 在现有 Avalonia TrayIcon（图标+菜单）旁加一个纯文本 NSStatusItem（方案 A 双槽位）。
// NSStatusItem 不需要 bundle 身份，dotnet run 下即可用。
import AppKit

private final class PocoTrayController: NSObject {
    static let shared = PocoTrayController()
    private var item: NSStatusItem?
    var onClick: (@convention(c) () -> Void)?

    // 等宽数字字体：跳秒时宽度不抖（对应主窗口 +tnum 的同款处理）
    private let font = NSFont.monospacedDigitSystemFont(
        ofSize: NSFont.systemFontSize, weight: .regular)

    /// text 为 nil/空 → 隐藏（不销毁，避免槽位左右跳动）；否则设置文本并显示。
    func setText(_ text: String?) {
        guard let text, !text.isEmpty else {
            item?.isVisible = false
            return
        }
        if item == nil {
            let it = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            it.button?.target = self
            it.button?.action = #selector(clicked)
            item = it
        }
        item?.button?.attributedTitle = NSAttributedString(
            string: text, attributes: [.font: font])
        item?.isVisible = true
    }

    @objc private func clicked() { onClick?() }
}

@_cdecl("poco_tray_init")
public func poco_tray_init(_ cb: @escaping @convention(c) () -> Void) {
    PocoTrayController.shared.onClick = cb
}

@_cdecl("poco_tray_set_text")
public func poco_tray_set_text(_ text: UnsafePointer<CChar>?) {
    let s = text.map { String(cString: $0) }
    DispatchQueue.main.async { PocoTrayController.shared.setText(s) }
}
