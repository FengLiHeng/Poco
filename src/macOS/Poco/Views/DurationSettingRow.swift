import SwiftUI

/// 单个时长设置行；边界按钮会禁用，并用数字滚动过渡反馈修改。
struct DurationSettingRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var engine: PomodoroEngine
    let name: String
    let dotColor: Color
    @Binding var value: Int

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    private var valueTransition: ContentTransition {
        reduceMotion ? .identity : .numericText(value: Double(value))
    }

    private var valueAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.01) : .snappy(duration: 0.25)
    }

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            Text(name)
                .font(.body)
                .foregroundStyle(theme.inkSoft)
            Spacer()

            HStack(spacing: 5) {
                Button("减少\(name)", systemImage: "minus", action: decrement)
                    .labelStyle(.iconOnly)
                    .buttonStyle(StepButtonStyle(theme: theme))
                    .disabled(value <= 1)

                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text(value, format: .number)
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .contentTransition(valueTransition)
                        .animation(valueAnimation, value: value)
                    Text("分")
                        .font(.caption)
                        .foregroundStyle(theme.inkSoft)
                        .padding(.leading, 2)
                }
                .frame(minWidth: 54)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(value) 分钟")

                Button("增加\(name)", systemImage: "plus", action: increment)
                    .labelStyle(.iconOnly)
                    .buttonStyle(StepButtonStyle(theme: theme))
                    .disabled(value >= 60)
            }
        }
        .padding(.vertical, 15)
    }

    private func decrement() {
        value = max(1, value - 1)
    }

    private func increment() {
        value = min(60, value + 1)
    }
}
