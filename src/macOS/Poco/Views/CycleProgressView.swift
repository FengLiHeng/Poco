import SwiftUI

/// 每组四轮专注进度，并向辅助功能提供完整语义。
struct CycleProgressView: View {
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }
    private var accent: Color { theme.accent(isFocus: engine.isFocus) }

    private var accessibilityProgress: String {
        if let current = engine.currentDotIndex {
            return "已完成 \(engine.completedFocus) 个，当前第 \(current + 1) 个，共 \(PomodoroEngine.focusPerCycle) 个"
        }
        return "已完成 \(engine.completedFocus) 个，共 \(PomodoroEngine.focusPerCycle) 个"
    }

    var body: some View {
        HStack(spacing: 11) {
            ForEach(0..<PomodoroEngine.focusPerCycle, id: \.self) { index in
                CycleDotView(
                    state: state(for: index),
                    accent: accent,
                    hairline: theme.hairline
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("本组专注进度")
        .accessibilityValue(accessibilityProgress)
    }

    private func state(for index: Int) -> CycleDotState {
        if index < engine.completedFocus { return .completed }
        if index == engine.currentDotIndex { return .current }
        return .upcoming
    }
}
