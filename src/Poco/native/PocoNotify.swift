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

@_cdecl("poco_notify_init")
public func poco_notify_init(_ cb: @escaping @convention(c) () -> Void) {
    PocoDelegate.shared.onClick = cb
    let center = UNUserNotificationCenter.current()
    center.delegate = PocoDelegate.shared
    center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
}

@_cdecl("poco_notify_post")
public func poco_notify_post(_ title: UnsafePointer<CChar>, _ body: UnsafePointer<CChar>) {
    let content = UNMutableNotificationContent()
    content.title = String(cString: title)
    content.body = String(cString: body)
    let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
}
