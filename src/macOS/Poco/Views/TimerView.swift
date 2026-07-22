import SwiftUI

/// 计时主界面的空间结构。
struct TimerView: View {
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                GearButton(theme: theme, action: openSettings)
            }
            .padding(.top, 10)
            .padding(.trailing, 14)

            Spacer(minLength: 12)

            VStack(spacing: 20) {
                TimerRingView()
                CycleProgressView()
                TimerControlsView()
                    .padding(.top, 2)
            }

            Spacer(minLength: 12)
            Spacer().frame(height: 26)
        }
    }

    private func openSettings() {
        engine.isSettingsOpen = true
    }
}
