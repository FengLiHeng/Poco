import SwiftUI

/// 浅色 / 深色主题分段选择。
struct ThemeSelectorRow: View {
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        HStack {
            Text("主题")
                .font(.body)
                .foregroundStyle(theme.inkSoft)
            Spacer()
            HStack(spacing: 2) {
                ThemeSegmentButton(
                    title: "浅色",
                    isActive: !engine.isDarkTheme,
                    action: selectLightTheme
                )
                ThemeSegmentButton(
                    title: "深色",
                    isActive: engine.isDarkTheme,
                    action: selectDarkTheme
                )
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 9).fill(theme.btn))
            .animation(.easeOut(duration: 0.2), value: engine.isDarkTheme)
        }
        .padding(.vertical, 14)
    }

    private func selectLightTheme() {
        engine.isDarkTheme = false
    }

    private func selectDarkTheme() {
        engine.isDarkTheme = true
    }
}
