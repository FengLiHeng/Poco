import SwiftUI

struct LinkButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let normal: Color
    let hover: Color
    @State private var hovered = false

    var body: some View {
        configuration.label
            .foregroundStyle(hovered ? hover : normal)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }
    }
}
