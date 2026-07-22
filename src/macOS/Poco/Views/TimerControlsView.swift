import SwiftUI

/// 重置、开始/暂停与跳过控制区。
struct TimerControlsView: View {
    @EnvironmentObject private var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }
    private var actionColor: Color { theme.action(isFocus: engine.isFocus) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 7) {
                Button("重置", systemImage: "arrow.counterclockwise", action: engine.reset)
                    .labelStyle(.iconOnly)
                    .buttonStyle(GhostButtonStyle(theme: theme))
                    .keyboardShortcut("r", modifiers: .command)
                    .help("重置当前阶段（⌘R）")
                Text("重置")
                    .font(.caption)
                    .kerning(0.3)
                    .foregroundStyle(theme.inkFaint)
            }
            .padding(.top, 4)

            Button(action: engine.primaryAction) {
                Label(
                    engine.primaryLabel,
                    systemImage: engine.state == .running ? "pause.fill" : "play.fill"
                )
                .labelStyle(.titleAndIcon)
            }
            .buttonStyle(PrimaryButtonStyle(theme: theme, actionColor: actionColor))
            .keyboardShortcut(.space, modifiers: [])
            .help("\(engine.primaryLabel)（空格）")

            VStack(spacing: 7) {
                Button("跳过", systemImage: "forward.end", action: engine.skip)
                    .labelStyle(.iconOnly)
                    .buttonStyle(GhostButtonStyle(theme: theme))
                    .keyboardShortcut(.rightArrow, modifiers: [.command, .shift])
                    .help("跳过当前阶段（⇧⌘→）")
                Text("跳过")
                    .font(.caption)
                    .kerning(0.3)
                    .foregroundStyle(theme.inkFaint)
            }
            .padding(.top, 4)
        }
    }
}
