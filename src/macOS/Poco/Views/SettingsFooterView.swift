import SwiftUI

/// 设置页底部说明与低频操作，分行避免小窗口内拥挤。
struct SettingsFooterView: View {
    @EnvironmentObject private var engine: PomodoroEngine
    @State private var isRestoreConfirmationPresented = false

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("每完成 4 个专注，下一次进入大休")
                .font(.caption)
                .foregroundStyle(theme.inkSoft)

            HStack {
                Button("恢复默认时长", action: requestRestoreConfirmation)
                    .buttonStyle(LinkButtonStyle(normal: theme.focusInk, hover: theme.focus))
                    .font(.callout)
                    .confirmationDialog(
                        "恢复默认时长？",
                        isPresented: $isRestoreConfirmationPresented,
                        titleVisibility: .visible
                    ) {
                        Button("恢复为 25 / 5 / 15 分钟", action: engine.restoreDefaults)
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text("当前的专注、短休和大休时长会被替换。")
                    }
                Spacer()
                Button("退出 Poco", action: quit)
                    .buttonStyle(LinkButtonStyle(normal: theme.inkSoft, hover: theme.ink))
                    .font(.callout)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 15)
    }

    private func quit() {
        NSApp.terminate(nil)
    }

    private func requestRestoreConfirmation() {
        isRestoreConfirmationPresented = true
    }
}
