// 主窗口：倒计时 + 轮次圆点 + 控制区；设置打开时整体切换为设置面板。
// 原生 macOS 风格：系统控件与系统字体，阶段语义色（专注橙/休息青）仅作点缀。
import SwiftUI

struct MainView: View {
    @EnvironmentObject var engine: PomodoroEngine

    var body: some View {
        Group {
            if engine.isSettingsOpen {
                SettingsView()
            } else {
                timerView
            }
        }
        .frame(width: 324, height: 416)
    }

    /// 阶段语义色：专注暖橙 / 休息薄荷青
    private var accent: Color { engine.isFocus ? .orange : .mint }

    private var timerView: some View {
        VStack(spacing: 0) {
            // 顶栏：齿轮
            HStack {
                Spacer()
                Button {
                    engine.isSettingsOpen = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("设置")
            }
            .padding(.top, 14)
            .padding(.trailing, 14)

            Spacer()

            VStack(spacing: 18) {
                // 阶段标签
                Text(engine.phaseCjk)
                    .font(.headline)
                    .foregroundStyle(accent)

                // 倒计时
                Text("\(engine.minutesText):\(engine.secondsText)")
                    .font(.system(size: 64, weight: .light).monospacedDigit())
                    .foregroundStyle(engine.state == .paused ? .secondary : .primary)

                // 提示行（已暂停 / 已结束）
                Text(engine.hintText ?? " ")
                    .font(.subheadline)
                    .foregroundStyle(engine.state == .finished ? AnyShapeStyle(accent) : AnyShapeStyle(.secondary))
                    .opacity(engine.hintText == nil ? 0 : 1)
                    .padding(.top, -8)

                // 轮次圆点
                HStack(spacing: 11) {
                    ForEach(0..<PomodoroEngine.focusPerCycle, id: \.self) { i in
                        dot(index: i)
                    }
                }

                // 控制区
                HStack(spacing: 14) {
                    controlButton("重置", systemImage: "arrow.counterclockwise") {
                        engine.reset()
                    }

                    Button {
                        engine.primaryAction()
                    } label: {
                        Label(engine.primaryLabel,
                              systemImage: engine.state == .running ? "pause.fill" : "play.fill")
                            .frame(minWidth: 84)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(accent)

                    controlButton("跳过", systemImage: "forward.end") {
                        engine.skip()
                    }
                }
                .padding(.top, 2)
            }

            Spacer()
            Spacer().frame(height: 14)
        }
    }

    private func dot(index: Int) -> some View {
        let on = index < engine.completedFocus || index == engine.currentDotIndex
        let current = index == engine.currentDotIndex
        return Circle()
            .fill(on ? accent : Color.secondary.opacity(0.25))
            .frame(width: 9, height: 9)
            .overlay {
                if current {
                    Circle().stroke(accent.opacity(0.35), lineWidth: 3).frame(width: 15, height: 15)
                }
            }
            .frame(width: 16, height: 16)
    }

    private func controlButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 7) {
            Button(action: action) {
                Image(systemName: systemImage)
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        // 与主按钮的视觉中线对齐：标签是附加说明，不参与按钮行高度
        .padding(.bottom, -22)
    }
}
