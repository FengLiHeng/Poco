// 系统原生通知（逻辑沿用 Avalonia 版 native/PocoNotify.swift，不再需要 dylib）：
// 阶段自然结束且 Poco 不在前台 → 横幅通知（声音）；
// 点击通知 → 唤出主窗口。
import AppKit
import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let onClick: @MainActor () -> Void

    init(onClick: @escaping @MainActor () -> Void) {
        self.onClick = onClick
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func postPhaseFinished(_ finished: PocoPhase) {
        let content = UNMutableNotificationContent()
        content.title = "Poco · 番茄钟"
        content.body = finished == .focus ? "专注结束，该休息一下" : "休息结束，开始下一个专注"
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // 前台展示兜底：用户已切回 Poco 时不再弹横幅/响铃。
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let isAppActive = await MainActor.run { NSApp.isActive }
        return isAppActive ? [] : [.banner, .list, .sound]
    }

    // 用户点击通知 → 唤出主窗口
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        await onClick()
    }
}
