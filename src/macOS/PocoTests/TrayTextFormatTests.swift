// 移植自 C# 版 Poco.Tests/TrayTextFormatTests.cs
// 菜单栏倒计时文本的状态→文本映射（设计：运行/暂停才显示，其余隐藏）。
import Testing
@testable import Poco

struct TrayTextFormatTests {
    @Test(arguments: [
        (1471, "24:31"), // 24 分 31 秒
        (59, "00:59"),
        (3600, "60:00"), // 上限 60 分钟，不进位到小时
    ])
    func runningShowsMmSs(remainingSeconds: Int, expected: String) {
        #expect(TrayTextFormat.text(for: .running, remainingSeconds: remainingSeconds) == expected)
    }

    @Test
    func pausedShowsPauseMarkWithTime() {
        #expect(TrayTextFormat.text(for: .paused, remainingSeconds: 1471) == "⏸ 24:31")
    }

    @Test(arguments: [TimerState.ready, TimerState.finished])
    func readyAndFinishedHidden(state: TimerState) {
        #expect(TrayTextFormat.text(for: state, remainingSeconds: 1500) == nil)
    }
}
