// 设置面板（与主窗口同窗滑入）：主题分段控件 + 三个时长步进行 + 恢复默认/退出。
// 视觉规格移植自设计稿：发丝线分行、自定义分段控件与步进钮。
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Rectangle().fill(theme.hairline).frame(height: 1)

                VStack(spacing: 0) {
                    themeRow
                    Rectangle().fill(theme.hairline).frame(height: 1)
                    durationRow("专注时长", dotColor: theme.focus, value: $engine.focusMinutes)
                    Rectangle().fill(theme.hairline).frame(height: 1)
                    durationRow("短休时长", dotColor: theme.rest, value: $engine.shortMinutes)
                    Rectangle().fill(theme.hairline).frame(height: 1)
                    durationRow("大休时长", dotColor: theme.rest, value: $engine.longMinutes)
                }
                .padding(.horizontal, 18)

                Spacer()

                footer
            }
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button("‹ 返回") { engine.isSettingsOpen = false }
                    .buttonStyle(LinkButtonStyle(normal: theme.inkFaint, hover: theme.inkSoft))
                    .font(.system(size: 13))
                Spacer()
                Text("时长 · 分钟")
                    .font(.system(size: 12))
                    .kerning(0.8)
                    .foregroundStyle(theme.inkFaint)
            }
            Text("设置")
                .font(.system(size: 15.5, weight: .semibold))
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.top, 36) // 头部左侧是「返回」，要让出交通灯一行
        .padding(.bottom, 14)
    }

    private var themeRow: some View {
        HStack {
            Text("主题")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.ink)
            Spacer()
            segmented
        }
        .padding(.vertical, 14)
    }

    /// 主题分段切换（自定义：胶囊底 + 浮起的选中块）
    private var segmented: some View {
        HStack(spacing: 2) {
            segmentButton("浅色", isActive: !engine.isDarkTheme) { engine.isDarkTheme = false }
            segmentButton("深色", isActive: engine.isDarkTheme) { engine.isDarkTheme = true }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 9).fill(theme.btn))
        .animation(.easeOut(duration: 0.2), value: engine.isDarkTheme)
    }

    private func segmentButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13.5, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? theme.ink : theme.inkSoft)
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).fill(isActive ? theme.surface : .clear))
        }
        .buttonStyle(.plain)
    }

    private func durationRow(_ name: String, dotColor: Color, value: Binding<Int>) -> some View {
        HStack(spacing: 9) {
            Circle().fill(dotColor).frame(width: 8, height: 8)
            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.ink)
            Spacer()

            HStack(spacing: 4) {
                Button { value.wrappedValue = max(1, value.wrappedValue - 1) } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(StepButtonStyle(theme: theme))

                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(value.wrappedValue)")
                        .font(.system(size: 23, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: Double(value.wrappedValue)))
                        .animation(.snappy(duration: 0.25), value: value.wrappedValue)
                    Text("分")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.inkFaint)
                        .padding(.leading, 2)
                }
                .frame(width: 52)

                Button { value.wrappedValue = min(60, value.wrappedValue + 1) } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(StepButtonStyle(theme: theme))
            }
        }
        .padding(.vertical, 16)
    }

    private var footer: some View {
        HStack {
            Text("每 4 个专注 → 1 次大休")
                .font(.system(size: 12))
                .kerning(0.3)
                .foregroundStyle(theme.inkFaint)
            Spacer()
            Button("恢复默认") { engine.restoreDefaults() }
                .buttonStyle(LinkButtonStyle(normal: theme.focusInk, hover: theme.focusInk))
                .font(.system(size: 12.5))
            Button("退出") { NSApp.terminate(nil) }
                .buttonStyle(LinkButtonStyle(normal: theme.inkFaint, hover: theme.ink))
                .font(.system(size: 12.5))
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 15)
    }
}
