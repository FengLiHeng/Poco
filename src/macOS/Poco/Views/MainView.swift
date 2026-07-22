// 主窗口容器：在计时页与同窗设置页之间切换。
import SwiftUI

struct MainView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    private var settingsTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
    }

    private var settingsAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.35, dampingFraction: 0.9)
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            TimerView()
                .opacity(engine.isSettingsOpen ? 0 : 1)
                .allowsHitTesting(!engine.isSettingsOpen)
                .accessibilityHidden(engine.isSettingsOpen)

            if engine.isSettingsOpen {
                SettingsView()
                    .transition(settingsTransition)
            }
        }
        .frame(
            minWidth: PocoMetrics.windowMinWidth,
            idealWidth: PocoMetrics.windowIdealWidth,
            minHeight: PocoMetrics.windowMinHeight,
            idealHeight: PocoMetrics.windowIdealHeight
        )
        .animation(settingsAnimation, value: engine.isSettingsOpen)
        .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.45), value: engine.isFocus)
    }
}
