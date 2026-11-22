import SwiftUI

/// Full-width pill button with the design-system styles applied and an optional leading icon.
public struct DSButton: View, DSLocalizableText {
    public enum Style: Sendable {
        case primary
        case secondary
        case outline
        case destructive
    }

    /// Leading icon of the button: an SF Symbol or a single text glyph.
    public enum Icon: Sendable {
        case symbol(String)
        case glyph(String)
    }

    /// Height of every button, as set by the `radius-pill` token ("Botones (50px de alto)").
    static let height: CGFloat = 50

    public var text: String
    private let style: Style
    private let icon: Icon?
    private let action: @MainActor () -> Void

    public init(
        _ text: String = "",
        style: Style = .primary,
        icon: Icon? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.text = text
        self.style = style
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.small) {
                iconView
                Text(text)
            }
            .font(DSFont.bodyStrong)
            .frame(maxWidth: .infinity, minHeight: Self.height)
            .padding(.horizontal, DSSpacing.medium)
        }
        .buttonStyle(DSButtonStyle(style: style))
    }

    @ViewBuilder private var iconView: some View {
        switch icon {
        case .symbol(let name):
            Image(systemName: name)
                .accessibilityHidden(true)
        case .glyph(let glyph):
            Text(verbatim: glyph)
                .fontWeight(.bold)
                .accessibilityHidden(true)
        case nil:
            EmptyView()
        }
    }
}

private struct DSButtonStyle: ButtonStyle {
    let style: DSButton.Style

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.radiusPill, style: .continuous)
        configuration.label
            .foregroundStyle(foreground)
            .background(background, in: shape)
            .overlay {
                if style == .outline {
                    shape.strokeBorder(DSColor.accent, lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(shape)
    }

    private var foreground: Color {
        switch style {
        case .primary: DSColor.onAccent
        case .secondary, .outline: DSColor.accent
        case .destructive: DSColor.onDestructive
        }
    }

    private var background: Color {
        switch style {
        case .primary: DSColor.accent
        case .secondary: DSColor.fillSecondary
        case .outline: DSColor.background
        case .destructive: DSColor.destructive
        }
    }
}

#Preview {
    VStack {
        DSButton("Primary", icon: .symbol("apple.logo")) {}
        DSButton("Outline", style: .outline, icon: .glyph("G")) {}
        DSButton("Secondary", style: .secondary) {}
        DSButton("Delete", style: .destructive) {}
    }
    .padding()
}
