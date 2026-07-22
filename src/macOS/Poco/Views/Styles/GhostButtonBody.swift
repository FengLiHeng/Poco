import SwiftUI

struct GhostButtonBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let configuration: ButtonStyle.Configuration
    let theme: PocoTheme
    @State private var hovered = false

    private var pressedScale: CGFloat {
        reduceMotion ? 1 : (configuration.isPressed ? 0.94 : 1)
    }

    var body: some View {
        configuration.label
            .font(.body)
            .foregroundStyle(hovered ? theme.ink : theme.inkSoft)
            .frame(width: 44, height: 44)
            .background(Circle().fill(hovered ? theme.btnHover : theme.btn))
            .scaleEffect(pressedScale)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }
    }
}
