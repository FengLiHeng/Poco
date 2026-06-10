// 菜单栏倒计时文本的状态→文本映射（纯逻辑，无 UI 依赖）。
// 设计：运行/暂停才显示，待开始/结束返回 nil（菜单栏切回图标态）。
import Foundation

enum TrayTextFormat {
    static func text(for state: TimerState, remainingSeconds: Int) -> String? {
        switch state {
        case .running: return clock(remainingSeconds)
        case .paused: return "⏸ \(clock(remainingSeconds))"
        default: return nil
        }
    }

    private static func clock(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
