// 番茄钟阶段推进的纯逻辑（无计时器、无 UI 依赖，便于单元测试）。
// 规则：每完成 4 个专注 → 1 次大休 → 计数归零，循环往复。
import Foundation

enum PomodoroLogic {
    /// 每组固定 4 轮专注。
    static let focusPerCycle = 4

    /// 给定当前阶段与本组已完成专注数，返回下一阶段。
    static func nextPhase(_ current: PocoPhase, completedFocus: Int) -> PocoPhase {
        if current == .focus {
            return completedFocus >= focusPerCycle ? .long : .short
        }
        // 短休 / 大休结束后都回到专注
        return .focus
    }

    /// 从某阶段推进到下一阶段时，是否应开启新一组（专注计数归零）。
    static func startsNewCycle(_ current: PocoPhase, completedFocus: Int) -> Bool {
        let next = nextPhase(current, completedFocus: completedFocus)
        return current != .focus && next == .focus && completedFocus >= focusPerCycle
    }
}
