import SwiftUI

/// 自定义主题分段中的一个选项。
struct ThemeSegmentButton: View {
    @EnvironmentObject private var engine: PomodoroEngine
    let title: String
    let isActive: Bool
    let action: () -> Void

    private var theme: PocoTheme { engine.isDarkTheme ? .dark : .light }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .bold(isActive)
                .foregroundStyle(isActive ? theme.ink : theme.inkSoft)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isActive ? theme.surface : .clear)
                )
                .contentShape(.rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isActive ? "已选择" : "未选择")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
