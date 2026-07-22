import SwiftUI

/// 顶栏设置按钮：保留轻量外观，同时扩大可点击范围。
struct GearButton: View {
    let theme: PocoTheme
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Label("设置", systemImage: "gearshape")
                .labelStyle(.iconOnly)
                .font(.callout)
                .foregroundStyle(hovered ? theme.inkSoft : theme.inkFaint)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hovered ? theme.btn : .clear)
                )
                // 命中形状必须位于 Button 的标签内部，确保整块背景都可点击。
                .contentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(",", modifiers: .command)
        .animation(.easeOut(duration: 0.15), value: hovered)
        .onHover { hovered = $0 }
        .help("设置（⌘,）")
    }
}
