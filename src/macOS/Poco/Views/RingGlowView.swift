import SwiftUI

/// 进度环唯一的环境动效；低频刷新，避免持续按屏幕帧率重算整个计时界面。
struct RingGlowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let accent: Color
    let size: CGFloat
    let isActive: Bool

    var body: some View {
        if isActive, !reduceMotion {
            TimelineView(.periodic(from: .now, by: 0.75)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let wave = 0.5 + 0.5 * cos(2 * .pi * time / 4.5)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.08), accent.opacity(0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size * 1.3, height: size * 1.3)
                    .opacity(0.85 + wave * 0.15)
                    .scaleEffect(0.985 + wave * 0.015)
                    .animation(.easeInOut(duration: 0.75), value: wave)
            }
        } else {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.08), accent.opacity(0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.62
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
        }
    }
}
