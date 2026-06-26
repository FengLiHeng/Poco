// 设置面板（与主窗口同窗滑入）：主题分段控件 + 三个时长步进行 + 恢复默认/退出。
// 视觉规格移植自设计稿：发丝线分行、自定义分段控件与步进钮。
import SwiftUI

struct SettingsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    private enum SettingsType {
        static let title = Font.system(size: 15.5, weight: .medium)
        static let meta = Font.system(size: 11.5, weight: .regular)
        static let rowLabel = Font.system(size: 14.5, weight: .regular)
        static let segmentActive = Font.system(size: 13.5, weight: .medium)
        static let segmentInactive = Font.system(size: 13.5, weight: .regular)
        static let value = Font.system(size: 23, weight: .regular)
        static let unit = Font.system(size: 11.5, weight: .regular)
        static let link = Font.system(size: 12.5, weight: .regular)
    }

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
                    .font(SettingsType.link)
                Spacer()
                Text("时长 · 分钟")
                    .font(SettingsType.meta)
                    .kerning(0.5)
                    .foregroundStyle(theme.inkFaint)
            }
            Text("设置")
                .font(SettingsType.title)
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.top, 36) // 头部左侧是「返回」，要让出交通灯一行
        .padding(.bottom, 14)
    }

    private var themeRow: some View {
        HStack {
            Text("主题")
                .font(SettingsType.rowLabel)
                .foregroundStyle(theme.inkSoft)
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
                .font(isActive ? SettingsType.segmentActive : SettingsType.segmentInactive)
                .foregroundStyle(isActive ? theme.ink : theme.inkSoft)
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).fill(isActive ? theme.surface : .clear))
                .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isActive ? "已选择" : "未选择")
    }

    private func durationRow(_ name: String, dotColor: Color, value: Binding<Int>) -> some View {
        HStack(spacing: 9) {
            Circle().fill(dotColor).frame(width: 8, height: 8)
            Text(name)
                .font(SettingsType.rowLabel)
                .foregroundStyle(theme.inkSoft)
            Spacer()

            HStack(spacing: 4) {
                Button("减少\(name)", systemImage: "minus") {
                    value.wrappedValue = max(1, value.wrappedValue - 1)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(StepButtonStyle(theme: theme))

                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(value.wrappedValue)")
                        .font(SettingsType.value)
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .contentTransition(valueTransition(for: value.wrappedValue))
                        .animation(valueAnimation, value: value.wrappedValue)
                    Text("分")
                        .font(SettingsType.unit)
                        .foregroundStyle(theme.inkFaint)
                        .padding(.leading, 2)
                }
                .frame(width: 52)

                Button("增加\(name)", systemImage: "plus") {
                    value.wrappedValue = min(60, value.wrappedValue + 1)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(StepButtonStyle(theme: theme))
            }
        }
        .padding(.vertical, 16)
    }

    private func valueTransition(for value: Int) -> ContentTransition {
        reduceMotion ? .identity : .numericText(value: Double(value))
    }

    private var valueAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.01) : .snappy(duration: 0.25)
    }

    private var footer: some View {
        HStack {
            Text("每 4 个专注 → 1 次大休")
                .font(SettingsType.meta)
                .kerning(0.3)
                .foregroundStyle(theme.inkFaint)
            Spacer()
            Button("恢复默认") { engine.restoreDefaults() }
                .buttonStyle(LinkButtonStyle(normal: theme.focusInk, hover: theme.focusInk))
                .font(SettingsType.link)
            Button("退出") { NSApp.terminate(nil) }
                .buttonStyle(LinkButtonStyle(normal: theme.inkFaint, hover: theme.ink))
                .font(SettingsType.link)
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 15)
    }
}
