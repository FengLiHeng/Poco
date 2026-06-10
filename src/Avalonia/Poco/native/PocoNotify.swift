// Poco 原生通知（macOS）
// 编译为 libPocoNotify.dylib，由 .NET 通过 P/Invoke 调用。
// 必须在带 bundle id 的 .app 中运行，UNUserNotificationCenter 才可用。
import Foundation
import UserNotifications

private final class PocoDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PocoDelegate()
    var onClick: (@convention(c) () -> Void)?

    // 应用在前台时也显示横幅
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    // 用户点击通知 → 回调 .NET（由其在 UI 线程唤出主窗口）
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        onClick?()
        completionHandler()
    }
}

// 无 bundle 身份的进程（dotnet run）调 UNUserNotificationCenter 会直接崩溃，
// 必须先判 bundleIdentifier；返回 0 让 .NET 侧回退 osascript。
@_cdecl("poco_notify_init")
public func poco_notify_init(_ cb: @escaping @convention(c) () -> Void) -> Int32 {
    guard Bundle.main.bundleIdentifier != nil else { return 0 }
    PocoDelegate.shared.onClick = cb
    let center = UNUserNotificationCenter.current()
    center.delegate = PocoDelegate.shared
    center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    return 1
}

@_cdecl("poco_notify_post")
public func poco_notify_post(_ title: UnsafePointer<CChar>, _ body: UnsafePointer<CChar>) {
    guard Bundle.main.bundleIdentifier != nil else { return }
    let content = UNMutableNotificationContent()
    content.title = String(cString: title)
    content.body = String(cString: body)
    let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
}
