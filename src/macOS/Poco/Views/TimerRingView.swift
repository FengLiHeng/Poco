import SwiftUI

/// 进度环仪表：承载阶段、稳定的倒计时数字与状态提示。
struct TimerRingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var engine: PomodoroEngine
    @ScaledMetric(relativeTo: .largeTitle) private var scaledRingSize = PocoMetrics.ringSize
    @ScaledMetric(relativeTo: .largeTitle) private var scaledCountdownSize: CGFloat = 48
    @State private var centerScale: CGFloat = 1

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }
    private var accent: Color { theme.accent(isFocus: engine.isFocus) }
    private var accentInk: Color { theme.accentInk(isFocus: engine.isFocus) }
    private var ringSize: CGFloat { min(scaledRingSize, PocoMetrics.ringMaxSize) }

    private var countdownColor: Color {
        switch engine.state {
        case .paused: return theme.inkSoft
        case .finished: return accent
        default: return theme.ink
        }
    }

    private var progressAnimation: Animation {
        if reduceMotion { return .easeOut(duration: 0.12) }
        return engine.state == .running ? .linear(duration: 1) : .easeOut(duration: 0.22)
    }

    private var accessibilityTime: String {
        let time = "\(engine.minutesText) 分 \(engine.secondsText) 秒"
        guard let hint = engine.hintText else { return time }
        return "\(time)，\(hint)"
    }

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(theme.hairline)
                    .frame(width: 1.5, height: 4)
                    .offset(y: -(ringSize / 2 - PocoMetrics.ringWidth - 8))
                    .rotationEffect(.degrees(Double(index) * 30))
                    .accessibilityHidden(true)
            }

            Circle()
                .stroke(theme.btn, lineWidth: PocoMetrics.ringWidth)
                .frame(width: ringSize, height: ringSize)
                .accessibilityHidden(true)

            Circle()
                .trim(from: 0, to: engine.progress)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: PocoMetrics.ringWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(progressAnimation, value: engine.progress)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(engine.phaseCjk)
                    .font(.callout)
                    .bold()
                    .kerning(4)
                    .foregroundStyle(accentInk)

                Text("\(engine.minutesText):\(engine.secondsText)")
                    .font(.system(size: min(scaledCountdownSize, 66), weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(countdownColor)

                Text(engine.hintText ?? " ")
                    .font(.caption)
                    .foregroundStyle(engine.state == .finished ? accentInk : theme.inkSoft)
                    .opacity(engine.hintText == nil ? 0 : 1)
            }
            .scaleEffect(centerScale)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(engine.phaseCjk)计时")
            .accessibilityValue(accessibilityTime)
            .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(width: ringSize, height: ringSize)
        .background {
            RingGlowView(
                accent: accent,
                size: ringSize,
                isActive: engine.state == .running
            )
        }
        .onChange(of: engine.state, handleStateChange)
    }

    private func handleStateChange(_ oldState: TimerState, _ newState: TimerState) {
        guard newState == .finished, !reduceMotion else {
            centerScale = 1
            return
        }
        centerScale = 1
        withAnimation(.easeInOut(duration: 0.18).repeatCount(2, autoreverses: true)) {
            centerScale = 1.025
        }
    }
}
