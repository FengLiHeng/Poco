import SwiftUI

/// 单个轮次标记：实心=完成、双环=当前、空心=未来，不只依赖颜色。
struct CycleDotView: View {
    let state: CycleDotState
    let accent: Color
    let hairline: Color

    var body: some View {
        ZStack {
            switch state {
            case .completed:
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
            case .current:
                Circle()
                    .stroke(accent.opacity(0.4), lineWidth: 2)
                    .frame(width: 16, height: 16)
                Circle()
                    .fill(accent)
                    .frame(width: 6, height: 6)
            case .upcoming:
                Circle()
                    .stroke(hairline, lineWidth: 1.5)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 16, height: 16)
        .animation(.easeOut(duration: 0.25), value: state)
        .accessibilityHidden(true)
    }
}
