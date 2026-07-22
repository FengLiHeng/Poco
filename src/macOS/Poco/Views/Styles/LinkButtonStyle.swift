import SwiftUI

/// 透明文字按钮（返回 / 恢复默认 / 退出）：无底色，悬停仅前景变化。
struct LinkButtonStyle: ButtonStyle {
    let normal: Color
    let hover: Color

    func makeBody(configuration: Configuration) -> some View {
        LinkButtonBody(configuration: configuration, normal: normal, hover: hover)
    }
}
