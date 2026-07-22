import SwiftUI

/// 设置页标题栏。
struct SettingsHeaderView: View {
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        ZStack {
            HStack {
                Button("‹ 返回", action: closeSettings)
                    .buttonStyle(LinkButtonStyle(normal: theme.inkSoft, hover: theme.ink))
                    .font(.callout)
                Spacer()
                Text("时长 · 分钟")
                    .font(.caption)
                    .kerning(0.4)
                    .foregroundStyle(theme.inkSoft)
            }

            Text("设置")
                .font(.headline)
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.top, 36)
        .padding(.bottom, 14)
    }

    private func closeSettings() {
        engine.isSettingsOpen = false
    }
}
