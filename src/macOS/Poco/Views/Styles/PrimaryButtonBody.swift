import SwiftUI

struct PrimaryButtonBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let configuration: ButtonStyle.Configuration
    let theme: PocoTheme
    let actionColor: Color
    @State private var hovered = false

    private var pressedScale: CGFloat {
        reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1)
    }

    var body: some View {
        configuration.label
            .font(.callout)
            .bold()
            .kerning(0.6)
            .foregroundStyle(theme.onAction)
            .frame(minWidth: 124)
            .frame(height: 52)
            .padding(.horizontal, 10)
            .background(Capsule().fill(actionColor))
            .opacity(configuration.isPressed ? 0.84 : (hovered ? 0.92 : 1))
            .scaleEffect(pressedScale)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }
    }
}
