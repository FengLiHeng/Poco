// 移植自 C# 版 Poco.Tests/PomodoroLogicTests.cs（xUnit → Swift Testing）
import Testing
@testable import Poco

struct PomodoroLogicTests {
    @Test(arguments: [
        (PocoPhase.focus, 0, PocoPhase.short), // 专注未满 4 → 短休
        (PocoPhase.focus, 3, PocoPhase.short),
        (PocoPhase.focus, 4, PocoPhase.long),  // 第 4 个专注后 → 大休
        (PocoPhase.short, 2, PocoPhase.focus), // 休息后回到专注
        (PocoPhase.long, 4, PocoPhase.focus),
    ])
    func nextPhaseFollowsCycleRules(current: PocoPhase, completed: Int, expected: PocoPhase) {
        #expect(PomodoroLogic.nextPhase(current, completedFocus: completed) == expected)
    }

    @Test(arguments: [
        (PocoPhase.long, 4, true),   // 大休结束、计数已满 → 开启新一组
        (PocoPhase.short, 1, false), // 短休不归零
        (PocoPhase.focus, 4, false), // 专注阶段本身不开启新组
    ])
    func startsNewCycleOnlyAfterCompletedLong(current: PocoPhase, completed: Int, expected: Bool) {
        #expect(PomodoroLogic.startsNewCycle(current, completedFocus: completed) == expected)
    }

    /// 完整一组：4 个专注穿插 3 次短休，第 4 个专注后进大休，大休后归零开新组。
    @Test
    func fullCycleFourFocusOneLongThenReset() {
        var phase = PocoPhase.focus
        var completed = 0
        var sequence: [PocoPhase] = []

        // 模拟 8 次「阶段自然结束 → 推进」，与 PomodoroEngine 的规则一致：
        // 专注自然走完才计数 +1，再据此决定下一阶段。
        for _ in 0..<8 {
            if phase == .focus {
                completed = min(completed + 1, PomodoroLogic.focusPerCycle)
            }
            let newCycle = PomodoroLogic.startsNewCycle(phase, completedFocus: completed)
            phase = PomodoroLogic.nextPhase(phase, completedFocus: completed)
            if newCycle { completed = 0 }
            sequence.append(phase)
        }

        #expect(sequence == [
            .short, .focus, .short, .focus,
            .short, .focus, .long, .focus,
        ])
        #expect(completed == 0) // 大休后已归零，新一组从头开始
    }

    /// 跳过专注不计入完成数：跳过第 4 个专注应进短休而非大休。
    @Test
    func skippingFourthFocusGoesToShortNotLong() {
        // 已完成 3 个专注，正在第 4 个专注但选择「跳过」——跳过不 +1
        #expect(PomodoroLogic.nextPhase(.focus, completedFocus: 3) == .short)
    }
}
