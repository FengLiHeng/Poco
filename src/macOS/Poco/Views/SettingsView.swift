// 设置面板（与主窗口同窗切换）：主题分段控件 + 三个时长 Stepper + 恢复默认/退出。
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var engine: PomodoroEngine

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            VStack(spacing: 0) {
                themeRow
                Divider()
                durationRow("专注时长", color: .orange, value: $engine.focusMinutes)
                Divider()
                durationRow("短休时长", color: .mint, value: $engine.shortMinutes)
                Divider()
                durationRow("大休时长", color: .mint, value: $engine.longMinutes)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            footer
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button("‹ 返回") { engine.isSettingsOpen = false }
                    .buttonStyle(.borderless)
                Spacer()
                Text("时长 · 分钟")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("设置").font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var themeRow: some View {
        HStack {
            Text("主题")
            Spacer()
            Picker("", selection: $engine.isDarkTheme) {
                Text("浅色").tag(false)
                Text("深色").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
        .padding(.vertical, 14)
    }

    private func durationRow(_ name: String, color: Color, value: Binding<Int>) -> some View {
        HStack(spacing: 9) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(name)
            Spacer()
            Text("\(value.wrappedValue) 分")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Stepper("", value: value, in: 1...60)
                .labelsHidden()
        }
        .padding(.vertical, 16)
    }

    private var footer: some View {
        HStack {
            Text("每 4 个专注 → 1 次大休")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("恢复默认") { engine.restoreDefaults() }
                .buttonStyle(.borderless)
            Button("退出") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 15)
    }
}
