import SwiftUI

/// 主按钮（开始 / 暂停）：胶囊形、阶段语义操作色填充。
struct PrimaryButtonStyle: ButtonStyle {
    let theme: PocoTheme
    let actionColor: Color

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration, theme: theme, actionColor: actionColor)
    }
}
