// Poco 设计系统（移植自 Avalonia 版 App.axaml 的双主题色板 + Styles/Poco.axaml 规格）。
// 两条正交的轴：主题轴（浅/深，手动切换）选 token 集；阶段轴（专注暖橙/休息薄荷青）选语义色。
import SwiftUI

struct PocoTheme {
    let bg: Color          // 窗口底
    let surface: Color     // 浮起表面（分段选中块）
    let ink: Color         // 主文字
    let inkSoft: Color     // 次文字
    let inkFaint: Color    // 弱文字
    let hairline: Color    // 发丝线
    let btn: Color         // 按钮底
    let btnHover: Color    // 按钮悬停底
    let onAction: Color    // 操作色上的文字

    let focus: Color       // 专注主色
    let focusInk: Color    // 专注文字色
    let rest: Color        // 休息主色
    let restInk: Color     // 休息文字色
    let focusAction: Color // 专注操作色（比进度环更深，保证按钮文字对比度）
    let restAction: Color  // 休息操作色

    static let light = PocoTheme(
        bg: Color(hex: 0xF7F4EE), surface: Color(hex: 0xFCF9F5),
        ink: Color(hex: 0x39332E), inkSoft: Color(hex: 0x6D6661), inkFaint: Color(hex: 0x746E69),
        hairline: Color(hex: 0xE0DCD7), btn: Color(hex: 0xEAE7E1), btnHover: Color(hex: 0xE3DFD9),
        onAction: Color(hex: 0xFBFAF7),
        // 专注色：鲜亮暖橙（陶土色大面积铺开发闷，进度环需要更亮的主色）
        focus: Color(hex: 0xE8772E), focusInk: Color(hex: 0xA94B0D),
        rest: Color(hex: 0x4D9BA1), restInk: Color(hex: 0x2F767D),
        focusAction: Color(hex: 0xB94F0C), restAction: Color(hex: 0x347C82))

    static let dark = PocoTheme(
        bg: Color(hex: 0x201D19), surface: Color(hex: 0x282420),
        ink: Color(hex: 0xE4DFD8), inkSoft: Color(hex: 0xA39D97), inkFaint: Color(hex: 0x8B857F),
        hairline: Color(hex: 0x3D3834), btn: Color(hex: 0x37322D), btnHover: Color(hex: 0x423C37),
        onAction: Color(hex: 0x1A1612),
        focus: Color(hex: 0xF2954E), focusInk: Color(hex: 0xF6AC6E),
        rest: Color(hex: 0x6FBEC4), restInk: Color(hex: 0x8FD2D8),
        focusAction: Color(hex: 0xF2954E), restAction: Color(hex: 0x6FBEC4))

    /// 当前阶段的视觉语义色（进度环 / 圆点 / 结束态数字）
    func accent(isFocus: Bool) -> Color { isFocus ? focus : rest }
    /// 当前阶段的文字语义色（阶段标签 / 强调提示）
    func accentInk(isFocus: Bool) -> Color { isFocus ? focusInk : restInk }
    /// 当前阶段的操作色（主按钮）
    func action(isFocus: Bool) -> Color { isFocus ? focusAction : restAction }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}
