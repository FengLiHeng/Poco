import SwiftUI

/// 幽灵圆钮（重置 / 跳过）：44pt 圆形，悬停加深。
struct GhostButtonStyle: ButtonStyle {
    let theme: PocoTheme

    func makeBody(configuration: Configuration) -> some View {
        GhostButtonBody(configuration: configuration, theme: theme)
    }
}
