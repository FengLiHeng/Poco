// 主窗口：倒计时 + 轮次圆点 + 控制区；设置打开时滑入设置面板。
// 视觉规格移植自设计稿（Styles/Poco.axaml）：自定义色板 + 阶段语义色 + 呼吸动画。
import SwiftUI

struct MainView: View {
    @EnvironmentObject var engine: PomodoroEngine

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }
    private var accent: Color { theme.accent(isFocus: engine.isFocus) }
    private var accentInk: Color { theme.accentInk(isFocus: engine.isFocus) }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            timerView
                .opacity(engine.isSettingsOpen ? 0 : 1)

            if engine.isSettingsOpen {
                SettingsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 324, height: 416)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: engine.isSettingsOpen)
        .animation(.easeInOut(duration: 0.45), value: engine.isFocus)
    }

    private var timerView: some View {
        VStack(spacing: 0) {
            // 顶栏：齿轮（与左上角交通灯同一行）
            HStack {
                Spacer()
                GearButton(theme: theme) { engine.isSettingsOpen = true }
            }
            .padding(.top, 10)
            .padding(.trailing, 14)

            Spacer()

            VStack(spacing: 18) {
                // 阶段标签
                Text(engine.phaseCjk)
                    .font(.system(size: 15, weight: .semibold))
                    .kerning(4)
                    .foregroundStyle(accentInk)

                // 倒计时（运行中缓慢呼吸；结束后较快脉动提示操作）
                Text("\(engine.minutesText):\(engine.secondsText)")
                    .font(.system(size: 84, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(countdownColor)
                    .breathing(active: engine.state == .running, period: 4.5, minOpacity: 0.62)
                    .breathing(active: engine.state == .finished, period: 1.15, minOpacity: 0.42)

                // 提示行（已暂停 / 已结束）
                Text(engine.hintText ?? " ")
                    .font(.system(size: 14))
                    .foregroundStyle(engine.state == .finished ? accentInk : theme.inkSoft)
                    .opacity(engine.hintText == nil ? 0 : 1)
                    .padding(.top, -8)

                // 轮次圆点
                HStack(spacing: 11) {
                    ForEach(0..<PomodoroEngine.focusPerCycle, id: \.self) { i in
                        dot(index: i)
                    }
                }

                // 控制区
                HStack(alignment: .top, spacing: 14) {
                    labeledControl("重置") {
                        Button { engine.reset() } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(GhostButtonStyle(theme: theme))
                    }

                    VStack(spacing: 7) {
                        Button { engine.primaryAction() } label: {
                            HStack(spacing: 9) {
                                Image(systemName: engine.state == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text(engine.primaryLabel)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(theme: theme, accent: accent))
                    }

                    labeledControl("跳过") {
                        Button { engine.skip() } label: {
                            Image(systemName: "forward.end")
                        }
                        .buttonStyle(GhostButtonStyle(theme: theme))
                    }
                }
                .padding(.top, 2)
            }

            Spacer()
            Spacer().frame(height: 26)
        }
    }

    private var countdownColor: Color {
        switch engine.state {
        case .paused: return theme.inkFaint
        case .finished: return accent
        default: return theme.ink
        }
    }

    private func dot(index: Int) -> some View {
        let on = index < engine.completedFocus || index == engine.currentDotIndex
        let current = index == engine.currentDotIndex
        return ZStack {
            // 当前轮光晕（运行中随呼吸起伏）
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 16, height: 16)
                .opacity(current ? 1 : 0)
                .breathing(active: current && engine.state == .running, period: 4.5, minOpacity: 0.3)
            Circle()
                .strokeBorder(on ? accent : theme.hairline, lineWidth: 1.5)
                .background(Circle().fill(on ? accent : .clear))
                .frame(width: 8, height: 8)
        }
        .frame(width: 16, height: 16)
        .animation(.easeOut(duration: 0.3), value: on)
        .animation(.easeOut(duration: 0.3), value: current)
    }

    private func labeledControl(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 7) {
            content()
            Text(title)
                .font(.system(size: 11.5))
                .kerning(0.5)
                .foregroundStyle(theme.inkFaint)
        }
        .padding(.top, 4) // 与 52pt 主按钮的视觉中线对齐
    }
}

/// 顶栏齿轮：悬停浮出按钮底色
private struct GearButton: View {
    let theme: PocoTheme
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(hovered ? theme.inkSoft : theme.inkFaint)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 7).fill(hovered ? theme.btn : .clear))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: hovered)
        .onHover { hovered = $0 }
        .help("设置")
    }
}

// ============================================================
// 呼吸动画：用 TimelineView 按余弦曲线起伏透明度（对应 Avalonia 版 SineEaseInOut 关键帧）
// ============================================================
private struct BreathingModifier: ViewModifier {
    let active: Bool
    let period: Double
    let minOpacity: Double

    func body(content: Content) -> some View {
        if active {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let wave = 0.5 + 0.5 * cos(2 * .pi * t / period) // 1 → min → 1
                content.opacity(minOpacity + (1 - minOpacity) * wave)
            }
        } else {
            content
        }
    }
}

extension View {
    func breathing(active: Bool, period: Double, minOpacity: Double) -> some View {
        modifier(BreathingModifier(active: active, period: period, minOpacity: minOpacity))
    }
}
