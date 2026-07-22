// 设置面板容器：主题、三种时长与底部操作。
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                SettingsHeaderView()
                Rectangle().fill(theme.hairline).frame(height: 1)

                VStack(spacing: 0) {
                    ThemeSelectorRow()
                    Rectangle().fill(theme.hairline).frame(height: 1)
                    DurationSettingRow(
                        name: "专注时长",
                        dotColor: theme.focus,
                        value: $engine.focusMinutes
                    )
                    Rectangle().fill(theme.hairline).frame(height: 1)
                    DurationSettingRow(
                        name: "短休时长",
                        dotColor: theme.rest,
                        value: $engine.shortMinutes
                    )
                    Rectangle().fill(theme.hairline).frame(height: 1)
                    DurationSettingRow(
                        name: "大休时长",
                        dotColor: theme.rest,
                        value: $engine.longMinutes
                    )
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 8)

                SettingsFooterView()
            }
        }
    }
}
