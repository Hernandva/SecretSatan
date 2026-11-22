import SwiftUI

/// Pill button with the design-system styles applied and an optional leading icon.
/// `.regular` is full width and 50 pt tall; `.compact` hugs its text and is 44 pt tall, e.g. "Editar" next to a field.
public struct DSButton: View, DSLocalizableText {
    public enum Style: Sendable {
        case primary
        case secondary
        case outline
        case destructive
    }

    /// Width and height of the button.
    public enum Size: Sendable {
        /// Full width, 50 pt tall: the main actions of a screen.
        case regular
        /// As wide as its text, 44 pt tall: inline actions next to a title or a field.
        case compact
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
    private let size: Size
    private let icon: Icon?
    private let action: @MainActor () -> Void

    public init(
        _ text: String = "",
        style: Style = .primary,
        size: Size = .regular,
        icon: Icon? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.text = text
        self.style = style
        self.size = size
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            DSButtonLabel(text: text, icon: icon, size: size)
        }
        .buttonStyle(DSButtonStyle(style: style))
    }
}

/// Content of every design-system button: optional icon and text on a full-width, 50 pt row,
/// or on a 44 pt row as wide as the text for `.compact`. Shared by `DSButton` and `DSLinkButton`.
struct DSButtonLabel: View {
    let text: String
    let icon: DSButton.Icon?
    var size: DSButton.Size = .regular

    var body: some View {
        HStack(spacing: DSSpacing.small) {
            iconView
            Text(text)
        }
        .font(DSFont.bodyStrong)
        .frame(maxWidth: size == .regular ? .infinity : nil, minHeight: minHeight)
        .padding(.horizontal, size == .regular ? DSSpacing.medium : DSSpacing.space5)
    }

    private var minHeight: CGFloat {
        size == .regular ? DSButton.height : DSSpacing.tapMin
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

/// Pill shape and colors of each `DSButton.Style`. Shared by `DSButton` and `DSLinkButton`.
struct DSButtonStyle: ButtonStyle {
    /// Opacity of a disabled button, so it reads as inactive.
    static let disabledOpacity: Double = 0.4

    let style: DSButton.Style
    @Environment(\.isEnabled) private var isEnabled

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
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : Self.disabledOpacity)
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
        DSButton("Edit", style: .secondary, size: .compact) {}
    }
    .padding()
}
