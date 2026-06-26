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
    let onAccent: Color    // 强调色上的文字

    let focus: Color       // 专注主色
    let focusInk: Color    // 专注文字色
    let rest: Color        // 休息主色
    let restInk: Color     // 休息文字色

    static let light = PocoTheme(
        bg: Color(hex: 0xF7F4EE), surface: Color(hex: 0xFCF9F5),
        ink: Color(hex: 0x39332E), inkSoft: Color(hex: 0x6D6661), inkFaint: Color(hex: 0x9D9792),
        hairline: Color(hex: 0xE0DCD7), btn: Color(hex: 0xEAE7E1), btnHover: Color(hex: 0xE3DFD9),
        onAccent: Color(hex: 0xFBFAF7),
        // 专注色：鲜亮暖橙（陶土色大面积铺开发闷，进度环需要更亮的主色）
        focus: Color(hex: 0xE8772E), focusInk: Color(hex: 0xC25A14),
        rest: Color(hex: 0x4D9BA1), restInk: Color(hex: 0x2F767D))

    static let dark = PocoTheme(
        bg: Color(hex: 0x201D19), surface: Color(hex: 0x282420),
        ink: Color(hex: 0xE4DFD8), inkSoft: Color(hex: 0xA39D97), inkFaint: Color(hex: 0x6D6862),
        hairline: Color(hex: 0x3D3834), btn: Color(hex: 0x37322D), btnHover: Color(hex: 0x423C37),
        onAccent: Color(hex: 0x1A1612),
        focus: Color(hex: 0xF2954E), focusInk: Color(hex: 0xF6AC6E),
        rest: Color(hex: 0x6FBEC4), restInk: Color(hex: 0x8FD2D8))

    /// 当前阶段的语义色（圆点 / 主按钮 / 结束态数字）
    func accent(isFocus: Bool) -> Color { isFocus ? focus : rest }
    /// 当前阶段的文字语义色（阶段标签 / 强调提示）
    func accentInk(isFocus: Bool) -> Color { isFocus ? focusInk : restInk }
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

// ============================================================
// 控件样式（对应 Styles/Poco.axaml 的 btn-ghost / btn-primary / step-btn 等）。
// 注意：悬停等瞬时状态放在 makeBody 返回的 View 里（@State 在 ButtonStyle
// 本体上的存储行为无文档保证）。
// ============================================================

/// 幽灵圆钮（重置 / 跳过）：44pt 圆形，悬停加深
struct GhostButtonStyle: ButtonStyle {
    let theme: PocoTheme

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, theme: theme)
    }

    private struct StyledBody: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        let configuration: Configuration
        let theme: PocoTheme
        @State private var hovered = false

        private var pressedScale: CGFloat {
            reduceMotion ? 1 : (configuration.isPressed ? 0.94 : 1)
        }

        var body: some View {
            configuration.label
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(hovered ? theme.ink : theme.inkSoft)
                .frame(width: 44, height: 44)
                .background(Circle().fill(hovered ? theme.btnHover : theme.btn))
                .scaleEffect(pressedScale)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .animation(.easeOut(duration: 0.15), value: hovered)
                .onHover { hovered = $0 }
        }
    }
}

/// 主按钮（开始 / 暂停）：胶囊形、阶段语义色填充
struct PrimaryButtonStyle: ButtonStyle {
    let theme: PocoTheme
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, theme: theme, accent: accent)
    }

    private struct StyledBody: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        let configuration: Configuration
        let theme: PocoTheme
        let accent: Color
        @State private var hovered = false

        private var pressedScale: CGFloat {
            reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1)
        }

        var body: some View {
            configuration.label
                .font(.system(size: 15, weight: .semibold))
                .kerning(0.9)
                .foregroundStyle(theme.onAccent)
                .frame(minWidth: 116)
                .frame(height: 52)
                .padding(.horizontal, 8)
                .background(Capsule().fill(accent))
                .opacity(configuration.isPressed ? 0.84 : (hovered ? 0.92 : 1))
                .scaleEffect(pressedScale)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .animation(.easeOut(duration: 0.15), value: hovered)
                .onHover { hovered = $0 }
        }
    }
}

/// 步进钮（− / +）：28pt 圆角 8
struct StepButtonStyle: ButtonStyle {
    let theme: PocoTheme

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, theme: theme)
    }

    private struct StyledBody: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        let configuration: Configuration
        let theme: PocoTheme
        @State private var hovered = false

        private var pressedScale: CGFloat {
            reduceMotion ? 1 : (configuration.isPressed ? 0.92 : 1)
        }

        var body: some View {
            configuration.label
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(hovered ? theme.ink : theme.inkSoft)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8).fill(hovered ? theme.btnHover : theme.btn))
                .scaleEffect(pressedScale)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .onHover { hovered = $0 }
        }
    }
}

/// 透明文字按钮（返回 / 恢复默认 / 退出）：无底色，悬停仅前景变化
struct LinkButtonStyle: ButtonStyle {
    let normal: Color
    let hover: Color

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, normal: normal, hover: hover)
    }

    private struct StyledBody: View {
        let configuration: Configuration
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
}
