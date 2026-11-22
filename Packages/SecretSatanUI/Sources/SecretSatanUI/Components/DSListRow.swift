import SwiftUI

/// Row with a title, an optional subtitle, an optional leading icon and an optional chevron.
/// `.localized(_:)` localises the title.
///
/// With `icon`, the row shows the SF Symbol on a rounded tile of the primary color and uses the larger
/// headline / subheadline type, as in the event list.
public struct DSListRow: View, DSLocalizableText {
    /// Side of the icon tile.
    static let iconSide: CGFloat = 40
    /// Point size of the symbol inside the icon tile.
    static let iconSymbolSize: CGFloat = 20
    /// Separator inset that lines up with the title of rows that have an icon. Pass it to `DSListGroup`.
    public static let iconSeparatorInset: CGFloat = DSSpacing.medium + iconSide + DSSpacing.space3

    public var text: String
    private let subtitle: String?
    private let icon: String?
    private let showsChevron: Bool

    public init(_ text: String = "", subtitle: String? = nil, icon: String? = nil, showsChevron: Bool = false) {
        self.text = text
        self.subtitle = subtitle
        self.icon = icon
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(spacing: icon == nil ? DSSpacing.small : DSSpacing.space3) {
            if let icon {
                iconTile(systemName: icon)
            }
            VStack(alignment: .leading, spacing: icon == nil ? DSSpacing.xSmall : 0) {
                Text(text)
                    .font(icon == nil ? DSFont.body : DSFont.headline)
                    .foregroundStyle(DSColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(icon == nil ? DSFont.footnote : DSTypeScale.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, DSSpacing.medium)
        .padding(.vertical, icon == nil ? 0 : DSSpacing.space3)
        .frame(minHeight: DSSpacing.tapMin)
        .background(DSColor.surface)
        .contentShape(Rectangle())
    }

    private func iconTile(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: Self.iconSymbolSize))
            .foregroundStyle(DSColor.onAccent)
            .frame(width: Self.iconSide, height: Self.iconSide)
            .background(
                DSColor.accent,
                in: RoundedRectangle(cornerRadius: DSRadius.radiusIcon, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 0) {
        DSListRow("Account", subtitle: "Signed in", showsChevron: true)
        DSListRow("Privacy", showsChevron: true)
        DSListRow("Family 2026", subtitle: "6 participants", icon: "gift", showsChevron: true)
    }
}
