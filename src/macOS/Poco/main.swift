// Poco 入口：AppKit 生命周期 + SwiftUI 内容（NSHostingView）。
// 不用 SwiftUI Window 场景：它在最后一个窗口关闭时默认退出应用，
// 且接管 NSWindow delegate，无法可靠实现「关窗隐藏不退出」；
// 自建 NSWindow（isReleasedWhenClosed=false）才能保证窗口常驻、随时唤出。
import AppKit

// 顶层代码非 MainActor 隔离；NSApplicationMain 不返回，闭包持有 delegate 引用
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}
