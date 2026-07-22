import SwiftUI

/// 时长步进钮：32pt 圆角按钮，边界禁用时明确变淡。
struct StepButtonStyle: ButtonStyle {
    let theme: PocoTheme

    func makeBody(configuration: Configuration) -> some View {
        StepButtonBody(configuration: configuration, theme: theme)
    }
}
