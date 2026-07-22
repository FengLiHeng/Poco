import SwiftUI

struct StepButtonBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyle.Configuration
    let theme: PocoTheme
    @State private var hovered = false

    private var pressedScale: CGFloat {
        reduceMotion || !isEnabled ? 1 : (configuration.isPressed ? 0.92 : 1)
    }

    var body: some View {
        configuration.label
            .font(.body)
            .foregroundStyle(hovered && isEnabled ? theme.ink : theme.inkSoft)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(hovered && isEnabled ? theme.btnHover : theme.btn)
            )
            .opacity(isEnabled ? 1 : 0.38)
            .scaleEffect(pressedScale)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }
    }
}
